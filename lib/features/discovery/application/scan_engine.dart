import 'dart:async';

import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/utils/cidr.dart';
import '../../../core/utils/ipv4_address.dart';
import '../domain/entities/arp_entry.dart';
import '../domain/entities/discovered_device.dart';
import '../domain/entities/discovery_method.dart';
import '../domain/entities/mdns_service_record.dart';
import '../domain/entities/scan_checkpoint.dart';
import '../domain/entities/scan_chunk.dart';
import '../domain/entities/scan_chunk_status.dart';
import '../domain/entities/scan_session_status.dart';
import '../domain/entities/scan_settings.dart';
import '../domain/entities/scan_stage.dart';
import '../domain/repositories/arp_table_provider.dart';
import '../domain/repositories/http_banner_provider.dart';
import '../domain/repositories/mdns_provider.dart';
import '../domain/repositories/netbios_provider.dart';
import '../domain/repositories/ping_provider.dart';
import '../domain/repositories/port_probe_provider.dart';
import '../domain/repositories/reverse_dns_provider.dart';
import '../domain/repositories/ssdp_provider.dart';
import 'scan_control.dart';

/// Something the engine reports while running.
sealed class ScanEvent {
  const ScanEvent();
}

/// Queue state changed. [persist] marks the points worth writing to SQLite
/// (chunk boundaries, end of the candidate pass); the others are throttled
/// UI refreshes.
class ScanProgressEvent extends ScanEvent {
  const ScanProgressEvent({
    required this.checkpoint,
    required this.stage,
    this.persist = false,
  });
  final ScanCheckpoint checkpoint;
  final ScanStage stage;
  final bool persist;
}

/// A live host, streamed as soon as its probe finishes.
class ScanHostFoundEvent extends ScanEvent {
  const ScanHostFoundEvent(this.device);
  final DiscoveredDevice device;
}

/// Always the last event.
class ScanFinishedEvent extends ScanEvent {
  const ScanFinishedEvent({
    required this.status,
    required this.checkpoint,
    this.failure,
  });
  final ScanSessionStatus status;
  final ScanCheckpoint checkpoint;
  final AppFailure? failure;
}

/// Per-scan facts about where this Mac sits on the network.
class ScanEngineContext {
  const ScanEngineContext({
    this.localSegments = const [],
    this.knownHosts = const {},
  });

  /// Directly connected subnets: the only place ARP can reveal a MAC
  /// (spec limitation #8), so single-address ARP lookups run only here.
  final List<Cidr> localSegments;

  /// Addresses seen in earlier scans — probed early, like ARP entries.
  final Set<Ipv4Address> knownHosts;
}

/// Runs a chunked discovery scan and streams results.
///
/// Order, per spec: (1) gather candidates from the ARP table, mDNS and SSDP;
/// (2) probe those known candidates first; (3) sweep the queued chunks with
/// low, bounded concurrency. Every probe checks [ScanControl] before it is
/// scheduled; on stop, in-flight probes drain and each chunk records exactly
/// how far it got, so a resume never skips or repeats an address.
class ScanEngine {
  ScanEngine({
    required ArpTableProvider arpTable,
    required PingProvider ping,
    required ReverseDnsProvider reverseDns,
    required MdnsProvider mdns,
    required SsdpProvider ssdp,
    required PortProbeProvider portProbe,
    required NetbiosProvider netbios,
    HttpBannerProvider? httpBanner,
    this.mdnsWindow = const Duration(seconds: 4),
    this.ssdpWindow = const Duration(seconds: 3),
    this.progressInterval = const Duration(milliseconds: 250),
    DateTime Function()? clock,
  }) : _arpTable = arpTable,
       _ping = ping,
       _reverseDns = reverseDns,
       _mdns = mdns,
       _ssdp = ssdp,
       _portProbe = portProbe,
       _netbios = netbios,
       _httpBanner = httpBanner,
       _clock = clock ?? DateTime.now;

