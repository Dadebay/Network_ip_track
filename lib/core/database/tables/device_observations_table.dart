import 'package:drift/drift.dart';

import 'devices_table.dart';

class DeviceObservations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deviceId => integer().references(Devices, #id)();
  DateTimeColumn get observedAt => dateTime()();
  TextColumn get ipAddress => text()();
  TextColumn get hostname => text().nullable()();
  TextColumn get servicesJson => text().withDefault(const Constant('[]'))();
  TextColumn get signalsJson => text().withDefault(const Constant('[]'))();
}
