import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/database/app_database.dart'
    show AppDatabase, DevicesCompanion;
import 'package:network_monitor/features/traffic/application/build_device_traffic_summary.dart';
import 'package:network_monitor/features/traffic/application/traffic_collector.dart';
import 'package:network_monitor/features/traffic/domain/entities/device_traffic_summary.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_connection_test_result.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_counter_snapshot.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_device_identity.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_provider_descriptor.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_reliability.dart';
import 'package:network_monitor/features/traffic/domain/failures/traffic_failures.dart';
import 'package:network_monitor/features/traffic/domain/repositories/traffic_provider.dart';
import 'package:network_monitor/features/traffic/infrastructure/demo/demo_traffic_provider.dart';
import 'package:network_monitor/features/traffic/infrastructure/drift_traffic_device_resolver.dart';
import 'package:network_monitor/features/traffic/infrastructure/drift_traffic_sample_repository.dart';

final _identity = TrafficDeviceIdentity.tryCreate(
  macAddress: 'aa:bb:cc:00:00:01',
  ipAddress: '192.168.1.10',
)!;

/// Replays scripted cumulative counters, one batch per poll.
class _ScriptedProvider implements CounterTrafficProvider {
  _ScriptedProvider(
    this._batches, {
    this.perspective = CounterPerspective.device,
  });

  final List<List<TrafficCounterSnapshot>> _batches;
  final CounterPerspective perspective;
  var _next = 0;

  @override
  TrafficProviderDescriptor get descriptor => TrafficProviderDescriptor(
    id: 'scripted',
    displayName: 'Scripted',
    description: 'test',
    perspective: perspective,
  );

  @override
  Future<TrafficConnectionTestResult> testConnection() async =>
      TrafficConnectionTestResult.failure(
        checkedAt: DateTime(2026),
        failure: TrafficProviderAuthFailure(),
      );

  @override
  Future<List<TrafficCounterSnapshot>> readCounters() async =>
      _batches[_next++];
}

TrafficCounterSnapshot _counter(DateTime at, int rx, int tx) =>
    TrafficCounterSnapshot(
      identity: _identity,
      readAt: at,
      receivedBytes: rx,
      transmittedBytes: tx,
    );