  final ArpTableProvider _arpTable;
  final PingProvider _ping;
  final ReverseDnsProvider _reverseDns;
  final MdnsProvider _mdns;
  final SsdpProvider _ssdp;
  final PortProbeProvider _portProbe;
  final NetbiosProvider _netbios;
  final HttpBannerProvider? _httpBanner;

  /// Web ports whose front page is read for classification, in preference
  /// order; only ones the limited port check found open are tried.
  static const _webPorts = [80, 8080, 443, 8443];
  final Duration mdnsWindow;
  final Duration ssdpWindow;
  final Duration progressInterval;
  final DateTime Function() _clock;

  static const _logger = AppLogger('ScanEngine');

  Stream<ScanEvent> run({
    required ScanCheckpoint from,
    required ScanControl control,
    ScanEngineContext context = const ScanEngineContext(),
  }) {
    final controller = StreamController<ScanEvent>();
    // A listener that goes away (screen disposed, app closing) must not
    // leave probes running in the background.
    controller.onCancel = control.pause;
    controller.onListen = () {
      _ScanRun(
        engine: this,
        checkpoint: from,
        control: control,
        context: context,
        emit: (event) {
          if (!controller.isClosed) controller.add(event);
        },
      ).execute().whenComplete(controller.close);
    };
    return controller.stream;
  }
}

class _ScanRun {
  _ScanRun({
    required this.engine,
    required ScanCheckpoint checkpoint,
    required this.control,
    required this.context,
    required this.emit,
  }) : settings = checkpoint.settings,
       _template = checkpoint,
       chunks = List.of(checkpoint.chunks),
       candidatePassDone = checkpoint.candidatePassDone,
       candidatesProbed = Set.of(checkpoint.candidatesProbed);

  final ScanEngine engine;
  final ScanControl control;
  final ScanEngineContext context;
  final void Function(ScanEvent) emit;
  final ScanSettings settings;
  // Kept only to rebuild checkpoints with the same scope/settings.
  final ScanCheckpoint _template;

  final List<ScanChunk> chunks;
  bool candidatePassDone;
  final Set<int> candidatesProbed;

  /// Chunk index by the /24 an address belongs to — O(1) plan membership
  /// even for the 4096-chunk full block.
  late final Map<int, List<int>> _chunksBy24 = () {
    final map = <int, List<int>>{};
    for (var i = 0; i < chunks.length; i++) {
      final cidr = chunks[i].cidr;
      (map[cidr.networkAddress.value >> 8] ??= []).add(i);
    }
    return map;
  }();

  ScanStage stage = ScanStage.gatheringCandidates;
  Map<Ipv4Address, ArpEntry> _arpByIp = const {};
  Map<Ipv4Address, List<MdnsServiceRecord>> _mdnsByIp = const {};
  Map<Ipv4Address, List<String>> _ssdpByIp = const {};
  DateTime _lastProgressAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool _uses(DiscoveryMethod method) => settings.methods.contains(method);

  ScanCheckpoint get checkpoint => _template.copyWith(
    chunks: List.unmodifiable(chunks),
    candidatePassDone: candidatePassDone,
    candidatesProbed: Set.unmodifiable(candidatesProbed),
  );

  Future<void> execute() async {
    try {
      _emitProgress(persist: false, force: true);
      await _gatherCandidates();
      if (!control.isStopRequested && !candidatePassDone) {
        await _probeCandidates();
      }
      if (!control.isStopRequested) {
        await _sweepChunks();
      }
      _finish(null);
    } on AppFailure catch (failure) {
      _finish(failure);
    } catch (error, stackTrace) {
      _finish(asAppFailure(error, stackTrace));
    }
  }

