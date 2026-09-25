/// Local-time bucket boundaries. Day and hour boundaries always follow the
/// machine's local time zone (including DST), never UTC.
enum TrafficBucketSize { hour, day }

/// Local midnight at or before [time].
DateTime startOfLocalDay(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// The local midnight after [time]. Built from calendar fields rather than
/// `+ 24h` so 23- and 25-hour DST days are handled.
DateTime startOfNextLocalDay(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day + 1);
}

/// Start of the local hour containing [time]. Subtracts the sub-hour fields
/// instead of rebuilding from calendar fields, which would be ambiguous in
/// the repeated hour when DST ends.
DateTime startOfLocalHour(DateTime time) {
  final local = time.toLocal();
  return local.subtract(
    Duration(
      minutes: local.minute,
      seconds: local.second,
      milliseconds: local.millisecond,
      microseconds: local.microsecond,
    ),
  );
}

DateTime bucketStart(DateTime time, TrafficBucketSize size) => switch (size) {
  TrafficBucketSize.hour => startOfLocalHour(time),
  TrafficBucketSize.day => startOfLocalDay(time),
};

DateTime bucketEnd(DateTime start, TrafficBucketSize size) => switch (size) {
  TrafficBucketSize.hour => start.add(const Duration(hours: 1)),
  TrafficBucketSize.day => startOfNextLocalDay(start),
};
