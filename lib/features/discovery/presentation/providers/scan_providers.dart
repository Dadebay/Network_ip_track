import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/cidr.dart';
import '../../../classification/domain/repositories/oui_lookup.dart';
import '../../../classification/infrastructure/ieee_oui_database.dart';
import '../../../devices/presentation/providers/device_providers.dart';
import '../../../network_scope/domain/entities/subnet_reachability.dart';
import '../../../network_scope/presentation/providers/network_scope_providers.dart';
import '../../application/build_scan_plan_use_case.dart';
import '../../application/scan_control.dart';
import '../../application/scan_coordinator.dart';
import '../../application/scan_engine.dart';
import '../../domain/entities/scan_plan.dart';
import '../../domain/entities/scan_progress.dart';
import '../../domain/entities/scan_session_record.dart';
import '../../domain/entities/scan_session_status.dart';
import '../../domain/entities/scan_settings.dart';
import '../../domain/repositories/arp_table_provider.dart';
import '../../domain/repositories/http_banner_provider.dart';
import '../../domain/repositories/upnp_description_provider.dart';
import '../../domain/repositories/mdns_name_provider.dart';
import '../../domain/repositories/ws_discovery_provider.dart';
import '../../domain/repositories/mdns_provider.dart';
import '../../domain/repositories/netbios_provider.dart';
import '../../domain/repositories/network_diagnostics.dart';
import '../../domain/repositories/ping_provider.dart';
import '../../domain/repositories/port_probe_provider.dart';
import '../../domain/repositories/reverse_dns_provider.dart';
import '../../domain/repositories/scan_session_repository.dart';
import '../../domain/repositories/scan_settings_repository.dart';
import '../../domain/repositories/ssdp_provider.dart';
import '../../infrastructure/drift_scan_session_repository.dart';
import '../../infrastructure/macos/macos_arp_table_provider.dart';
import '../../infrastructure/http/io_http_banner_provider.dart';
import '../../infrastructure/http/io_upnp_description_provider.dart';
import '../../infrastructure/mdns/udp_mdns_name_provider.dart';
import '../../infrastructure/wsd/udp_ws_discovery_provider.dart';
import '../../infrastructure/macos/macos_mdns_provider.dart';
import '../../infrastructure/macos/macos_network_diagnostics.dart';
import '../../infrastructure/macos/native_icmp_ping_provider.dart';
import '../../infrastructure/macos/macos_reverse_dns_provider.dart';
import '../../infrastructure/macos/socket_port_probe_provider.dart';
import '../../infrastructure/macos/udp_ssdp_provider.dart';
import '../../infrastructure/netbios/udp_netbios_provider.dart';
import '../../infrastructure/settings/file_scan_settings_repository.dart';

// Platform adapters — overridden with fakes in tests so no test ever probes
// the real network.
final arpTableAdapterProvider = Provider<ArpTableProvider>(
  (ref) => const MacosArpTableProvider(),
);
final pingAdapterProvider = Provider<PingProvider>(
  (ref) => const NativeIcmpPingProvider(),
);
final reverseDnsAdapterProvider = Provider<ReverseDnsProvider>(
  (ref) => const MacosReverseDnsProvider(),
);
final mdnsAdapterProvider = Provider<MdnsProvider>(
  (ref) => MacosMdnsProvider(),
);
final ssdpAdapterProvider = Provider<SsdpProvider>(
  (ref) => const UdpSsdpProvider(),
);
final portProbeAdapterProvider = Provider<PortProbeProvider>(
  (ref) => const SocketPortProbeProvider(),
);
final networkDiagnosticsProvider = Provider<NetworkDiagnostics>(
  (ref) => MacosNetworkDiagnostics(ping: ref.watch(pingAdapterProvider)),
);
final httpBannerAdapterProvider = Provider<HttpBannerProvider>(
  (ref) => const IoHttpBannerProvider(),
);
final upnpDescriptionAdapterProvider = Provider<UpnpDescriptionProvider>(
  (ref) => const IoUpnpDescriptionProvider(),
);
final mdnsNameAdapterProvider = Provider<MdnsNameProvider>(
  (ref) => UdpMdnsNameProvider(),
);
final wsDiscoveryAdapterProvider = Provider<WsDiscoveryProvider>(
  (ref) => UdpWsDiscoveryProvider(),
);
final netbiosAdapterProvider = Provider<NetbiosProvider>(
  (ref) => UdpNetbiosProvider(),
);