  void _finish(AppFailure? failure) {
    for (var i = 0; i < chunks.length; i++) {
      if (chunks[i].status == ScanChunkStatus.running) {
        chunks[i] = chunks[i].copyWith(
          status: failure != null
              ? ScanChunkStatus.failed
              : ScanChunkStatus.paused,
        );
      }
    }
    if (failure != null) ScanEngine._logger.failure(failure);
    final status = failure != null
        ? ScanSessionStatus.failed
        : switch (control.request) {
            ScanStopRequest.pause => ScanSessionStatus.paused,
            ScanStopRequest.cancel => ScanSessionStatus.cancelled,
            null => ScanSessionStatus.completed,
          };
    stage = ScanStage.finished;
    emit(
      ScanFinishedEvent(
        status: status,
        checkpoint: checkpoint,
        failure: failure,
      ),
    );
  }

  int? _chunkIndexOf(Ipv4Address address) {
    final candidates = _chunksBy24[address.value >> 8];
    if (candidates == null) return null;
    for (final index in candidates) {
      if (chunks[index].cidr.contains(address)) return index;
    }
    return null;
  }

  bool _isLocal(Ipv4Address address) =>
      context.localSegments.any((segment) => segment.contains(address));

  Future<void> _gatherCandidates() async {
    stage = ScanStage.gatheringCandidates;
    // mDNS/SSDP are listening windows; end them early on stop.
    Future<Map<Ipv4Address, List<T>>> listen<T>(
      Future<Map<Ipv4Address, List<T>>> Function() browse,
    ) {
      return Future.any([
        browse(),
        control.onStopRequested.then((_) => <Ipv4Address, List<T>>{}),
      ]).catchError((Object error, StackTrace stackTrace) {
        // Multicast discovery is best-effort enrichment; the sweep still
        // finds hosts without it.
        ScanEngine._logger.warning('Çok noktaya yayın keşfi başarısız: $error');
        return <Ipv4Address, List<T>>{};
      });
    }

    final results = await Future.wait([
      _uses(DiscoveryMethod.arpTable)
          ? engine._arpTable.getArpTable()
          : Future.value(const <ArpEntry>[]),
      _uses(DiscoveryMethod.mdns)
          ? listen(() => engine._mdns.browse(timeout: engine.mdnsWindow))
          : Future.value(const <Ipv4Address, List<MdnsServiceRecord>>{}),
      _uses(DiscoveryMethod.ssdp)
          ? listen(() => engine._ssdp.search(timeout: engine.ssdpWindow))
          : Future.value(const <Ipv4Address, List<String>>{}),
    ]);

    final arpEntries = results[0] as List<ArpEntry>;
    _arpByIp = {
      for (final entry in arpEntries)
        if (_isUnicastMac(entry.macAddress) &&
            _chunkIndexOf(entry.ipAddress) != null)
          entry.ipAddress: entry,
    };
    _mdnsByIp = results[1] as Map<Ipv4Address, List<MdnsServiceRecord>>;
    _ssdpByIp = results[2] as Map<Ipv4Address, List<String>>;
  }

  Future<void> _probeCandidates() async {
    stage = ScanStage.probingCandidates;
    final candidates =
        {
              ..._arpByIp.keys,
              ..._mdnsByIp.keys,
              ..._ssdpByIp.keys,
              ...context.knownHosts,
            }
            .where(
              (address) =>
                  _chunkIndexOf(address) != null &&
                  !candidatesProbed.contains(address.value),
            )
            .toList()
          ..sort();

    await _runBounded(candidates.iterator, (address) async {
      final found = await _probeHost(address);
      candidatesProbed.add(address.value);
      if (found != null) _recordFound(found);
      _emitProgress();
    }, maxConcurrent: settings.concurrency);

    if (!control.isStopRequested) {
      candidatePassDone = true;
      _emitProgress(persist: true, force: true);
    }
  }

