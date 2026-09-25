import 'traffic_reliability.dart';

class TrafficTotals {
  const TrafficTotals({required this.downloadBytes, required this.uploadBytes});

  static const zero = TrafficTotals(downloadBytes: 0, uploadBytes: 0);

  final int downloadBytes;
  final int uploadBytes;

  int get totalBytes => downloadBytes + uploadBytes;

  TrafficTotals operator +(TrafficTotals other) => TrafficTotals(
    downloadBytes: downloadBytes + other.downloadBytes,
    uploadBytes: uploadBytes + other.uploadBytes,
  );

  @override
  bool operator ==(Object other) =>
      other is TrafficTotals &&
      other.downloadBytes == downloadBytes &&
      other.uploadBytes == uploadBytes;

  @override
  int get hashCode => Object.hash(downloadBytes, uploadBytes);

  @override
  String toString() => 'TrafficTotals(down: $downloadBytes, up: $uploadBytes)';
}

/// One chart bar: a local hour or local day.
class TrafficBucket {
  const TrafficBucket({
    required this.start,
    required this.end,
    required this.totals,
    required this.hasData,
  });

  final DateTime start;
  final DateTime end;
  final TrafficTotals totals;

  /// False when no sample covers this bucket. That is "unknown", not zero.
  final bool hasData;
}

class DeviceTrafficSummary {
  const DeviceTrafficSummary({
    required this.today,
    required this.hasTodayData,
    required this.hourly,
    required this.daily,
    required this.sources,
    required this.worstReliability,
  });

  final TrafficTotals today;
  final bool hasTodayData;

  /// Last 24 local hours, oldest first; the last bucket is the current hour.
  final List<TrafficBucket> hourly;

  /// Last 7 local days, oldest first; the last bucket is today.
  final List<TrafficBucket> daily;

  /// Provider ids that contributed samples.
  final Set<String> sources;

  /// Null when there are no samples.
  final TrafficReliability? worstReliability;

  bool get hasAnyData =>
      hourly.any((b) => b.hasData) || daily.any((b) => b.hasData);

  bool get containsSimulatedData =>
      worstReliability == TrafficReliability.simulated;
}
