/// How trustworthy a traffic sample's byte counts are.
///
/// Ordered from most to least trustworthy: an aggregate is only as reliable
/// as its least reliable input (see [worstOf]).
enum TrafficReliability {
  /// Direct per-device counter delta reported by the provider.
  measured,

  /// The total is exact, but how it is distributed over time was estimated —
  /// e.g. a polling interval split proportionally at local midnight.
  estimated,

  /// Produced by the demo provider. Never real usage.
  simulated;

  TrafficReliability worstOf(TrafficReliability other) =>
      index >= other.index ? this : other;

  static TrafficReliability parse(String raw) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
    // Unknown value (e.g. written by a newer version): don't claim it was
    // measured.
    return estimated;
  }
}
