import '../domain/entities/traffic_counter_snapshot.dart';
import '../domain/entities/traffic_device_identity.dart';
import '../domain/entities/traffic_reliability.dart';
import '../domain/entities/traffic_sample.dart';
import 'local_time_buckets.dart';

/// A cumulative counter reading with direction normalized to the device's
/// point of view.
class NormalizedCounterReading {
  const NormalizedCounterReading({
    required this.identity,
    required this.readAt,
    required this.downloadTotal,
    required this.uploadTotal,
  });

  factory NormalizedCounterReading.fromSnapshot(
    TrafficCounterSnapshot snapshot,
    CounterPerspective perspective,
  ) {
    final (download, upload) = switch (perspective) {
      CounterPerspective.device => (
        snapshot.receivedBytes,
        snapshot.transmittedBytes,
      ),
      CounterPerspective.gateway => (
        snapshot.transmittedBytes,
        snapshot.receivedBytes,
      ),
    };
    return NormalizedCounterReading(
      identity: snapshot.identity,
      readAt: snapshot.readAt,
      downloadTotal: download,
      uploadTotal: upload,
    );
  }

  final TrafficDeviceIdentity identity;
  final DateTime readAt;
  final int downloadTotal;
  final int uploadTotal;
}

sealed class CounterDeltaResult {
  const CounterDeltaResult(this.reading);

  final NormalizedCounterReading reading;
}

/// First reading for this device: nothing to compare against yet, so no
/// usage is counted.
class CounterBaseline extends CounterDeltaResult {
  const CounterBaseline(super.reading);
}

/// Usage between the previous and the current reading.
class CounterUsage extends CounterDeltaResult {
  const CounterUsage(super.reading, this.usage);

  final TrafficUsage usage;
}

/// A counter went backwards (router reboot, counter reset, 32-bit wrap).
/// The negative difference is not counted; the current reading becomes the
/// new baseline.
class CounterReset extends CounterDeltaResult {
  const CounterReset(super.reading);
}

/// The reading is not newer than the previous one (clock change, duplicate
/// poll). No usage is counted; the current reading becomes the new baseline.
class CounterClockAnomaly extends CounterDeltaResult {
  const CounterClockAnomaly(super.reading);
}

/// Difference between two consecutive readings of the same counter.
///
/// If *either* direction decreased, the whole reading is treated as a reset:
/// after a reset the other direction's difference is measured against a
/// stale baseline too, so counting it would be made-up usage.
CounterDeltaResult computeCounterDelta({
  required NormalizedCounterReading? previous,
  required NormalizedCounterReading current,
  required String source,
  required TrafficReliability reliability,
}) {
  if (previous == null) return CounterBaseline(current);
  if (!current.readAt.isAfter(previous.readAt)) {
    return CounterClockAnomaly(current);
  }

  final download = current.downloadTotal - previous.downloadTotal;
  final upload = current.uploadTotal - previous.uploadTotal;
  if (download < 0 || upload < 0) return CounterReset(current);

  return CounterUsage(
    current,
    TrafficUsage(
      // The binding observed at the end of the interval.
      identity: current.identity,
      periodStart: previous.readAt,
      periodEnd: current.readAt,
      downloadBytes: download,
      uploadBytes: upload,
      source: source,
      reliability: reliability,
    ),
  );
}

/// Remembers the last reading per device ([TrafficDeviceIdentity.counterKey])
/// and turns a stream of cumulative readings into deltas.
///
/// State is in memory only: after an app restart the first reading is a new
/// baseline, because usage while the app was not running is unknown.
class CounterDeltaTracker {
  final _last = <String, NormalizedCounterReading>{};

  List<CounterDeltaResult> ingest(
    Iterable<NormalizedCounterReading> readings, {
    required String source,
    required TrafficReliability reliability,
  }) {
    final results = <CounterDeltaResult>[];
    for (final reading in readings) {
      final key = reading.identity.counterKey;
      results.add(
        computeCounterDelta(
          previous: _last[key],
          current: reading,
          source: source,
          reliability: reliability,
        ),
      );
      _last[key] = reading;
    }
    return results;
  }

  void clear() => _last.clear();
}

/// Intervals up to this long are split without being marked estimated: at
/// minute-level polling the proportional error is negligible, and without
/// this nearly every reading that crosses an hour would be "tahmini".
const exactSplitMaxSpan = Duration(minutes: 5);

/// Splits [usage] at local midnight so every piece belongs to exactly one
/// local day. See [splitAtLocalBoundaries].
List<TrafficUsage> splitAtLocalDayBoundaries(TrafficUsage usage) =>
    splitAtLocalBoundaries(usage, TrafficBucketSize.day);

/// Splits [usage] at every local hour boundary (which includes midnight),
/// so a long gap — e.g. the Mac slept for hours — lands on the hours it
/// actually spans instead of the hour it started in. See
/// [splitAtLocalBoundaries].
List<TrafficUsage> splitAtLocalHourBoundaries(TrafficUsage usage) =>
    splitAtLocalBoundaries(usage, TrafficBucketSize.hour);

/// Splits [usage] at local [size] boundaries so every piece belongs to
/// exactly one local bucket. Bytes are distributed proportionally to time
/// (the provider only tells us the total), so pieces of an interval longer
/// than [exactSplitMaxSpan] are marked [TrafficReliability.estimated]. Piece
/// totals always add up exactly to the original.
List<TrafficUsage> splitAtLocalBoundaries(
  TrafficUsage usage,
  TrafficBucketSize size,
) {
  final start = usage.periodStart;
  final end = usage.periodEnd;
  final firstBoundary = bucketEnd(bucketStart(start, size), size);
  if (!firstBoundary.isBefore(end)) return [usage];

  final edges = <DateTime>[start];
  for (
    var boundary = firstBoundary;
    boundary.isBefore(end);
    boundary = bucketEnd(boundary, size)
  ) {
    edges.add(boundary);
  }
  edges.add(end);

  final totalMicros = end.difference(start).inMicroseconds;
  final reliability = end.difference(start) > exactSplitMaxSpan
      ? usage.reliability.worstOf(TrafficReliability.estimated)
      : usage.reliability;
  final pieces = <TrafficUsage>[];
  var allocatedDown = 0;
  var allocatedUp = 0;
  for (var i = 0; i < edges.length - 1; i++) {
    final isLast = i == edges.length - 2;
    final fraction =
        edges[i + 1].difference(start).inMicroseconds / totalMicros;
    // Allocate by cumulative fraction so rounding never loses or adds bytes.
    final downUntilHere = isLast
        ? usage.downloadBytes
        : (usage.downloadBytes * fraction).round();
    final upUntilHere = isLast
        ? usage.uploadBytes
        : (usage.uploadBytes * fraction).round();
    pieces.add(
      TrafficUsage(
        identity: usage.identity,
        periodStart: edges[i],
        periodEnd: edges[i + 1],
        downloadBytes: downUntilHere - allocatedDown,
        uploadBytes: upUntilHere - allocatedUp,
        source: usage.source,
        reliability: reliability,
      ),
    );
    allocatedDown = downUntilHere;
    allocatedUp = upUntilHere;
  }
  return pieces;
}
