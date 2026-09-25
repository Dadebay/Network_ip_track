import '../entities/traffic_connection_test_result.dart';
import '../entities/traffic_counter_snapshot.dart';
import '../entities/traffic_provider_descriptor.dart';
import '../entities/traffic_usage_batch.dart';

/// A source of per-device traffic (router API, controller API, gateway
/// agent, NetFlow collector, per-device SNMP, demo).
///
/// Two shapes exist, because real systems expose one or the other:
/// [CounterTrafficProvider] (cumulative per-device counters) and
/// [UsageTrafficProvider] (usage already attributed to time intervals, e.g.
/// per-session firewall logs).
///
/// Never divide an interface total across devices to implement this — a
/// provider must have real per-device data.
sealed class TrafficProvider {
  TrafficProviderDescriptor get descriptor;

  /// Checks reachability/authentication without persisting anything.
  /// Never throws; failures are returned in the result.
  Future<TrafficConnectionTestResult> testConnection();
}

/// Reports cumulative counters as-is; delta computation, reset handling,
/// direction normalization and local-time splitting happen in the
/// application layer so every provider gets the same semantics.
abstract class CounterTrafficProvider implements TrafficProvider {
  /// Current cumulative counters for every device the provider knows.
  ///
  /// Throws an [AppFailure] (e.g. [TrafficProviderUnreachableFailure],
  /// [TrafficProviderAuthFailure]) on error.
  Future<List<TrafficCounterSnapshot>> readCounters();
}

/// Reports usage records (bytes over a known interval) from the device's
/// point of view. Reading resumes from a persisted [UsageCursor] so nothing
/// is counted twice across polls or app restarts.
abstract class UsageTrafficProvider implements TrafficProvider {
  /// Records that ended after [after]; throws an [AppFailure] on error.
  Future<TrafficUsageBatch> readUsage({required UsageCursor after});
}
