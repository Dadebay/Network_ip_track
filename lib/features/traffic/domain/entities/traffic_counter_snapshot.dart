import 'traffic_device_identity.dart';

/// Whose point of view a provider's rx/tx counters are reported from.
enum CounterPerspective {
  /// rx = the device downloaded, tx = the device uploaded.
  device,

  /// Counters on the router/gateway port facing the device: rx = the device
  /// uploaded, tx = the device downloaded.
  gateway,
}

/// One cumulative (monotonic) per-device counter reading, exactly as the
/// provider reported it. Direction is normalized later using the provider's
/// [CounterPerspective].
class TrafficCounterSnapshot {
  const TrafficCounterSnapshot({
    required this.identity,
    required this.readAt,
    required this.receivedBytes,
    required this.transmittedBytes,
  });

  final TrafficDeviceIdentity identity;
  final DateTime readAt;
  final int receivedBytes;
  final int transmittedBytes;
}
