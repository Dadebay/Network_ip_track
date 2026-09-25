import 'package:drift/drift.dart';

class Networks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get interfaceName => text()();
  TextColumn get displayName => text()();
  TextColumn get cidr => text()();
  TextColumn get gatewayIp => text().nullable()();
  DateTimeColumn get firstSeenAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime()();
}