/// IEEE OUI registry, loaded once per app run.
final ouiLookupProvider = FutureProvider<OuiLookup>(
  (ref) => IeeeOuiDatabase.load(rootBundle),
);

final scanSessionRepositoryProvider = Provider<ScanSessionRepository>((ref) {
  return DriftScanSessionRepository(ref.watch(appDatabaseProvider));
});

final scanCoordinatorProvider = Provider<ScanCoordinator>((ref) {
  return ScanCoordinator(
    engine: ScanEngine(
      arpTable: ref.watch(arpTableAdapterProvider),
      ping: ref.watch(pingAdapterProvider),
      reverseDns: ref.watch(reverseDnsAdapterProvider),
      mdns: ref.watch(mdnsAdapterProvider),
      ssdp: ref.watch(ssdpAdapterProvider),
      portProbe: ref.watch(portProbeAdapterProvider),
      netbios: ref.watch(netbiosAdapterProvider),
      httpBanner: ref.watch(httpBannerAdapterProvider),
      upnpDescription: ref.watch(upnpDescriptionAdapterProvider),
      mdnsName: ref.watch(mdnsNameAdapterProvider),
      wsDiscovery: ref.watch(wsDiscoveryAdapterProvider),
    ),
    sessions: ref.watch(scanSessionRepositoryProvider),
    devices: ref.watch(deviceRepositoryProvider),
    ouiLoader: () => ref.read(ouiLookupProvider.future),
    networkProbe: () async {
      final current = await ref.read(currentNetworkLookupProvider)();
      if (current == null) return null;
      return ScanNetworkIdentity(
        networkId: current.networkId,
        interfaceName: current.interfaceName,
        cidr: current.cidr,
      );
    },
  );
});

final buildScanPlanUseCaseProvider = Provider<BuildScanPlanUseCase>(
  (ref) => const BuildScanPlanUseCase(),
);

final scanSettingsRepositoryProvider = Provider<ScanSettingsRepository>(
  (ref) => FileScanSettingsRepository(),
);

/// Scan settings for new scans (resumed scans keep the settings they were
/// started with, from their checkpoint). Starts from the defaults and
/// switches to the stored settings once they load; every change is saved.
class ScanSettingsController extends Notifier<ScanSettings> {
  static const _logger = AppLogger('scan.settings');
  var _changedBeforeLoad = false;

  @override
  ScanSettings build() {
    _changedBeforeLoad = false;
    ref
        .watch(scanSettingsRepositoryProvider)
        .load()
        .then(
          (stored) {
            if (ref.mounted && !_changedBeforeLoad) state = stored;
          },
          onError: (Object error) {
            _logger.warning('Tarama ayarları yüklenemedi: $error');
          },
        );
    return const ScanSettings();
  }

  /// Updates immediately; the save is queued behind earlier ones by the
  /// repository, so rapid changes are written in order and the newest wins.
  void set(ScanSettings settings) {
    _changedBeforeLoad = true;
    state = settings.sanitized();
    ref
        .read(scanSettingsRepositoryProvider)
        .save(state)
        .catchError(
          (Object error) =>
              _logger.warning('Tarama ayarları kaydedilemedi: $error'),
        );
  }
}

final scanSettingsProvider =
    NotifierProvider<ScanSettingsController, ScanSettings>(
      ScanSettingsController.new,
    );

/// Runs once per app launch, before anything reads sessions: a session
/// still marked `running` was cut off by the app quitting.
final interruptedSessionsCleanupProvider = FutureProvider<void>((ref) {
  return ref
      .watch(scanSessionRepositoryProvider)
      .markInterruptedSessionsPaused();
});

final resumableSessionProvider = FutureProvider.autoDispose<ScanSessionRecord?>(
  (ref) async {
    await ref.watch(interruptedSessionsCleanupProvider.future);
    // Re-evaluate whenever a scan changes status.
    ref.watch(scanControllerProvider.select((state) => state.progress?.status));
    return ref.watch(scanSessionRepositoryProvider).findResumableSession();
  },
);

final recentSessionsProvider =
    StreamProvider.autoDispose<List<ScanSessionRecord>>((ref) async* {
      await ref.watch(interruptedSessionsCleanupProvider.future);
      yield* ref.watch(scanSessionRepositoryProvider).watchRecentSessions();
    });

class ScanState {
  const ScanState({this.progress, this.failure, this.isStarting = false});

