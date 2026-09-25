import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/database/app_database.dart'
    show AppDatabase, DevicesCompanion;
import 'package:network_monitor/features/traffic/domain/entities/traffic_device_identity.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_reliability.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_retention_policy.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_sample.dart';
import 'package:network_monitor/features/traffic/infrastructure/drift_traffic_device_resolver.dart';
import 'package:network_monitor/features/traffic/infrastructure/drift_traffic_sample_repository.dart';
import 'package:network_monitor/features/traffic/infrastructure/traffic_sample_row_codec.dart';

final _identity = TrafficDeviceIdentity.tryCreate(
  macAddress: 'aa:bb:cc:00:00:01',
  ipAddress: '192.168.1.10',
)!;

Future<int> _insertDevice(
  AppDatabase db, {
  String? mac = 'aa:bb:cc:00:00:01',
  String ip = '192.168.1.10',
}) async {
  final now = DateTime(2026, 9, 1);
  final networkId = await db.upsertActiveNetwork(
    interfaceName: 'en0',
    displayName: 'Wi-Fi',
    cidr: '192.168.1.0/24',
    observedAt: now,
  );
  return db
      .into(db.devices)
      .insert(
        DevicesCompanion.insert(
          networkId: networkId,
          macAddress: Value(mac),
          currentIp: ip,
          inferredType: 'unknown',
          confidence: 'unknown',
          firstSeenAt: now,
          lastSeenAt: now,
          status: 'online',
        ),
      );
}

TrafficSample _sample(
  int deviceId,
  DateTime start,
  Duration length,
  int down, {
  String source = 'test',
}) => TrafficSample(
  deviceId: deviceId,
  identity: _identity,
  periodStart: start,
  periodEnd: start.add(length),
  downloadBytes: down,
  uploadBytes: down ~/ 10,
  source: source,
  reliability: TrafficReliability.measured,
);

