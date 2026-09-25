import 'package:drift/drift.dart';

import 'devices_table.dart';

// Per-device time-range queries (detail charts, list totals) over up to
// 1,000 devices × 90 days go through this index.
@TableIndex(
  name: 'traffic_samples_device_period',
  columns: {#deviceId, #periodStart},
)
class TrafficSamples extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deviceId => integer().references(Devices, #id)();
  TextColumn get source => text()();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  IntColumn get downloadBytes => integer()();
  IntColumn get uploadBytes => integer()();
  TextColumn get reliability => text()();

  /// The MAC/IP binding the provider reported at sample time (schema v2).
  TextColumn get macAddress => text().nullable()();
  TextColumn get ipAddress => text().nullable()();
}
