import 'discovery_method.dart';
import 'scan_chunk.dart';
import 'scan_scope_type.dart';
import 'scan_settings.dart';

/// What the UI shows before a scan starts: the resolved CIDR list, how many
/// candidate hosts that is, an estimated duration, which discovery methods
/// will run, and the concurrency/timeout that produced the estimate.
class ScanPlan {
  const ScanPlan({
    required this.scopeType,
    required this.chunks,
    required this.settings,
  });

  final ScanScopeType scopeType;
  final List<ScanChunk> chunks;
  final ScanSettings settings;

  /// Addresses that will actually be probed (see [ScanChunk.hostAddresses]).
  int get totalCandidateHosts =>
      chunks.fold(0, (sum, chunk) => sum + chunk.hostsTotal);

  /// Raw address count of the scope, including each chunk's network and
  /// broadcast address.
  int get totalAddresses => chunks.fold(
    0,
    (sum, chunk) => sum + chunk.cidr.totalAddressCount.toInt(),
  );

  Set<DiscoveryMethod> get methods => settings.methods;

  /// Largest scan that may start without explicit confirmation: one /24.
  static const unconfirmedHostLimit = 254;

  /// Decided by the plan's actual size, not by which scope option produced
  /// it: "all accessible subnets" can resolve to the whole /12 when the
  /// route table carries a `172.16.0.0/12` route.
  bool get requiresConfirmation => totalCandidateHosts > unconfirmedHostLimit;

  /// Worst-case estimate for a silent host, which dominates a sweep: the
  /// ping timeout plus (ports are probed in parallel per host) one port
  /// timeout, at up to `concurrency × chunkConcurrency` hosts in parallel
  /// (several `/24` chunks swept at once, each internally bounded by
  /// [ScanSettings.concurrency]).
  Duration get estimatedDuration {
    var perHostMs = 0;
    if (settings.methods.contains(DiscoveryMethod.icmpPing)) {
      perHostMs += settings.pingTimeout.inMilliseconds;
    }
    if (settings.methods.contains(DiscoveryMethod.limitedPortScan) &&
        settings.limitedPorts.isNotEmpty) {
      perHostMs += settings.portProbeTimeout.inMilliseconds;
    }
    if (perHostMs == 0) return const Duration(seconds: 5);
    final effectiveConcurrency =
        settings.concurrency * settings.chunkConcurrency;
    final batches = (totalCandidateHosts / effectiveConcurrency).ceil();
    return Duration(milliseconds: batches * perHostMs);
  }
}