  /// Latest progress of the current (or last) run in this app session.
  final ScanProgress? progress;

  /// A failure starting/resuming a scan (a failure *during* a scan is on
  /// [ScanProgress.failure]).
  final AppFailure? failure;
  final bool isStarting;

  bool get isRunning => isStarting || (progress?.isActive ?? false);
}

/// Owns the one scan that may run at a time. Lives for the whole app
/// session so a scan keeps running while the user browses other screens;
/// on disposal (app closing) the scan is paused, which checkpoints it for
/// resuming next launch.
class ScanController extends Notifier<ScanState> {
  ScanControl? _control;
  StreamSubscription<ScanProgress>? _subscription;

  @override
  ScanState build() {
    ref.onDispose(() {
      _control?.pause();
      _subscription?.cancel();
    });
    return const ScanState();
  }

  /// [confirmed] must be true for a plan that
  /// [ScanPlan.requiresConfirmation] — the UI's confirmation dialog is not
  /// the only line of defense against an unintended /12 sweep.
  Future<void> start(
    ScanPlan plan,
    ActiveNetwork network, {
    bool confirmed = false,
  }) {
    if (plan.requiresConfirmation && !confirmed) {
      state = ScanState(
        failure: InvalidScanScopeFailure(
          userMessage:
              'Bu tarama ${plan.totalCandidateHosts} adres içeriyor ve açık '
              'onay gerektiriyor. Taramayı onay penceresinden başlatın.',
        ),
      );
      return Future.value();
    }
    return _launch(
      network,
      (coordinator, context) => coordinator.start(plan: plan, network: context),
    );
  }

  Future<void> resume(ScanSessionRecord session, ActiveNetwork network) {
    return _launch(
      network,
      (coordinator, context) =>
          coordinator.resume(session: session, network: context),
    );
  }

  void pause() => _control?.pause();

  void cancel() => _control?.cancel();

  /// Gives up on a paused session without running it again.
  Future<void> discard(ScanSessionRecord session) async {
    await ref
        .read(scanSessionRepositoryProvider)
        .markStatus(sessionId: session.id, status: ScanSessionStatus.cancelled);
    final progress = state.progress;
    if (progress != null && progress.sessionId == session.id) {
      state = ScanState(
        progress: progress.copyWith(status: ScanSessionStatus.cancelled),
      );
    }
    ref.invalidate(resumableSessionProvider);
  }

  Future<void> _launch(
    ActiveNetwork network,
    Future<ScanRun> Function(ScanCoordinator, ScanNetworkContext) begin,
  ) async {
    if (state.isRunning) return;
    state = const ScanState(isStarting: true);
    try {
      final context = _contextFor(network);
      await ref.read(interruptedSessionsCleanupProvider.future);
      final run = await begin(ref.read(scanCoordinatorProvider), context);
      if (!ref.mounted) {
        run.control.pause();
        return;
      }
      _control = run.control;
      await _subscription?.cancel();
      _subscription = run.progress.listen((progress) {
        if (progress.failure is ScanNetworkChangedFailure &&
            state.progress?.failure is! ScanNetworkChangedFailure) {
          // Re-detect so the screens show the network the Mac is on now.
          ref.invalidate(networkScopeProvider);
        }
        state = ScanState(progress: progress);
      });
    } catch (error, stackTrace) {
      if (ref.mounted) {
        state = ScanState(failure: asAppFailure(error, stackTrace));
      }
    }
  }

  ScanNetworkContext _contextFor(ActiveNetwork network) {
    final activeInterface = network.snapshot.activeInterface;
    final networkId = network.networkId;
    if (activeInterface == null || networkId == null) {
      throw InvalidScanScopeFailure(
        userMessage:
            'Taranacak aktif bir ağ yok. Wi-Fi veya Ethernet bağlantınızı kontrol edin.',
      );
    }
    return ScanNetworkContext(
      networkId: networkId,
      interfaceName: activeInterface.name,
      interfaceCidr: activeInterface.cidr,
      localAddress: activeInterface.address,
      gatewayAddress: activeInterface.gatewayAddress,
      localSegments: <Cidr>{
        activeInterface.cidr,
        for (final subnet in network.snapshot.accessibleSubnets)
          if (subnet.reachability == SubnetReachability.directlyConnected)
            subnet.cidr,
      }.toList(),
    );
  }
}

final scanControllerProvider = NotifierProvider<ScanController, ScanState>(
  ScanController.new,
);
