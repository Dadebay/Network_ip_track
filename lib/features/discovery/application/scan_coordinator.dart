import 'dart:async';

import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/cidr.dart';
import '../../../core/utils/ipv4_address.dart';
import '../../classification/application/device_classifier.dart';
import '../../classification/domain/repositories/oui_lookup.dart';
import '../../devices/domain/repositories/device_repository.dart';
import '../domain/entities/discovered_device.dart';
import '../domain/entities/scan_checkpoint.dart';
import '../domain/entities/scan_plan.dart';
import '../domain/entities/scan_progress.dart';
import '../domain/entities/scan_session_record.dart';
import '../domain/entities/scan_session_status.dart';
import '../domain/entities/scan_stage.dart';
import '../domain/repositories/scan_session_repository.dart';
import 'scan_control.dart';
import 'scan_engine.dart';

/// Which network a scan belongs to: the `networks` row plus the interface
/// and subnet that define it.
class ScanNetworkIdentity {
  const ScanNetworkIdentity({
    required this.networkId,
    required this.interfaceName,
    required this.cidr,
  });

  final int networkId;
  final String interfaceName;
  final Cidr cidr;

  @override
  bool operator ==(Object other) =>
      other is ScanNetworkIdentity &&
      other.networkId == networkId &&
      other.interfaceName == interfaceName &&
      other.cidr == cidr;

  @override
  int get hashCode => Object.hash(networkId, interfaceName, cidr);

  @override
  String toString() => '$interfaceName $cidr (network $networkId)';
}

/// Re-detects the currently active network while a scan runs. Returns null
/// when no active network (or no stored network row for it) is found.
typedef ScanNetworkProbe = Future<ScanNetworkIdentity?> Function();

/// Where this Mac sits on the network being scanned.
class ScanNetworkContext {
  const ScanNetworkContext({
    required this.networkId,
    required this.interfaceName,
    required this.interfaceCidr,
    required this.localAddress,
    required this.localSegments,
    this.gatewayAddress,
  });

  final int networkId;
  final String interfaceName;
  final Cidr interfaceCidr;
  final Ipv4Address localAddress;
  final Ipv4Address? gatewayAddress;
  final List<Cidr> localSegments;

  ScanNetworkIdentity get identity => ScanNetworkIdentity(
    networkId: networkId,
    interfaceName: interfaceName,
    cidr: interfaceCidr,
  );
}

/// A running scan: its session, live progress, and the stop handle.
class ScanRun {
  const ScanRun({
    required this.sessionId,
    required this.progress,
    required this.control,
  });

  final int sessionId;

  /// Ends after the final snapshot (status completed/paused/cancelled/
  /// failed) has been persisted.
  final Stream<ScanProgress> progress;
  final ScanControl control;
}

/// Wires [ScanEngine] to persistence: creates/resumes the `scan_sessions`
/// row, checkpoints the queue at chunk boundaries, upserts (and dedups)
/// every found host as it streams in, and ages devices a completed scan did
/// not see.
class ScanCoordinator {
  ScanCoordinator({
    required ScanEngine engine,
    required ScanSessionRepository sessions,
    required DeviceRepository devices,
    ScanNetworkProbe? networkProbe,
    Future<OuiLookup> Function()? ouiLoader,
    DeviceClassifier classifier = const DeviceClassifier(),
    this.networkCheckInterval = const Duration(seconds: 15),
    DateTime Function()? clock,
  }) : _engine = engine,
       _ouiLoader = ouiLoader,
       _classifier = classifier,
       _sessions = sessions,
       _devices = devices,
       _networkProbe = networkProbe,
       _clock = clock ?? DateTime.now;

  final ScanEngine _engine;
  final ScanSessionRepository _sessions;
  final DeviceRepository _devices;
  final ScanNetworkProbe? _networkProbe;
  final Future<OuiLookup> Function()? _ouiLoader;
  final DeviceClassifier _classifier;
  final DateTime Function() _clock;

  /// How often (by the injected clock, checked as progress arrives) the
  /// active network is re-detected during a scan.
  final Duration networkCheckInterval;

  static const _logger = AppLogger('ScanCoordinator');

