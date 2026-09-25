import 'traffic_device_identity.dart';

/// Bytes a device moved during [periodStart]–[periodEnd], from the device's
/// point of view (download = received by the device).
class ProviderUsageRecord {
  const ProviderUsageRecord({
    required this.key,
    required this.identity,
    required this.periodStart,
    required this.periodEnd,
    required this.downloadBytes,
    required this.uploadBytes,
  });

  /// Unique per record at the source (e.g. session id + event time), so a
  /// record read twice is recognized.
  final String key;
  final TrafficDeviceIdentity identity;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int downloadBytes;
  final int uploadBytes;
}

/// Where the last read stopped: records ending after [endedAfter] are new,
/// plus those ending exactly at it whose key isn't in [keysAtBoundary].
class UsageCursor {
  const UsageCursor({required this.endedAfter, this.keysAtBoundary = const {}});

  final DateTime endedAfter;
  final Set<String> keysAtBoundary;

  bool isNew(ProviderUsageRecord record) =>
      record.periodEnd.isAfter(endedAfter) ||
      (record.periodEnd.isAtSameMomentAs(endedAfter) &&
          !keysAtBoundary.contains(record.key));

  /// The cursor after also having read [records].
  UsageCursor advancedPast(Iterable<ProviderUsageRecord> records) {
    var latest = endedAfter;
    for (final record in records) {
      if (record.periodEnd.isAfter(latest)) latest = record.periodEnd;
    }
    return UsageCursor(
      endedAfter: latest,
      keysAtBoundary: {
        if (latest.isAtSameMomentAs(endedAfter)) ...keysAtBoundary,
        for (final record in records)
          if (record.periodEnd.isAtSameMomentAs(latest)) record.key,
      },
    );
  }

  Map<String, Object?> toJson() => {
    'endedAfterMicros': endedAfter.microsecondsSinceEpoch,
    'keysAtBoundary': keysAtBoundary.toList(),
  };

  static UsageCursor? tryFromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final micros = json['endedAfterMicros'];
    final keys = json['keysAtBoundary'];
    if (micros is! int) return null;
    return UsageCursor(
      endedAfter: DateTime.fromMicrosecondsSinceEpoch(micros),
      keysAtBoundary: keys is List
          ? keys.whereType<String>().toSet()
          : const {},
    );
  }
}

class TrafficUsageBatch {
  const TrafficUsageBatch({
    required this.records,
    required this.next,
    this.truncated = false,
  });

  /// Only records that are new relative to the cursor that was read from.
  final List<ProviderUsageRecord> records;
  final UsageCursor next;

  /// The source had more than one poll may read; older records may be
  /// missing.
  final bool truncated;
}