  /// Sweeps up to `settings.chunkConcurrency` `/24` chunks at once — each
  /// internally bounded by `settings.concurrency` — instead of one subnet
  /// at a time. Scanning one chunk at a time is what makes a large scope
  /// (the full `/12` is 4096 chunks) take days; running several in
  /// parallel is a direct multiplier on wall-clock time.
  Future<void> _sweepChunks() async {
    stage = ScanStage.sweeping;
    final pending = [
      for (var i = 0; i < chunks.length; i++)
        if (!chunks[i].isFinished) i,
    ].iterator;

    await _runBounded(
      pending,
      _sweepOneChunk,
      maxConcurrent: settings.chunkConcurrency,
    );
  }

  Future<void> _sweepOneChunk(int index) async {
    if (control.isStopRequested) return;

    final startOffset = chunks[index].hostsScanned;
    chunks[index] = chunks[index].copyWith(status: ScanChunkStatus.running);
    _emitProgress(force: true);

    final addresses = chunks[index].hostAddresses.skip(startOffset).iterator;
    var started = 0;
    var completed = 0;
    final chunkIndex = index;

    await _runBounded(addresses, (address) async {
      started++;
      if (!candidatesProbed.contains(address.value)) {
        final found = await _probeHost(address);
        if (found != null) _recordFound(found);
      }
      completed++;
      chunks[chunkIndex] = chunks[chunkIndex].copyWith(
        hostsScanned: startOffset + completed,
      );
      _emitProgress();
    }, maxConcurrent: settings.concurrency);

    // Everything started has drained, so the offset is exact.
    final chunk = chunks[index].copyWith(hostsScanned: startOffset + started);
    final finished = chunk.hostsScanned >= chunk.hostsTotal;
    chunks[index] = chunk.copyWith(
      status: finished
          ? ScanChunkStatus.completed
          : control.request == ScanStopRequest.cancel
          ? ScanChunkStatus.cancelled
          : ScanChunkStatus.paused,
    );
    _emitProgress(persist: true, force: true);
  }

  /// Runs [task] for each item with at most [maxConcurrent] in flight,
  /// without materializing the whole item list. Stops scheduling as soon as
  /// a stop is requested, then waits for in-flight tasks to drain.
  Future<void> _runBounded<T>(
    Iterator<T> items,
    Future<void> Function(T item) task, {
    required int maxConcurrent,
  }) async {
    final inFlight = <Future<void>>{};
    Object? firstError;
    StackTrace? firstStackTrace;

    while (!control.isStopRequested && firstError == null && items.moveNext()) {
      final item = items.current;
      late final Future<void> future;
      future = task(item)
          .catchError((Object error, StackTrace stackTrace) {
            firstError ??= error;
            firstStackTrace ??= stackTrace;
          })
          .whenComplete(() => inFlight.remove(future));
      inFlight.add(future);
      if (inFlight.length >= maxConcurrent) {
        await Future.any(inFlight);
      }
    }
    await Future.wait(inFlight);
    if (firstError != null) {
      Error.throwWithStackTrace(firstError!, firstStackTrace!);
    }
  }

  void _recordFound(DiscoveredDevice device) {
    final index = _chunkIndexOf(device.ipAddress);
    if (index != null) {
      chunks[index] = chunks[index].copyWith(
        devicesFound: chunks[index].devicesFound + 1,
      );
    }
    emit(ScanHostFoundEvent(device));
  }

