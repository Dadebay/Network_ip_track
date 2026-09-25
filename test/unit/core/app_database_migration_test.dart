import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/database/app_database.dart';

void main() {
  test('v1 -> v3: traffic MAC/IP binding moves to columns, index is added, '
      'devices gain classification/user columns', () async {
    final database = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          // The v1 tables the migration touches.
          raw.execute('''
            CREATE TABLE devices (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              network_id INTEGER NOT NULL,
              mac_address TEXT NULL,
              current_ip TEXT NOT NULL,
              hostname TEXT NULL,
              vendor TEXT NULL,
              inferred_type TEXT NOT NULL,
              inferred_os TEXT NULL,
              confidence TEXT NOT NULL,
              custom_name TEXT NULL,
              custom_type TEXT NULL,
              note TEXT NULL,
              is_gateway INTEGER NOT NULL DEFAULT 0,
              is_local_device INTEGER NOT NULL DEFAULT 0,
              first_seen_at INTEGER NOT NULL,
              last_seen_at INTEGER NOT NULL,
              status TEXT NOT NULL
            )
          ''');
          raw.execute('''
            INSERT INTO devices (network_id, current_ip, inferred_type,
              confidence, custom_type, first_seen_at, last_seen_at, status)
            VALUES
              (1, '172.16.14.12', 'unknown', 'unknown', 'printer', 0, 0,
               'online'),
              (1, '172.16.14.13', 'unknown', 'unknown', 'Benim yazıcım', 0, 0,
               'online')
          ''');
          // Present since v1; empty here since this test's own assertions
          // don't need rows in it. The v3 -> v4 step (pingConfirmed
          // backfill) queries it, so it must exist.
          raw.execute('''
            CREATE TABLE device_observations (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              device_id INTEGER NOT NULL,
              observed_at INTEGER NOT NULL,
              ip_address TEXT NOT NULL,
              hostname TEXT NULL,
              services_json TEXT NOT NULL DEFAULT '[]',
              signals_json TEXT NOT NULL DEFAULT '[]'
            )
          ''');
          raw.execute('''
            CREATE TABLE traffic_samples (
              id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
              device_id INTEGER NOT NULL,
              source TEXT NOT NULL,
              period_start INTEGER NOT NULL,
              period_end INTEGER NOT NULL,
              download_bytes INTEGER NOT NULL,
              upload_bytes INTEGER NOT NULL,
              reliability TEXT NOT NULL
            )
          ''');
          raw.execute('''
            INSERT INTO traffic_samples
              (device_id, source, period_start, period_end, download_bytes,
               upload_bytes, reliability)
            VALUES
              (1, 'demo', 0, 60, 10, 20,
               '{"level":"measured","mac":"aa:bb:cc:dd:ee:ff","ip":"172.16.14.12"}'),
              (1, 'demo', 60, 120, 1, 2, 'estimated')
          ''');
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(database.close);

    final samples = await database.select(database.trafficSamples).get();
    expect(samples[0].reliability, 'measured');
    expect(samples[0].macAddress, 'aa:bb:cc:dd:ee:ff');
    expect(samples[0].ipAddress, '172.16.14.12');
    expect(samples[1].reliability, 'estimated');
    expect(samples[1].macAddress, isNull);

    final indexes = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND tbl_name = 'traffic_samples'",
        )
        .get();
    expect(
      indexes.map((row) => row.read<String>('name')),
      contains('traffic_samples_device_period'),
    );

    final devices = await database.select(database.devices).get();
    expect(devices[0].customDeviceType, 'printer');
    // Free text isn't a DeviceType: dropped rather than guessed.
    expect(devices[1].customDeviceType, isNull);
    expect(devices[0].isKnown, isFalse);
    expect(devices[0].inferenceReasonsJson, '[]');
    expect(devices[0].osConfidence, isNull);
    // v3 -> v4: no observation ever recorded an ICMP reply for either
    // device, so the backfill leaves pingConfirmed at its default.
    expect(devices[0].pingConfirmed, isFalse);
    expect(devices[1].pingConfirmed, isFalse);
  });
}
