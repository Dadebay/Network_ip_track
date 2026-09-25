import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/traffic/application/counter_delta.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_counter_snapshot.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_device_identity.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_reliability.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_sample.dart';

final _phone = TrafficDeviceIdentity.tryCreate(
  macAddress: 'AA-BB-CC-00-11-22',
  ipAddress: '192.168.1.20',
)!;

NormalizedCounterReading _reading(
  DateTime at,
  int down,
  int up, {
  TrafficDeviceIdentity? identity,
}) => NormalizedCounterReading(
  identity: identity ?? _phone,
  readAt: at,
  downloadTotal: down,
  uploadTotal: up,
);

CounterDeltaResult _delta(
  NormalizedCounterReading? previous,
  NormalizedCounterReading current,
) => computeCounterDelta(
  previous: previous,
  current: current,
  source: 'test',
  reliability: TrafficReliability.measured,
);

void main() {
  final t0 = DateTime(2026, 9, 24, 10);
  final t1 = t0.add(const Duration(minutes: 1));

  group('computeCounterDelta', () {
    test('first reading is only a baseline', () {
      expect(_delta(null, _reading(t0, 5000, 100)), isA<CounterBaseline>());
    });

    test('counts the difference between consecutive readings', () {
      final result = _delta(_reading(t0, 1000, 200), _reading(t1, 4500, 260));

      final usage = (result as CounterUsage).usage;
      expect(usage.downloadBytes, 3500);
      expect(usage.uploadBytes, 60);
      expect(usage.periodStart, t0);
      expect(usage.periodEnd, t1);
      expect(usage.reliability, TrafficReliability.measured);
    });

    test('a counter reset is not counted as usage', () {
      final result = _delta(
        _reading(t0, 9000000, 50000),
        _reading(t1, 1200, 80),
      );
      expect(result, isA<CounterReset>());
    });

    test('a 32-bit wrap is treated as a reset, not as usage', () {
      final result = _delta(
        _reading(t0, 4294967000, 10),
        _reading(t1, 300, 20),
      );
      expect(result, isA<CounterReset>());
    });

    test('one direction going backwards invalidates the whole reading', () {
      // Upload grew, but download reset: the upload difference is measured
      // against a stale baseline too.
      final result = _delta(_reading(t0, 50000, 100), _reading(t1, 10, 900));
      expect(result, isA<CounterReset>());
    });

    test('a reading that is not newer is a clock anomaly', () {
      expect(
        _delta(_reading(t1, 1000, 10), _reading(t0, 2000, 20)),
        isA<CounterClockAnomaly>(),
      );
      expect(
        _delta(_reading(t0, 1000, 10), _reading(t0, 2000, 20)),
        isA<CounterClockAnomaly>(),
      );
    });

    test('keeps the MAC-IP binding observed at the sample time', () {
      final moved = TrafficDeviceIdentity.tryCreate(
        macAddress: 'aa:bb:cc:00:11:22',
        ipAddress: '192.168.1.77',
      )!;
      final result = _delta(
        _reading(t0, 100, 10),
        _reading(t1, 400, 40, identity: moved),
      );
      final usage = (result as CounterUsage).usage;
      expect(usage.identity.macAddress, 'aa:bb:cc:00:11:22');
      expect(usage.identity.ipAddress, '192.168.1.77');
    });
  });

  group('NormalizedCounterReading.fromSnapshot', () {
    final snapshot = TrafficCounterSnapshot(
      identity: _phone,
      readAt: t0,
      receivedBytes: 700,
      transmittedBytes: 30,
    );

    test('device perspective: rx is download', () {
      final reading = NormalizedCounterReading.fromSnapshot(
        snapshot,
        CounterPerspective.device,
      );
      expect(reading.downloadTotal, 700);
      expect(reading.uploadTotal, 30);
    });

    test('gateway perspective: tx towards the device is download', () {
      final reading = NormalizedCounterReading.fromSnapshot(
        snapshot,
        CounterPerspective.gateway,
      );
      expect(reading.downloadTotal, 30);
      expect(reading.uploadTotal, 700);
    });
  });

  group('CounterDeltaTracker', () {
    test('after a reset the next delta is measured from the new baseline', () {
      final tracker = CounterDeltaTracker();
      List<CounterDeltaResult> ingest(NormalizedCounterReading reading) =>
          tracker.ingest(
            [reading],
            source: 'test',
            reliability: TrafficReliability.measured,
          );

      expect(ingest(_reading(t0, 10000, 1000)).single, isA<CounterBaseline>());
      expect(ingest(_reading(t1, 15000, 1500)).single, isA<CounterUsage>());
      expect(
        ingest(_reading(t1.add(const Duration(minutes: 1)), 200, 20)).single,
        isA<CounterReset>(),
      );
      final after =
          ingest(_reading(t1.add(const Duration(minutes: 2)), 700, 50)).single
              as CounterUsage;
      expect(after.usage.downloadBytes, 500);
      expect(after.usage.uploadBytes, 30);
    });

    test('tracks devices independently; IP-only devices key by IP', () {
      final tracker = CounterDeltaTracker();
      final ipOnly = TrafficDeviceIdentity.tryCreate(ipAddress: '10.0.0.9')!;
      tracker.ingest(
        [_reading(t0, 100, 10), _reading(t0, 5000, 500, identity: ipOnly)],
        source: 'test',
        reliability: TrafficReliability.measured,
      );
      final results = tracker.ingest(
        [_reading(t1, 150, 15), _reading(t1, 5400, 540, identity: ipOnly)],
        source: 'test',
        reliability: TrafficReliability.measured,
      );
      final usages = results.cast<CounterUsage>().map((r) => r.usage).toList();
      expect(usages[0].downloadBytes, 50);
      expect(usages[1].downloadBytes, 400);
      expect(usages[1].identity.macAddress, isNull);
    });
  });

  group('splitAtLocalDayBoundaries', () {
    TrafficUsage usage(DateTime start, DateTime end, int down, int up) =>
        TrafficUsage(
          identity: _phone,
          periodStart: start,
          periodEnd: end,
          downloadBytes: down,
          uploadBytes: up,
          source: 'test',
          reliability: TrafficReliability.measured,
        );

    test('leaves an interval within one local day untouched', () {
      final input = usage(
        DateTime(2026, 9, 24, 10),
        DateTime(2026, 9, 24, 11),
        900,
        90,
      );
      final pieces = splitAtLocalDayBoundaries(input);
      expect(pieces, hasLength(1));
      expect(pieces.single.reliability, TrafficReliability.measured);
    });

    test('an interval ending exactly at local midnight is not split', () {
      final pieces = splitAtLocalDayBoundaries(
        usage(DateTime(2026, 9, 24, 23), DateTime(2026, 9, 25), 10, 1),
      );
      expect(pieces, hasLength(1));
    });

    test('splits at local midnight proportionally, preserving totals', () {
      final pieces = splitAtLocalDayBoundaries(
        usage(
          DateTime(2026, 9, 24, 23, 30),
          DateTime(2026, 9, 25, 0, 30),
          1001,
          3,
        ),
      );

      expect(pieces, hasLength(2));
      expect(pieces[0].periodEnd, DateTime(2026, 9, 25));
      expect(pieces[1].periodStart, DateTime(2026, 9, 25));
      expect(pieces[0].downloadBytes + pieces[1].downloadBytes, 1001);
      expect(pieces[0].uploadBytes + pieces[1].uploadBytes, 3);
      expect(pieces[0].downloadBytes, closeTo(500, 1));
      expect(
        pieces.every((p) => p.reliability == TrafficReliability.estimated),
        isTrue,
      );
    });

    test('a multi-day gap is split into one piece per local day', () {
      final pieces = splitAtLocalDayBoundaries(
        usage(
          DateTime(2026, 9, 22, 12),
          DateTime(2026, 9, 25, 12),
          7200000,
          720,
        ),
      );
      expect(pieces.map((p) => p.periodStart.day), [22, 23, 24, 25]);
      expect(pieces.fold<int>(0, (sum, p) => sum + p.downloadBytes), 7200000);
      expect(pieces.fold<int>(0, (sum, p) => sum + p.uploadBytes), 720);
    });

    test('simulated data stays simulated when split', () {
      final pieces = splitAtLocalDayBoundaries(
        TrafficUsage(
          identity: _phone,
          periodStart: DateTime(2026, 9, 24, 23),
          periodEnd: DateTime(2026, 9, 25, 1),
          downloadBytes: 10,
          uploadBytes: 1,
          source: 'demo',
          reliability: TrafficReliability.simulated,
        ),
      );
      expect(
        pieces.every((p) => p.reliability == TrafficReliability.simulated),
        isTrue,
      );
    });
  });

  group('splitAtLocalHourBoundaries', () {
    TrafficUsage usage(DateTime start, DateTime end, int down, int up) =>
        TrafficUsage(
          identity: _phone,
          periodStart: start,
          periodEnd: end,
          downloadBytes: down,
          uploadBytes: up,
          source: 'test',
          reliability: TrafficReliability.measured,
        );

    test('a sleep gap is spread over the hours it spans, not the first', () {
      // Mac slept 10:30 -> 13:30; the counter delta covers all of it.
      final pieces = splitAtLocalHourBoundaries(
        usage(
          DateTime(2026, 9, 24, 10, 30),
          DateTime(2026, 9, 24, 13, 30),
          3000,
          300,
        ),
      );
      expect(pieces.map((p) => p.periodStart.hour), [10, 11, 12, 13]);
      expect(pieces.map((p) => p.downloadBytes), [500, 1000, 1000, 500]);
      expect(pieces.fold<int>(0, (sum, p) => sum + p.uploadBytes), 300);
      expect(
        pieces.every((p) => p.reliability == TrafficReliability.estimated),
        isTrue,
      );
    });

    test('crossing midnight also lands on the right local day', () {
      final pieces = splitAtLocalHourBoundaries(
        usage(
          DateTime(2026, 9, 24, 23, 30),
          DateTime(2026, 9, 25, 0, 30),
          100,
          0,
        ),
      );
      expect(pieces.map((p) => p.periodStart), [
        DateTime(2026, 9, 24, 23, 30),
        DateTime(2026, 9, 25),
      ]);
    });

    test('a short poll interval crossing an hour stays measured', () {
      final pieces = splitAtLocalHourBoundaries(
        usage(
          DateTime(2026, 9, 24, 10, 59),
          DateTime(2026, 9, 24, 11, 1),
          200,
          20,
        ),
      );
      expect(pieces, hasLength(2));
      expect(pieces.map((p) => p.downloadBytes), [100, 100]);
      expect(
        pieces.every((p) => p.reliability == TrafficReliability.measured),
        isTrue,
      );
    });
  });
}
