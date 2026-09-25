import '../entities/device_traffic_summary.dart';
import '../entities/traffic_retention_policy.dart';
import '../entities/traffic_sample.dart';

class TrafficRetentionReport {
  const TrafficRetentionReport({
    required this.rolledUpToHourly,
    required this.rolledUpToDaily,
    required this.deleted,
  });

  /// Input rows replaced by hour rows.
  final int rolledUpToHourly;

  /// Input rows replaced by day rows.
  final int rolledUpToDaily;

  /// Rows removed because they exceeded the daily retention.
  final int deleted;
}

abstract interface class TrafficSampleRepository {
  Future<void> insertSamples(List<TrafficSample> samples);

  /// Samples of [deviceId] whose `period_start` is in [from, to).
  Future<List<TrafficSample>> samplesForDevice(
    int deviceId, {
    required DateTime from,
    required DateTime to,
  });

  /// Download/upload totals per device over samples whose `period_start` is
  /// in [from, to). Devices without samples are absent (unknown, not zero).
  /// Exact for whole local days: samples never cross local midnight.
  Future<Map<int, TrafficTotals>> totalsByDevice({
    required DateTime from,
    required DateTime to,
  });

  /// Rolls up old raw rows into local-hour rows, old hour rows into
  /// local-day rows, and deletes rows past the daily retention.
  Future<TrafficRetentionReport> applyRetention({
    required DateTime now,
    required TrafficRetentionPolicy policy,
  });

  /// Removes every sample written by [source] (e.g. demo data when the demo
  /// provider is switched off). Returns the number of rows deleted.
  Future<int> deleteBySource(String source);
}
