/// How long each granularity of traffic data is kept.
///
/// Raw samples (one per poll) are rolled up into local-hour rows after
/// [rawRetention]; hour rows are rolled up into local-day rows after
/// [hourlyRetention]; day rows are deleted after [dailyRetention].
///
/// Expected: rawRetention <= hourlyRetention <= dailyRetention and
/// hourlyRetention >= [minimumHourlyRetention].
class TrafficRetentionPolicy {
  const TrafficRetentionPolicy({
    this.rawRetention = const Duration(hours: 48),
    this.hourlyRetention = const Duration(days: 8),
    this.dailyRetention = const Duration(days: 90),
  });

  /// The 24-hour chart needs hour-level data for at least the last day.
  static const minimumHourlyRetention = Duration(days: 2);

  final Duration rawRetention;
  final Duration hourlyRetention;
  final Duration dailyRetention;

  factory TrafficRetentionPolicy.withDailyRetentionDays(int days) {
    const defaults = TrafficRetentionPolicy();
    final daily = Duration(days: days);
    return TrafficRetentionPolicy(
      dailyRetention: daily < defaults.hourlyRetention
          ? defaults.hourlyRetention
          : daily,
    );
  }
}
