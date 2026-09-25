import '../entities/traffic_device_identity.dart';

/// Maps provider-reported MAC/IP bindings to `devices.id` of the network the
/// Mac is currently on.
abstract interface class TrafficDeviceResolver {
  /// Returns device ids keyed by [TrafficDeviceIdentity.counterKey].
  /// Identities that cannot be matched unambiguously are omitted — their
  /// usage is dropped rather than attributed to a guessed device.
  Future<Map<String, int>> resolveDeviceIds(
    Iterable<TrafficDeviceIdentity> identities,
  );
}
