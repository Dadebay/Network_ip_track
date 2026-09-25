import '../domain/entities/device_traffic_summary.dart';
import '../domain/entities/traffic_reliability.dart';
import '../domain/entities/traffic_sample.dart';
import 'local_time_buckets.dart';

/// First instant [buildDeviceTrafficSummary] looks at: local midnight six
/// days before [now] (7 local days including today).
DateTime trafficSummaryRangeStart(DateTime now) {
  final local = now.toLocal();
  return DateTime(local.year, local.month, local.day - 6);
}

/// Builds today's totals, the last 24 local hours and the last 7 local days
/// from one device's samples. A sample is counted in the bucket containing
/// its `periodStart`.
DeviceTrafficSummary buildDeviceTrafficSummary({
  required List<TrafficSample> samples,
  required DateTime now,
}) {
  final currentHour = startOfLocalHour(now);
  final hourStarts = [
    for (var i = 23; i >= 0; i--) currentHour.subtract(Duration(hours: i)),
  ];
  final local = now.toLocal();
  final dayStarts = [
    for (var i = 6; i >= 0; i--)
      DateTime(local.year, local.month, local.day - i),
  ];

  final hourly = _fillBuckets(samples, hourStarts, TrafficBucketSize.hour);
  final daily = _fillBuckets(samples, dayStarts, TrafficBucketSize.day);

  TrafficReliability? worst;
  final sources = <String>{};
  final rangeStart = dayStarts.first;
  for (final sample in samples) {
    if (sample.periodStart.isBefore(rangeStart)) continue;
    sources.add(sample.source);
    worst = worst == null
        ? sample.reliability
        : worst.worstOf(sample.reliability);
  }

  return DeviceTrafficSummary(
    today: daily.last.totals,
    hasTodayData: daily.last.hasData,
    hourly: hourly,
    daily: daily,
    sources: sources,
    worstReliability: worst,
  );
}

List<TrafficBucket> _fillBuckets(
  List<TrafficSample> samples,
  List<DateTime> starts,
  TrafficBucketSize size,
) {
  final ends = [for (final start in starts) bucketEnd(start, size)];
  final totals = List.filled(starts.length, TrafficTotals.zero);
  final hasData = List.filled(starts.length, false);

  for (final sample in samples) {
    final at = sample.periodStart;
    // 24 or 7 buckets: a linear scan is cheaper than anything clever.
    for (var i = 0; i < starts.length; i++) {
      if (!at.isBefore(starts[i]) && at.isBefore(ends[i])) {
        totals[i] =
            totals[i] +
            TrafficTotals(
              downloadBytes: sample.downloadBytes,
              uploadBytes: sample.uploadBytes,
            );
        hasData[i] = true;
        break;
      }
    }
  }

  return [
    for (var i = 0; i < starts.length; i++)
      TrafficBucket(
        start: starts[i],
        end: ends[i],
        totals: totals[i],
        hasData: hasData[i],
      ),
  ];
}
