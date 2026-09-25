import 'traffic_counter_snapshot.dart';

/// Static description of a [TrafficProvider] implementation.
class TrafficProviderDescriptor {
  const TrafficProviderDescriptor({
    required this.id,
    required this.displayName,
    required this.description,
    required this.perspective,
    this.isDemo = false,
    this.requiresCredentials = false,
  });

  /// Stable id; also stored as `traffic_samples.source`.
  final String id;
  final String displayName;
  final String description;
  final CounterPerspective perspective;

  /// Demo providers produce simulated data; everything they write is marked
  /// as such and must never be presented as a real measurement.
  final bool isDemo;

  /// Whether the provider needs router credentials from the Keychain.
  final bool requiresCredentials;
}