void main() {
  late AppDatabase db;
  late DriftTrafficSampleRepository repository;
  late DriftTrafficDeviceResolver resolver;
  late int deviceId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftTrafficSampleRepository(db);
    final seenAt = DateTime(2026, 9, 1);
    final networkId = await db.upsertActiveNetwork(
      interfaceName: 'en0',
      displayName: 'Wi-Fi',
      cidr: '192.168.1.0/24',
      observedAt: seenAt,
    );
    resolver = DriftTrafficDeviceResolver(
      db,
      activeNetworkId: () async => networkId,
    );
    deviceId = await db
        .into(db.devices)
        .insert(
          DevicesCompanion.insert(
            networkId: networkId,
            macAddress: const Value('aa:bb:cc:00:00:01'),
            currentIp: '192.168.1.10',
            inferredType: 'unknown',
            confidence: 'unknown',
            firstSeenAt: seenAt,
            lastSeenAt: seenAt,
            status: 'online',
          ),
        );
  });

  tearDown(() => db.close());

  Future<DeviceTrafficSummary> summaryAt(DateTime now) async {
    final samples = await repository.samplesForDevice(
      deviceId,
      from: trafficSummaryRangeStart(now),
      to: DateTime(2027),
    );
    return buildDeviceTrafficSummary(samples: samples, now: now);
  }

  test('mock provider: daily download/upload/total across a reset and '
      'local midnight', () async {
    final provider = _ScriptedProvider(
      [
        [_counter(DateTime(2026, 9, 23, 23, 0), 1000, 100)],
        // 23:00 -> 01:00 crosses midnight: 2000/200 split evenly.
        [_counter(DateTime(2026, 9, 24, 1, 0), 3000, 300)],
        [_counter(DateTime(2026, 9, 24, 2, 0), 8000, 800)],
        // Router rebooted: counters restarted; not counted.
        [_counter(DateTime(2026, 9, 24, 3, 0), 500, 50)],
        [_counter(DateTime(2026, 9, 24, 4, 0), 1500, 150)],
      ],
      // Router-port perspective: tx is what the device downloaded.
      perspective: CounterPerspective.gateway,
    );
    final collector = TrafficCollector(
      provider: provider,
      resolver: resolver,
      repository: repository,
    );

    final reports = [for (var i = 0; i < 5; i++) await collector.pollOnce()];
    expect(reports.map((r) => r.baselines), [1, 0, 0, 0, 0]);
    expect(reports.map((r) => r.counterResets), [0, 0, 0, 1, 0]);
    expect(reports[1].samplesWritten, 2); // Split at local midnight.

    final summary = await summaryAt(DateTime(2026, 9, 24, 12));
    // Today: 00:00-01:00 half of first interval (100 down / 1000 up in
    // gateway terms: tx=download), 01-02 (500/5000), 04:00 (100/1000).
    expect(
      summary.today,
      const TrafficTotals(
        downloadBytes: 100 + 500 + 100,
        uploadBytes: 1000 + 5000 + 1000,
      ),
    );
    expect(summary.daily[5].totals.totalBytes, 100 + 1000);
    expect(summary.worstReliability, TrafficReliability.estimated);
  });

  test('usage from unknown devices is dropped, not guessed', () async {
    final stranger = TrafficDeviceIdentity.tryCreate(
      macAddress: 'de:ad:be:ef:00:01',
    )!;
    TrafficCounterSnapshot strangerAt(DateTime at, int v) =>
        TrafficCounterSnapshot(
          identity: stranger,
          readAt: at,
          receivedBytes: v,
          transmittedBytes: v,
        );
    final collector = TrafficCollector(
      provider: _ScriptedProvider([
        [strangerAt(DateTime(2026, 9, 24, 10), 1)],
        [strangerAt(DateTime(2026, 9, 24, 11), 9)],
      ]),
      resolver: resolver,
      repository: repository,
    );
    await collector.pollOnce();
    final report = await collector.pollOnce();
    expect(report.unresolvedDevices, 1);
    expect(report.samplesWritten, 0);
  });

  group('DemoTrafficProvider', () {
    test('counters are monotonic and data is marked simulated', () async {
      final demo = DemoTrafficProvider(loadDevices: () async => [_identity]);
      var previous = demo.countersAt(DateTime(2026, 9, 20), [_identity]).single;
      for (var i = 1; i <= 48; i++) {
        final current = demo.countersAt(DateTime(2026, 9, 20, i), [
          _identity,
        ]).single;
        expect(current.receivedBytes, greaterThan(previous.receivedBytes));
        expect(
          current.transmittedBytes,
          greaterThanOrEqualTo(previous.transmittedBytes),
        );
        previous = current;
      }

      final now = DateTime(2026, 9, 24, 12, 30);
      await backfillDemoHistory(
        provider: demo,
        collector: TrafficCollector(
          provider: demo,
          resolver: resolver,
          repository: repository,
        ),
        devices: [_identity],
        now: now,
      );
      final summary = await summaryAt(now);
      expect(summary.hasTodayData, isTrue);
      expect(summary.daily.every((bucket) => bucket.hasData), isTrue);
      expect(summary.sources, {'demo'});
      expect(summary.containsSimulatedData, isTrue);
    });

    test('connection test says it is demo data', () async {
      final demo = DemoTrafficProvider(loadDevices: () async => [_identity]);
      final result = await demo.testConnection();
      expect(result.isSuccess, isTrue);
      expect(result.deviceCount, 1);
      expect(result.message, contains('Simüle'));
    });
  });
}
