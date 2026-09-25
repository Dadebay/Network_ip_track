import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/database/app_database.dart';
import 'package:network_monitor/features/traffic/application/traffic_usage_collector.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_connection_test_result.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_counter_snapshot.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_device_identity.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_provider_descriptor.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_reliability.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_usage_batch.dart';
import 'package:network_monitor/features/traffic/domain/repositories/traffic_provider.dart';
import 'package:network_monitor/features/traffic/infrastructure/drift_traffic_device_resolver.dart';
import 'package:network_monitor/features/traffic/infrastructure/drift_traffic_sample_repository.dart';
import 'package:network_monitor/features/traffic/infrastructure/file_usage_cursor_store.dart';

/// Serves a fixed set of records, filtered by the cursor like a real source.
class _FixedUsageProvider extends UsageTrafficProvider {
  _FixedUsageProvider(this.all);

  final List<ProviderUsageRecord> all;
  final List<UsageCursor> readsFrom = [];

  @override
  TrafficProviderDescriptor get descriptor => const TrafficProviderDescriptor(
    id: 'fixed',
    displayName: 'Fixed',
    description: '',
    perspective: CounterPerspective.device,
  );

  @override
  Future<TrafficConnectionTestResult> testConnection() async =>
      TrafficConnectionTestResult.success(
        checkedAt: DateTime(2026),
        message: '',
      );

  @override
  Future<TrafficUsageBatch> readUsage({required UsageCursor after}) async {
    readsFrom.add(after);
    final fresh = all.where(after.isNew).toList();
    return TrafficUsageBatch(records: fresh, next: after.advancedPast(fresh));
  }
}

void main() {
  late AppDatabase db;
  late Directory directory;
  late int homeNetwork;
  late int homeLaptop;
  late int officeLaptop;

  const mac = 'aa:bb:cc:00:00:99';

  Future<int> device(int networkId, String ip) => db
      .into(db.devices)
      .insert(
        DevicesCompanion.insert(
          networkId: networkId,
          macAddress: const Value(mac),
          currentIp: ip,
          inferredType: 'unknown',
          confidence: 'unknown',
          firstSeenAt: DateTime(2026, 9, 1),
          lastSeenAt: DateTime(2026, 9, 1),
          status: 'online',
        ),
      );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    directory = await Directory.systemTemp.createTemp('usage_cursor_test');
    homeNetwork = await db.upsertActiveNetwork(
      interfaceName: 'en0',
      displayName: 'Wi-Fi',
      cidr: '172.16.14.0/24',
      observedAt: DateTime(2026, 9, 1),
    );
    final office = await db.upsertActiveNetwork(
      interfaceName: 'en0',
      displayName: 'Wi-Fi',
      cidr: '10.0.0.0/24',
      observedAt: DateTime(2026, 9, 1),
    );
    homeLaptop = await device(homeNetwork, '172.16.14.99');
    officeLaptop = await device(office, '10.0.0.99');
  });

  tearDown(() async {
    await db.close();
    await directory.delete(recursive: true);
  });

  TrafficUsageCollector collector(_FixedUsageProvider provider) =>
      TrafficUsageCollector(
        provider: provider,
        resolver: DriftTrafficDeviceResolver(
          db,
          activeNetworkId: () async => homeNetwork,
        ),
        repository: DriftTrafficSampleRepository(db),
        // A fresh store instance each time: cursors must come from disk.
        cursors: FileUsageCursorStore(directory: () async => directory),
        clock: () => DateTime(2026, 9, 25, 12),
      );

  final session = ProviderUsageRecord(
    key: 's1',
    identity: TrafficDeviceIdentity.tryCreate(macAddress: mac)!,
    // A 30-minute session crossing 11:00.
    periodStart: DateTime(2026, 9, 25, 10, 45),
    periodEnd: DateTime(2026, 9, 25, 11, 15),
    downloadBytes: 3000,
    uploadBytes: 300,
  );

  test('stores hour-split usage on the active network only, once', () async {
    final provider = _FixedUsageProvider([session]);
    final report = await collector(provider).pollOnce();
    expect(report.readings, 1);
    expect(report.samplesWritten, 2);

    final rows = await (db.select(
      db.trafficSamples,
    )..orderBy([(r) => OrderingTerm.asc(r.periodStart)])).get();
    expect(rows.map((r) => r.deviceId).toSet(), {homeLaptop});
    expect(rows.map((r) => r.periodStart.hour), [10, 11]);
    expect(rows.map((r) => r.downloadBytes), [1500, 1500]);
    expect(rows.fold<int>(0, (sum, r) => sum + r.uploadBytes), 300);
    expect(rows.first.reliability, TrafficReliability.estimated.name);
    expect(rows.map((r) => r.deviceId), isNot(contains(officeLaptop)));

    // Next poll (new collector, as after an app restart): nothing new.
    final second = await collector(provider).pollOnce();
    expect(second.readings, 0);
    expect(await db.select(db.trafficSamples).get(), hasLength(2));
    expect(provider.readsFrom.last.endedAfter, session.periodEnd);
  });

  test('the first poll looks back 24 hours', () async {
    final provider = _FixedUsageProvider([]);
    await collector(provider).pollOnce();
    expect(provider.readsFrom.single.endedAfter, DateTime(2026, 9, 24, 12));
  });
}
