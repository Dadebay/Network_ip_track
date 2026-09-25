import 'package:drift/drift.dart';

import 'networks_table.dart';

class Devices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get networkId => integer().references(Networks, #id)();
  TextColumn get macAddress => text().nullable()();
  TextColumn get currentIp => text()();
  TextColumn get hostname => text().nullable()();
  TextColumn get vendor => text().nullable()();
  TextColumn get inferredType => text()();
  TextColumn get inferredOs => text().nullable()();
  TextColumn get confidence => text()();

  /// Confidence of [inferredOs] alone (schema v3) — the OS can be backed by
  /// weaker evidence than the device type.
  TextColumn get osConfidence => text().nullable()();

  /// Human-readable reasons behind the current inference (schema v3).
  TextColumn get inferenceReasonsJson =>
      text().withDefault(const Constant('[]'))();
  TextColumn get customName => text().nullable()();
  // Named explicitly: `customType` collides with drift's own
  // `Table.customType()` API, so the Dart getter must differ from the spec's
  // `custom_type` column name.
  TextColumn get customDeviceType => text().nullable().named('custom_type')();
  TextColumn get note => text().nullable()();

  /// "Bu cihazı tanıyorum" (schema v3).
  BoolColumn get isKnown => boolean().withDefault(const Constant(false))();

  /// True once an ICMP echo reply has ever been seen from this IP (schema
  /// v4). Sticky — never reset to false — because it's a strong, hard-to-
  /// spoof liveness signal: on networks where a middlebox answers every TCP
  /// connect attempt (see `signals_json`/port-probe false positives), this
  /// is what actually distinguishes a real host from noise.
  BoolColumn get pingConfirmed =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isGateway => boolean().withDefault(const Constant(false))();
  BoolColumn get isLocalDevice =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get firstSeenAt => dateTime()();
  DateTimeColumn get lastSeenAt => dateTime()();
  TextColumn get status => text()();
}