void main() {
  late AppDatabase db;
  late DriftTrafficSampleRepository repository;
  late int deviceId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repository = DriftTrafficSampleRepository(db);
    deviceId = await _insertDevice(db);
  });

  tearDown(() => db.close());

  test('round-trips samples including the MAC-IP binding', () async {
    final start = DateTime(2026, 9, 24, 10);
    await repository.insertSamples([
      _sample(deviceId, start, const Duration(minutes: 1), 5000),
    ]);

    final rows = await repository.samplesForDevice(
      deviceId,
      from: DateTime(2026, 9, 24),
      to: DateTime(2026, 9, 25),
    );
    expect(rows.single.downloadBytes, 5000);
    expect(rows.single.uploadBytes, 500);
    expect(rows.single.periodStart, start);
    expect(rows.single.identity, _identity);
    expect(rows.single.reliability, TrafficReliability.measured);
  });

  test(
    'applyRetention rolls up raw -> hour -> day and deletes old rows',
    () async {
      final now = DateTime(2026, 9, 24, 12);
      const minute = Duration(minutes: 1);
      await repository.insertSamples([
        // Recent raw rows (< 48h): untouched.
        _sample(deviceId, DateTime(2026, 9, 24, 11, 0), minute, 1),
        _sample(deviceId, DateTime(2026, 9, 24, 11, 1), minute, 2),
        // 3 days old: raw -> one hour row.
        _sample(deviceId, DateTime(2026, 9, 21, 10, 0), minute, 10),
        _sample(deviceId, DateTime(2026, 9, 21, 10, 30), minute, 20),
        // 10 days old: raw -> one day row.
        _sample(deviceId, DateTime(2026, 9, 14, 3), minute, 100),
        _sample(deviceId, DateTime(2026, 9, 14, 21), minute, 200),
        // 100 days old: deleted.
        _sample(deviceId, DateTime(2026, 6, 10, 12), minute, 9999),
      ]);

      final report = await repository.applyRetention(
        now: now,
        policy: const TrafficRetentionPolicy(),
      );
      expect(report.deleted, 1);
      expect(report.rolledUpToDaily, 2);
      expect(report.rolledUpToHourly, 2);

      final rows = await repository.samplesForDevice(
        deviceId,
        from: DateTime(2026, 1, 1),
        to: DateTime(2027, 1, 1),
      );
      expect(rows, hasLength(4));
      final day = rows[0];
      expect(day.periodStart, DateTime(2026, 9, 14));
      expect(day.periodEnd, DateTime(2026, 9, 15));
      expect(day.downloadBytes, 300);
      final hour = rows[1];
      expect(hour.periodStart, DateTime(2026, 9, 21, 10));
      expect(hour.periodEnd, DateTime(2026, 9, 21, 11));
      expect(hour.downloadBytes, 30);
      expect(hour.identity, _identity);

      // Idempotent: a second run changes nothing.
      final again = await repository.applyRetention(
        now: now,
        policy: const TrafficRetentionPolicy(),
      );
      expect(again.rolledUpToHourly + again.rolledUpToDaily + again.deleted, 0);
    },
  );

  test('deleteBySource removes only that source', () async {
    final start = DateTime(2026, 9, 24, 10);
    await repository.insertSamples([
      _sample(deviceId, start, const Duration(minutes: 1), 1, source: 'demo'),
      _sample(deviceId, start, const Duration(minutes: 1), 2),
    ]);

    expect(await repository.deleteBySource('demo'), 1);
    final rows = await repository.samplesForDevice(
      deviceId,
      from: DateTime(2026, 9, 24),
      to: DateTime(2026, 9, 25),
    );
    expect(rows.single.source, 'test');
  });

  test(
    'totalsByDevice sums a local day per device and omits devices without samples',
    () async {
      final otherId = await _insertDevice(db, mac: null, ip: '192.168.1.99');
      final start = DateTime(2026, 9, 24, 10);
      await repository.insertSamples([
        _sample(deviceId, start, const Duration(minutes: 1), 1),
        _sample(
          deviceId,
          start.add(const Duration(hours: 1)),
          const Duration(minutes: 1),
          2,
        ),
        // Yesterday: excluded.
        _sample(
          deviceId,
          DateTime(2026, 9, 23, 10),
          const Duration(minutes: 1),
          50,
        ),
      ]);

      final totals = await repository.totalsByDevice(
        from: DateTime(2026, 9, 24),
        to: DateTime(2026, 9, 25),
      );
      final expected = [
        _sample(deviceId, start, const Duration(minutes: 1), 1),
        _sample(deviceId, start, const Duration(minutes: 1), 2),
      ];
      expect(totals.keys, [deviceId]);
      expect(
        totals[deviceId]!.downloadBytes,
        expected.fold<int>(0, (sum, s) => sum + s.downloadBytes),
      );
      expect(
        totals[deviceId]!.uploadBytes,
        expected.fold<int>(0, (sum, s) => sum + s.uploadBytes),
      );
      expect(totals.containsKey(otherId), isFalse);
    },
  );

  test('stores the MAC/IP binding in its own columns', () async {
    await repository.insertSamples([
      _sample(
        deviceId,
        DateTime(2026, 9, 24, 10),
        const Duration(minutes: 1),
        1,
      ),
    ]);
    final row = await db.select(db.trafficSamples).getSingle();
    expect(row.reliability, isNot(contains('{')));
    final stored = await repository.samplesForDevice(
      deviceId,
      from: DateTime(2026, 9, 24),
      to: DateTime(2026, 9, 25),
    );
    expect(stored.single.identity.macAddress, row.macAddress);
    expect(stored.single.identity.ipAddress, row.ipAddress);
  });

  group('TrafficSampleRowCodec', () {
    test('decodes a bare reliability value without a binding', () {
      final (reliability, identity) = TrafficSampleRowCodec.decode('measured');
      expect(reliability, TrafficReliability.measured);
      expect(identity, isNull);
    });
  });

  group('DriftTrafficDeviceResolver', () {
    test('matches by MAC, and by IP only when unambiguous', () async {
      final resolver = DriftTrafficDeviceResolver(
        db,
        activeNetworkId: () =>
            db.findNetworkId(interfaceName: 'en0', cidr: '192.168.1.0/24'),
      );
      final ipOnlyId = await _insertDevice(db, mac: null, ip: '192.168.1.50');
      await _insertDevice(db, mac: null, ip: '192.168.1.60');
      await _insertDevice(db, mac: null, ip: '192.168.1.60');

      final byMac = _identity;
      final byIp = TrafficDeviceIdentity.tryCreate(ipAddress: '192.168.1.50')!;
      final ambiguous = TrafficDeviceIdentity.tryCreate(
        ipAddress: '192.168.1.60',
      )!;
      final unknown = TrafficDeviceIdentity.tryCreate(
        macAddress: 'ff:ff:ff:00:00:00',
      )!;

      final resolved = await resolver.resolveDeviceIds([
        byMac,
        byIp,
        ambiguous,
        unknown,
      ]);
      expect(resolved, {byMac.counterKey: deviceId, byIp.counterKey: ipOnlyId});
    });
  });

  group('DriftTrafficDeviceResolver network scoping', () {
    Future<(int, int)> twoNetworksWithSameMac() async {
      Future<int> deviceOn(String cidr, String ip) async {
        final networkId = await db.upsertActiveNetwork(
          interfaceName: 'en0',
          displayName: 'Wi-Fi',
          cidr: cidr,
          observedAt: DateTime(2026, 9, 1),
        );
        return db
            .into(db.devices)
            .insert(
              DevicesCompanion.insert(
                networkId: networkId,
                macAddress: const Value('aa:bb:cc:00:00:99'),
                currentIp: ip,
                inferredType: 'unknown',
                confidence: 'unknown',
                firstSeenAt: DateTime(2026, 9, 1),
                // The office copy was seen more recently.
                lastSeenAt: cidr.startsWith('10.')
                    ? DateTime(2026, 9, 20)
                    : DateTime(2026, 9, 2),
                status: 'online',
              ),
            );
      }

      final home = await deviceOn('192.168.1.0/24', '192.168.1.99');
      final office = await deviceOn('10.0.0.0/24', '10.0.0.99');
      return (home, office);
    }

    final laptop = TrafficDeviceIdentity.tryCreate(
      macAddress: 'aa:bb:cc:00:00:99',
    )!;

    test(
      'same MAC on two networks: usage goes only to the active one',
      () async {
        final (home, office) = await twoNetworksWithSameMac();
        final homeNetwork = await db.findNetworkId(
          interfaceName: 'en0',
          cidr: '192.168.1.0/24',
        );
        final resolver = DriftTrafficDeviceResolver(
          db,
          activeNetworkId: () async => homeNetwork,
        );
        expect(await resolver.resolveDeviceIds([laptop]), {
          laptop.counterKey: home,
        });
        expect(home, isNot(office));
        expect(
          (await resolver.knownIdentities()).map((i) => i.ipAddress),
          isNot(contains('10.0.0.99')),
        );
      },
    );

    test('no active network: nothing is attributed', () async {
      await twoNetworksWithSameMac();
      final resolver = DriftTrafficDeviceResolver(
        db,
        activeNetworkId: () async => null,
      );
      expect(await resolver.resolveDeviceIds([laptop]), isEmpty);
      expect(await resolver.knownIdentities(), isEmpty);
    });
  });
}