  /// Probes one address. Returns null when nothing proved the host is
  /// there — which is "not found", never "offline".
  Future<DiscoveredDevice?> _probeHost(Ipv4Address address) async {
    final signals = <String>[];
    var alive = false;
    int? ttl;

    if (_uses(DiscoveryMethod.icmpPing)) {
      final reply = await engine._ping.ping(
        address,
        timeout: settings.pingTimeout,
      );
      if (reply != null) {
        alive = true;
        ttl = reply.ttl;
        signals.add('ICMP yanıtı');
        final ttlSignal = reply.ttlSignal;
        if (ttlSignal != null) signals.add(ttlSignal);
      }
    }

    var arpEntry = _arpByIp[address];
    if (arpEntry != null) {
      signals.add('ARP tablosunda');
    } else if (_uses(DiscoveryMethod.arpTable) && _isLocal(address)) {
      // The probe above made the kernel ARP for this address; a hit proves
      // the host exists even if it drops ICMP.
      final looked = await engine._arpTable.lookup(address);
      if (looked != null && _isUnicastMac(looked.macAddress)) {
        arpEntry = looked;
        signals.add('ARP yanıtı');
      }
    }
    if (arpEntry != null) alive = true;

    final mdnsRecords = _mdnsByIp[address] ?? const <MdnsServiceRecord>[];
    final ssdpServices = _ssdpByIp[address] ?? const [];
    if (mdnsRecords.isNotEmpty) {
      alive = true;
      signals.add('mDNS/Bonjour yanıtı');
    }
    if (ssdpServices.isNotEmpty) {
      alive = true;
      signals.add('SSDP/UPnP yanıtı');
    }

    // Probed before the liveness verdict: a routed host that drops ICMP
    // (and whose MAC ARP can't reveal) is still found by an open port.
    var openPorts = const <int>[];
    if (_uses(DiscoveryMethod.limitedPortScan) &&
        settings.limitedPorts.isNotEmpty &&
        !control.isStopRequested) {
      openPorts = await engine._portProbe.probeOpenPorts(
        address,
        settings.limitedPorts,
        timeout: settings.portProbeTimeout,
      );
      if (openPorts.isNotEmpty) {
        alive = true;
        signals.add('TCP port yanıtı');
      }
    }

    if (!alive) return null;

    // Name, in order of reliability: reverse DNS, the host's own mDNS
    // name, then (only if still unnamed) a single NetBIOS query.
    String? hostname;
    if (_uses(DiscoveryMethod.reverseDns)) {
      hostname = await engine._reverseDns.lookup(
        address,
        timeout: settings.pingTimeout * 2,
      );
    }
    hostname ??= mdnsRecords
        .map((record) => record.hostname)
        .whereType<String>()
        .firstOrNull;
    String? netbiosName;
    if (hostname == null &&
        _uses(DiscoveryMethod.netbios) &&
        !control.isStopRequested) {
      netbiosName = await engine._netbios.lookupName(
        address,
        timeout: settings.portProbeTimeout,
      );
      if (netbiosName != null) signals.add('NetBIOS adı: $netbiosName');
    }

    HttpBanner? banner;
    final bannerProvider = engine._httpBanner;
    if (bannerProvider != null &&
        _uses(DiscoveryMethod.httpBanner) &&
        !control.isStopRequested) {
      for (final port in ScanEngine._webPorts) {
        if (!openPorts.contains(port)) continue;
        banner = await bannerProvider.fetch(
          address,
          port,
          timeout: settings.portProbeTimeout * 4,
        );
        if (banner != null) break;
      }
    }

    return DiscoveredDevice(
      ipAddress: address,
      respondedAt: engine._clock(),
      httpBanner: banner,
      macAddress: arpEntry?.macAddress,
      hostname: hostname ?? netbiosName,
      netbiosName: netbiosName,
      ttl: ttl,
      mdnsRecords: mdnsRecords,
      ssdpServices: ssdpServices,
      openPorts: openPorts,
      signals: signals,
    );
  }

  void _emitProgress({bool persist = false, bool force = false}) {
    final now = engine._clock();
    if (!force &&
        !persist &&
        now.difference(_lastProgressAt) < engine.progressInterval) {
      return;
    }
    _lastProgressAt = now;
    emit(
      ScanProgressEvent(checkpoint: checkpoint, stage: stage, persist: persist),
    );
  }
}

/// Broadcast (`ff:ff:…`) and multicast (low bit of the first octet set)
/// entries in the ARP table are not devices.
bool _isUnicastMac(String normalizedMac) {
  final firstOctet = int.tryParse(normalizedMac.substring(0, 2), radix: 16);
  return firstOctet != null && firstOctet & 1 == 0;
}
