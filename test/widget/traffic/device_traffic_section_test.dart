import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/database/app_database.dart'
    show AppDatabase, DevicesCompanion;
import 'package:network_monitor/features/network_scope/presentation/providers/network_scope_providers.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_device_identity.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_reliability.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_sample.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_settings.dart';
import 'package:network_monitor/features/traffic/domain/repositories/traffic_settings_repository.dart';
import 'package:network_monitor/features/traffic/infrastructure/drift_traffic_sample_repository.dart';
import 'package:network_monitor/features/traffic/presentation/providers/traffic_providers.dart';
import 'package:network_monitor/features/traffic/presentation/widgets/device_traffic_section.dart';

class _MemorySettingsRepository implements TrafficSettingsRepository {
  _MemorySettingsRepository(this.settings);

  TrafficSettings settings;

  @override
  Future<TrafficSettings> load() async => settings;

  @override
  Future<void> save(TrafficSettings settings) async => this.settings = settings;
}

final _now = DateTime(2026, 9, 24, 15, 20);

Future<int> _insertDevice(AppDatabase db) async {
  final networkId = await db.upsertActiveNetwork(
    interfaceName: 'en0',
    displayName: 'Wi-Fi',
    cidr: '192.168.1.0/24',
    observedAt: _now,
  );
  return db
      .into(db.devices)
      .insert(
        DevicesCompanion.insert(
          networkId: networkId,
          macAddress: const Value('aa:bb:cc:00:00:01'),
          currentIp: '192.168.1.10',
          inferredType: 'unknown',
          confidence: 'unknown',
          firstSeenAt: _now,
          lastSeenAt: _now,
          status: 'online',
        ),
      );
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<void> pumpSection(
    WidgetTester tester, {
    required int deviceId,
    required TrafficSettings settings,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          // No real network detection in tests.
          currentNetworkLookupProvider.overrideWithValue(() async => null),
          trafficSettingsRepositoryProvider.overrideWithValue(
            _MemorySettingsRepository(settings),
          ),
          trafficClockProvider.overrideWithValue(() => _now),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeviceTrafficSection(deviceId: deviceId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('without a traffic provider explains why instead of 0 MB', (
    tester,
  ) async {
    await pumpSection(tester, deviceId: 1, settings: const TrafficSettings());

    expect(find.text(DeviceTrafficSection.unavailableMessage), findsOneWidget);
    expect(find.text('Trafik entegrasyonunu kur'), findsOneWidget);
    expect(find.textContaining('MB'), findsNothing);
    expect(find.textContaining(' B'), findsNothing);
  });

  testWidgets('provider configured but no samples yet: no zero values', (
    tester,
  ) async {
    final deviceId = await tester.runAsync(() => _insertDevice(db));
    await pumpSection(
      tester,
      deviceId: deviceId!,
      settings: const TrafficSettings(providerId: 'demo'),
    );

    expect(find.textContaining('henüz trafik örneği'), findsOneWidget);
    expect(find.textContaining('MB'), findsNothing);
    expect(find.text('DEMO'), findsOneWidget);
  });

  testWidgets('shows today totals, both charts and the demo label', (
    tester,
  ) async {
    final deviceId = (await tester.runAsync(() async {
      final id = await _insertDevice(db);
      final identity = TrafficDeviceIdentity.tryCreate(
        macAddress: 'aa:bb:cc:00:00:01',
        ipAddress: '192.168.1.10',
      )!;
      TrafficSample sample(DateTime start, int down, int up) => TrafficSample(
        deviceId: id,
        identity: identity,
        periodStart: start,
        periodEnd: start.add(const Duration(hours: 1)),
        downloadBytes: down,
        uploadBytes: up,
        source: 'demo',
        reliability: TrafficReliability.simulated,
      );
      await DriftTrafficSampleRepository(db).insertSamples([
        sample(DateTime(2026, 9, 24, 9), 1000000000, 200000000),
        sample(DateTime(2026, 9, 24, 14), 500000000, 50000000),
        sample(DateTime(2026, 9, 22, 20), 300000000, 30000000),
      ]);
      return id;
    }))!;

    await pumpSection(
      tester,
      deviceId: deviceId,
      settings: const TrafficSettings(providerId: 'demo'),
    );

    Finder today(String text) => find.descendant(
      of: find.byKey(const ValueKey('traffic-today-totals')),
      matching: find.text(text),
    );
    expect(today('İndirme'), findsOneWidget);
    expect(today('1,5 GB'), findsOneWidget);
    expect(today('250 MB'), findsOneWidget);
    expect(today('1,8 GB'), findsOneWidget);
    expect(find.byKey(const ValueKey('traffic-hourly-chart')), findsOneWidget);
    expect(find.byKey(const ValueKey('traffic-daily-chart')), findsOneWidget);
    expect(find.text('DEMO'), findsOneWidget);
    expect(find.textContaining('gerçek kullanım değildir'), findsOneWidget);
    expect(find.text(DeviceTrafficSection.unavailableMessage), findsNothing);
  });

  testWidgets('an unknown provider id is treated as not configured', (
    tester,
  ) async {
    await pumpSection(
      tester,
      deviceId: 1,
      settings: const TrafficSettings(providerId: 'unknown-adapter'),
    );
    expect(find.text(DeviceTrafficSection.unavailableMessage), findsOneWidget);
  });
}