  Future<ScanRun> start({
    required ScanPlan plan,
    required ScanNetworkContext network,
  }) async {
    final checkpoint = ScanCheckpoint.fromPlan(plan);
    final startedAt = _clock();
    final sessionId = await _sessions.createSession(
      networkId: network.networkId,
      targetCidrs: [for (final chunk in plan.chunks) chunk.cidr],
      checkpoint: checkpoint,
      startedAt: startedAt,
    );
    return _run(
      sessionId: sessionId,
      sessionStartedAt: startedAt,
      checkpoint: checkpoint,
      devicesFoundBefore: 0,
      network: network,
    );
  }

  Future<ScanRun> resume({
    required ScanSessionRecord session,
    required ScanNetworkContext network,
  }) async {
    final checkpoint = session.checkpoint;
    if (checkpoint == null || !session.isResumable) {
      throw InvalidScanScopeFailure(
        userMessage:
            'Bu tarama devam ettirilemiyor. Yeni bir tarama başlatabilirsiniz.',
        technicalDetail: 'session ${session.id} status ${session.status}',
      );
    }
    if (session.networkId != network.networkId) {
      throw ScanNetworkChangedFailure(
        technicalDetail:
            'session network ${session.networkId}, active ${network.networkId}',
      );
    }
    await _sessions.markStatus(
      sessionId: session.id,
      status: ScanSessionStatus.running,
    );
    return _run(
      sessionId: session.id,
      sessionStartedAt: session.startedAt,
      checkpoint: checkpoint,
      devicesFoundBefore: session.devicesFound,
      network: network,
    );
  }

