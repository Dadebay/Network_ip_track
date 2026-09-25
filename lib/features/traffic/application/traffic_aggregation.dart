import '../domain/entities/traffic_sample.dart';
import 'local_time_buckets.dart';

/// Rolls [samples] up into one row per device, source, MAC/IP binding and
/// local bucket. The bucket is chosen by `periodStart` (samples never cross
/// a local hour boundary, see [splitAtLocalHourBoundaries]). Aggregates keep the
/// least reliable input's reliability.
///
/// Grouping by binding keeps the "which MAC had which IP" history intact
/// after aggregation.
List<TrafficSample> rollUpSamples(
  Iterable<TrafficSample> samples,
  TrafficBucketSize size,
) {
  final groups = <_RollUpKey, TrafficSample>{};
  for (final sample in samples) {
    final start = bucketStart(sample.periodStart, size);
    final key = _RollUpKey(
      deviceId: sample.deviceId,
      source: sample.source,
      macAddress: sample.identity.macAddress,
      ipAddress: sample.identity.ipAddress,
      bucketStart: start,
    );
    final existing = groups[key];
    groups[key] = existing == null
        ? TrafficSample(
            deviceId: sample.deviceId,
            identity: sample.identity,
            periodStart: start,
            periodEnd: bucketEnd(start, size),
            downloadBytes: sample.downloadBytes,
            uploadBytes: sample.uploadBytes,
            source: sample.source,
            reliability: sample.reliability,
          )
        : TrafficSample(
            deviceId: existing.deviceId,
            identity: existing.identity,
            periodStart: existing.periodStart,
            periodEnd: existing.periodEnd,
            downloadBytes: existing.downloadBytes + sample.downloadBytes,
            uploadBytes: existing.uploadBytes + sample.uploadBytes,
            source: existing.source,
            reliability: existing.reliability.worstOf(sample.reliability),
          );
  }
  final result = groups.values.toList()
    ..sort((a, b) => a.periodStart.compareTo(b.periodStart));
  return result;
}

class _RollUpKey {
  const _RollUpKey({
    required this.deviceId,
    required this.source,
    required this.macAddress,
    required this.ipAddress,
    required this.bucketStart,
  });

  final int deviceId;
  final String source;
  final String? macAddress;
  final String? ipAddress;
  final DateTime bucketStart;

  @override
  bool operator ==(Object other) =>
      other is _RollUpKey &&
      other.deviceId == deviceId &&
      other.source == source &&
      other.macAddress == macAddress &&
      other.ipAddress == ipAddress &&
      other.bucketStart.isAtSameMomentAs(bucketStart);

  @override
  int get hashCode => Object.hash(
    deviceId,
    source,
    macAddress,
    ipAddress,
    bucketStart.microsecondsSinceEpoch,
  );
}
