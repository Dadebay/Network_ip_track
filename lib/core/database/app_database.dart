import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/device_observations_table.dart';
import 'tables/devices_table.dart';
import 'tables/networks_table.dart';
import 'tables/scan_sessions_table.dart';
import 'tables/traffic_samples_table.dart';

part 'app_database.g.dart';

/// App-wide SQLite database (via Drift). Byte counters are stored as
/// integers; MB/GB conversion happens only in the presentation layer.
@DriftDatabase(
  tables: [Networks, Devices, DeviceObservations, TrafficSamples, ScanSessions],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // v1 kept the traffic sample's MAC/IP binding as JSON inside
        // `reliability` ({"level":…,"mac":…,"ip":…}); v2 has real columns.
        await migrator.addColumn(trafficSamples, trafficSamples.macAddress);
        await migrator.addColumn(trafficSamples, trafficSamples.ipAddress);
        await customStatement('''
          UPDATE traffic_samples
          SET mac_address = json_extract(reliability, '\$.mac'),
              ip_address = json_extract(reliability, '\$.ip'),
              reliability = COALESCE(
                json_extract(reliability, '\$.level'), 'estimated')
          WHERE json_valid(reliability)
            AND json_type(reliability) = 'object'
        ''');
        await migrator.create(trafficSamplesDevicePeriod);
      }
      if (from < 3) {
        await migrator.addColumn(devices, devices.osConfidence);
        await migrator.addColumn(devices, devices.inferenceReasonsJson);
        await migrator.addColumn(devices, devices.isKnown);
        // v2 stored the user's type as free text; v3 stores a DeviceType
        // name. Earlier builds never wrote this column from the UI, so
        // anything that isn't a known name is dropped rather than guessed.
        await customStatement('''
          UPDATE devices SET custom_type = NULL
          WHERE custom_type IS NOT NULL AND custom_type NOT IN (
            'phone', 'tablet', 'windowsComputer', 'mac',
            'linuxComputerServer', 'routerGateway', 'printer',
            'smartTvMedia', 'iotSmartHome', 'gameConsole', 'unknown')
        ''');
      }
      if (from < 4) {
        await migrator.addColumn(devices, devices.pingConfirmed);
        // Backfill from history: a device some past scan actually pinged
        // shouldn't look unconfirmed just because the column is new.
        await customStatement('''
          UPDATE devices SET ping_confirmed = 1
          WHERE id IN (
            SELECT DISTINCT device_id FROM device_observations
            WHERE signals_json LIKE '%ICMP yanıtı%'
          )
        ''');
      }
    },
  );

  /// Inserts the active network on first sight, or refreshes its metadata
  /// and `last_seen_at` on subsequent detections. Returns the network's id.
  ///
  /// A network is identified by interface *and* CIDR: the same `en0` joining
  /// a different Wi-Fi is a different network, and its devices must not be
  /// merged with the previous one's.
  Future<int> upsertActiveNetwork({
    required String interfaceName,
    required String displayName,
    required String cidr,
    required DateTime observedAt,
    String? gatewayIp,
  }) async {
    final existing =
        await (select(networks)..where(
              (row) =>
                  row.interfaceName.equals(interfaceName) &
                  row.cidr.equals(cidr),
            ))
            .getSingleOrNull();

    if (existing == null) {
      return into(networks).insert(
        NetworksCompanion.insert(
          interfaceName: interfaceName,
          displayName: displayName,
          cidr: cidr,
          gatewayIp: Value(gatewayIp),
          firstSeenAt: observedAt,
          lastSeenAt: observedAt,
        ),
      );
    }

    await (update(networks)..where((row) => row.id.equals(existing.id))).write(
      NetworksCompanion(
        displayName: Value(displayName),
        gatewayIp: Value(gatewayIp),
        lastSeenAt: Value(observedAt),
      ),
    );
    return existing.id;
  }

  /// Read-only lookup of a network row (no insert), for checking during a
  /// scan whether the active network is still the one being scanned.
  Future<int?> findNetworkId({
    required String interfaceName,
    required String cidr,
  }) async {
    final row =
        await (select(networks)..where(
              (row) =>
                  row.interfaceName.equals(interfaceName) &
                  row.cidr.equals(cidr),
            ))
            .getSingleOrNull();
    return row?.id;
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final supportDir = await getApplicationSupportDirectory();
      final dbFile = File(p.join(supportDir.path, 'network_monitor.sqlite'));
      return NativeDatabase.createInBackground(dbFile);
    });
  }
}