  Future<ScanRun> _run({
    required int sessionId,
    required DateTime sessionStartedAt,
    required ScanCheckpoint checkpoint,
    required int devicesFoundBefore,
    required ScanNetworkContext network,
  }) async {
    final knownHosts = {
      for (final device in await _devices.getDevicesForNetwork(
        network.networkId,
      ))
        device.currentIp,
    };
    final oui = await _ouiLoader?.call() ?? const _NoOui();
    final control = ScanControl();
    final output = StreamController<ScanProgress>();

    var progress = ScanProgress(
      sessionId: sessionId,
      status: ScanSessionStatus.running,
      stage: ScanStage.gatheringCandidates,
      chunks: checkpoint.chunks,
      runStartedAt: _clock(),
      now: _clock(),
      hostsScannedAtRunStart: checkpoint.chunks.fold(
        0,
        (sum, chunk) => sum + chunk.hostsScanned,
      ),
      devicesFoundTotal: devicesFoundBefore,
    );

    // Writes are chained so upserts and checkpoints land in event order
    // and the final status is written only after every found host.
    var writes = Future<void>.value();
    void enqueue(Future<void> Function() write) {
      writes = writes.then((_) => write()).catchError((
        Object error,
        StackTrace stackTrace,
      ) {
        final failure = DatabaseFailure(
          technicalDetail: error.toString(),
          cause: error,
          stackTrace: stackTrace,
        );
        _logger.failure(failure);
        control.cancel();
        progress = progress.copyWith(failure: failure);
      });
    }

    void publish(ScanProgress next) {
      progress = next;
      if (!output.isClosed) output.add(next);
    }

    // Network-change guard: if the active interface, its CIDR or network
    // row changes mid-scan, pause rather than keep probing the old scope
    // from the new network. The session stays resumable on the original
    // network (resume refuses any other).
    AppFailure? networkChanged;
    var lastNetworkCheck = _clock();
    var networkCheckInFlight = false;
    Future<void> checkNetwork() async {
      final probe = _networkProbe;
      if (probe == null || networkCheckInFlight || networkChanged != null) {
        return;
      }
      final now = _clock();
      if (now.difference(lastNetworkCheck) < networkCheckInterval) return;
      lastNetworkCheck = now;
      networkCheckInFlight = true;
      try {
        ScanNetworkIdentity? current;
        Object? error;
        try {
          current = await probe();
        } catch (e) {
          error = e;
        }
        if (current != network.identity && networkChanged == null) {
          networkChanged = ScanNetworkChangedFailure(
            technicalDetail:
                'Tarama ağı: ${network.identity}; şu anki: '
                '${current ?? 'algılanamadı${error == null ? '' : ' ($error)'}'}',
          );
          _logger.failure(networkChanged!);
          control.pause();
          publish(progress.copyWith(failure: networkChanged, now: _clock()));
        }
      } finally {
        networkCheckInFlight = false;
      }
    }

    final events = _engine.run(
      from: checkpoint,
      control: control,
      context: ScanEngineContext(
        localSegments: network.localSegments,
        knownHosts: knownHosts,
      ),
    );

    late final StreamSubscription<ScanEvent> subscription;
    subscription = events.listen(
      (event) {
        switch (event) {
          case ScanProgressEvent(
            :final checkpoint,
            :final stage,
            :final persist,
          ):
            publish(
              progress.copyWith(
                chunks: checkpoint.chunks,
                stage: stage,
                now: _clock(),
              ),
            );
            unawaited(checkNetwork());
            if (persist) {
              final snapshot = progress;
              enqueue(
                () => _sessions.updateProgress(
                  sessionId: sessionId,
                  hostsScanned: snapshot.hostsScannedTotal,
                  devicesFound: snapshot.devicesFoundTotal,
                  checkpoint: checkpoint,
                ),
              );
            }
          case ScanHostFoundEvent(:final device):
            publish(
              progress.copyWith(
                devicesFoundTotal: progress.devicesFoundTotal + 1,
                now: _clock(),
              ),
            );
            enqueue(() => _persistDevice(device, network, oui));
          case ScanFinishedEvent(
            :final status,
            :final checkpoint,
            :final failure,
          ):
            enqueue(() async {
              // A network change pauses (resumable); any other failure
              // fails the session.
              final hardFailure =
                  failure ??
                  (identical(progress.failure, networkChanged)
                      ? null
                      : progress.failure);
              final finalFailure = hardFailure ?? networkChanged;
              final finalStatus = hardFailure != null
                  ? ScanSessionStatus.failed
                  : networkChanged != null
                  ? ScanSessionStatus.paused
                  : status;
              final done = progress.copyWith(
                status: finalStatus,
                stage: ScanStage.finished,
                chunks: checkpoint.chunks,
                now: _clock(),
                failure: finalFailure,
              );
              await _sessions.updateProgress(
                sessionId: sessionId,
                hostsScanned: done.hostsScannedTotal,
                devicesFound: done.devicesFoundTotal,
                checkpoint: checkpoint,
              );
              await _sessions.markStatus(
                sessionId: sessionId,
                status: finalStatus,
                errorMessage: finalFailure?.userMessage,
              );
              if (finalStatus == ScanSessionStatus.completed) {
                await _devices.markUnseenDevices(
                  networkId: network.networkId,
                  scannedCidrs: [
                    for (final chunk in checkpoint.chunks) chunk.cidr,
                  ],
                  seenSince: sessionStartedAt,
                );
              }
              publish(done);
            });
        }
      },
      onDone: () async {
        await writes;
        await subscription.cancel();
        await output.close();
      },
    );

    return ScanRun(
      sessionId: sessionId,
      progress: output.stream,
      control: control,
    );
  }

  Future<void> _persistDevice(
    DiscoveredDevice device,
    ScanNetworkContext network,
    OuiLookup oui,
  ) async {
    final isGateway = device.ipAddress == network.gatewayAddress;
    final isLocal = device.ipAddress == network.localAddress;
    final mac = device.macAddress;
    final vendor = mac == null ? null : oui.vendorFor(mac);

    await _devices.upsertDiscoveredDevice(
      networkId: network.networkId,
      discovered: device,
      vendor: vendor,
      classification: _classifier.classify(
        device: device,
        vendor: vendor,
        isGateway: isGateway,
        isLocalDevice: isLocal,
      ),
      isGateway: isGateway,
      isLocalDevice: isLocal,
    );
  }
}

class _NoOui implements OuiLookup {
  const _NoOui();

  @override
  bool get isAvailable => false;

  @override
  String? vendorFor(String normalizedMac) => null;
}
