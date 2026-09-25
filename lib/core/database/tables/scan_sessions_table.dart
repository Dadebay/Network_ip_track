import 'package:drift/drift.dart';

import 'networks_table.dart';

class ScanSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get networkId => integer().references(Networks, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get finishedAt => dateTime().nullable()();
  TextColumn get targetCidrsJson => text()();
  TextColumn get status => text()();
  IntColumn get hostsScanned => integer().withDefault(const Constant(0))();
  IntColumn get devicesFound => integer().withDefault(const Constant(0))();
  TextColumn get checkpointJson => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
}
