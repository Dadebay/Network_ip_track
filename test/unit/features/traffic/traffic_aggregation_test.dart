import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/traffic/application/build_device_traffic_summary.dart';
import 'package:network_monitor/features/traffic/application/local_time_buckets.dart';
import 'package:network_monitor/features/traffic/application/traffic_aggregation.dart';
import 'package:network_monitor/features/traffic/domain/entities/device_traffic_summary.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_device_identity.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_reliability.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_sample.dart';

final _laptop = TrafficDeviceIdentity.tryCreate(
  macAddress: 'aa:bb:cc:00:00:01',
  ipAddress: '192.168.1.10',
)!;

TrafficSample _sample(
  DateTime start,
  Duration length,
  int down,
  int up, {
  int deviceId = 1,
  TrafficDeviceIdentity? identity,
  TrafficReliability reliability = TrafficReliability.measured,
}) => TrafficSample(
  deviceId: deviceId,
  identity: identity ?? _laptop,
  periodStart: start,
  periodEnd: start.add(length),
  downloadBytes: down,
  uploadBytes: up,
  source: 'test',
  reliability: reliability,
);

void main() {
  const minute = Duration(minutes: 1);

  group('local time buckets', () {
    test('day and hour starts follow local time', () {
      final t = DateTime(2026, 9, 24, 14, 37, 12, 5);
      expect(startOfLocalDay(t), DateTime(2026, 9, 24));
      expect(startOfNextLocalDay(t), DateTime(2026, 9, 25));
      expect(startOfLocalHour(t), DateTime(2026, 9, 24, 14));
    });

    test('a UTC instant is bucketed by its local day', () {
      final local = DateTime(2026, 9, 24, 0, 15);
      expect(startOfLocalDay(local.toUtc()), DateTime(2026, 9, 24));
    });

    test('next local day crosses month and year ends', () {
      expect(startOfNextLocalDay(DateTime(2026, 12, 31, 22)), DateTime(2027));
    });
  });

  group('rollUpSamples', () {
    test('sums raw samples into local-hour rows', () {
      final rows = rollUpSamples([
        _sample(DateTime(2026, 9, 24, 10, 0), minute, 100, 10),
        _sample(DateTime(2026, 9, 24, 10, 1), minute, 200, 20),
        _sample(DateTime(2026, 9, 24, 11, 5), minute, 50, 5),
      ], TrafficBucketSize.hour);

      expect(rows, hasLength(2));
      expect(rows[0].periodStart, DateTime(2026, 9, 24, 10));
      expect(rows[0].periodEnd, DateTime(2026, 9, 24, 11));
      expect(rows[0].downloadBytes, 300);
      expect(rows[0].uploadBytes, 30);
      expect(rows[1].downloadBytes, 50);
    });

    test('sums into local-day rows and keeps the worst reliability', () {
      final rows = rollUpSamples([
        _sample(DateTime(2026, 9, 24, 1), const Duration(hours: 1), 1, 1),
        _sample(
          DateTime(2026, 9, 24, 23),
          const Duration(hours: 1),
          2,
          2,
          reliability: TrafficReliability.estimated,
        ),
      ], TrafficBucketSize.day);

      expect(rows.single.periodStart, DateTime(2026, 9, 24));
      expect(rows.single.periodEnd, DateTime(2026, 9, 25));
      expect(rows.single.totalBytes, 6);
      expect(rows.single.reliability, TrafficReliability.estimated);
    });

    test('keeps devices and MAC-IP bindings apart', () {
      final newIp = TrafficDeviceIdentity.tryCreate(
        macAddress: 'aa:bb:cc:00:00:01',
        ipAddress: '192.168.1.99',
      )!;
      final rows = rollUpSamples([
        _sample(DateTime(2026, 9, 24, 10), minute, 1, 0),
        _sample(DateTime(2026, 9, 24, 10, 1), minute, 1, 0, identity: newIp),
        _sample(DateTime(2026, 9, 24, 10, 2), minute, 1, 0, deviceId: 2),
      ], TrafficBucketSize.hour);

      expect(rows, hasLength(3));
      expect(rows.map((r) => r.identity.ipAddress).toSet(), {
        '192.168.1.10',
        '192.168.1.99',
      });
    });
  });

  group('buildDeviceTrafficSummary', () {
    final now = DateTime(2026, 9, 24, 15, 20);

    test('with no samples everything is marked as having no data', () {
      final summary = buildDeviceTrafficSummary(samples: const [], now: now);
      expect(summary.hasAnyData, isFalse);
      expect(summary.hasTodayData, isFalse);
      expect(summary.hourly, hasLength(24));
      expect(summary.daily, hasLength(7));
      expect(summary.worstReliability, isNull);
    });

    test('computes today, last 24 hours and last 7 days', () {
      final summary = buildDeviceTrafficSummary(
        now: now,
        samples: [
          // Today.
          _sample(DateTime(2026, 9, 24, 15, 0), minute, 1000, 100),
          _sample(DateTime(2026, 9, 24, 9, 0), minute, 2000, 200),
          // Yesterday, still within the last 24 hours.
          _sample(DateTime(2026, 9, 23, 18, 0), minute, 400, 40),
          // Yesterday, older than 24 hours.
          _sample(DateTime(2026, 9, 23, 8, 0), minute, 300, 30),
          // A rolled-up day row six days ago.
          _sample(DateTime(2026, 9, 18), const Duration(days: 1), 7000, 700),
          // Older than 7 days: ignored.
          _sample(DateTime(2026, 9, 17, 12), minute, 99999, 9999),
        ],
      );

      expect(
        summary.today,
        const TrafficTotals(downloadBytes: 3000, uploadBytes: 300),
      );
      expect(summary.today.totalBytes, 3300);

      expect(summary.hourly.first.start, DateTime(2026, 9, 23, 16));
      expect(summary.hourly.last.start, DateTime(2026, 9, 24, 15));
      expect(summary.hourly.last.totals.downloadBytes, 1000);
      final hourlyTotal = summary.hourly.fold<int>(
        0,
        (sum, b) => sum + b.totals.totalBytes,
      );
      expect(hourlyTotal, 1100 + 2200 + 440);

      expect(summary.daily.first.start, DateTime(2026, 9, 18));
      expect(summary.daily.first.totals.downloadBytes, 7000);
      expect(summary.daily[5].totals.downloadBytes, 700); // Yesterday.
      expect(summary.daily[5].hasData, isTrue);
      expect(summary.daily[3].hasData, isFalse);
    });

    test('a sample just after local midnight counts for the new day', () {
      final summary = buildDeviceTrafficSummary(
        now: DateTime(2026, 9, 24, 0, 5),
        samples: [
          _sample(DateTime(2026, 9, 23, 23, 59), minute, 10, 0),
          _sample(DateTime(2026, 9, 24, 0, 0), minute, 20, 0),
        ],
      );
      expect(summary.today.downloadBytes, 20);
      expect(summary.daily[5].totals.downloadBytes, 10);
    });

    test('flags simulated data', () {
      final summary = buildDeviceTrafficSummary(
        now: now,
        samples: [
          _sample(
            DateTime(2026, 9, 24, 12),
            minute,
            1,
            1,
            reliability: TrafficReliability.simulated,
          ),
        ],
      );
      expect(summary.containsSimulatedData, isTrue);
    });
  });
}
