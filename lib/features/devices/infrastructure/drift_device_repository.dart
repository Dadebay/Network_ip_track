import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/utils/cidr.dart';
import '../../../core/utils/ipv4_address.dart';
import '../../classification/application/device_identity.dart';
import '../../classification/domain/entities/device_classification.dart';
import '../../discovery/domain/entities/discovered_device.dart';
import '../domain/entities/device.dart';
import '../domain/entities/device_confidence.dart';
import '../domain/entities/device_observation.dart';
import '../domain/entities/device_status.dart';
import '../domain/entities/device_type.dart';
import '../domain/repositories/device_repository.dart';

/// [DeviceRepository] backed by Drift/SQLite.
class DriftDeviceRepository implements DeviceRepository {
  DriftDeviceRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<int> upsertDiscoveredDevice({
    required int networkId,
    required DiscoveredDevice discovered,
    required DeviceClassification classification,
    String? vendor,
    bool isGateway = false,
    bool isLocalDevice = false,
  }) {
    return _database.transaction(() async {
      final observedAt = discovered.respondedAt;
      final ipString = discovered.ipAddress.toString();
      final mac = discovered.macAddress;
      final osConfidence = classification.os == null
          ? null
          : classification.osConfidence;
      final pingedNow = discovered.signals.contains('ICMP yanıtı');
      final identity = deriveDeviceIdentity(discovered);

      final existing = await _findExistingDevice(
        networkId: networkId,
        ipString: ipString,
        mac: mac,
      );

      final int deviceId;
      if (existing == null) {
        deviceId = await _database
            .into(_database.devices)
            .insert(
              db.DevicesCompanion.insert(
                networkId: networkId,
                macAddress: Value(mac),
                currentIp: ipString,
                hostname: Value(discovered.hostname),
                discoveredName: Value(identity.name),
                model: Value(identity.model),
                webPort: Value(identity.webPort),
                vendor: Value(vendor),
                inferredType: classification.type.name,
                confidence: classification.typeConfidence.name,
                inferredOs: Value(classification.os),
                osConfidence: Value(osConfidence?.name),
                inferenceReasonsJson: Value(jsonEncode(classification.reasons)),
                isGateway: Value(isGateway),
                isLocalDevice: Value(isLocalDevice),
                pingConfirmed: Value(pingedNow),
                firstSeenAt: observedAt,
                lastSeenAt: observedAt,
                status: DeviceStatus.online.name,
              ),
            );
      } else {
        deviceId = existing.id;
        if (mac != null) {
          await _mergeTemporaryRows(
            networkId: networkId,
            ipString: ipString,
            intoDeviceId: deviceId,
          );
        }
        final storedTypeRank = DeviceConfidence.values
            .byName(existing.confidence)
            .rank;
        final replaceType =
            classification.typeConfidence.rank >= storedTypeRank &&
            (classification.typeConfidence != DeviceConfidence.unknown ||
                storedTypeRank == 0);
        final storedOsRank = existing.osConfidence == null
            ? -1
            : DeviceConfidence.values.byName(existing.osConfidence!).rank;
        final replaceOs =
            osConfidence != null && osConfidence.rank >= storedOsRank;

        await (_database.update(
          _database.devices,
        )..where((row) => row.id.equals(deviceId))).write(
          db.DevicesCompanion(
            macAddress: mac != null ? Value(mac) : const Value.absent(),
            currentIp: Value(ipString),
            hostname: discovered.hostname != null
                ? Value(discovered.hostname)
                : const Value.absent(),
            discoveredName: identity.name != null
                ? Value(identity.name)
                : const Value.absent(),
            model: identity.model != null
                ? Value(identity.model)
                : const Value.absent(),
            webPort: identity.webPort != null
                ? Value(identity.webPort)
                : const Value.absent(),
            vendor: vendor != null ? Value(vendor) : const Value.absent(),
            inferredType: replaceType
                ? Value(classification.type.name)
                : const Value.absent(),
            confidence: replaceType
                ? Value(classification.typeConfidence.name)
                : const Value.absent(),
            inferenceReasonsJson: replaceType || replaceOs
                ? Value(jsonEncode(classification.reasons))
                : const Value.absent(),
            inferredOs: replaceOs
                ? Value(classification.os)
                : const Value.absent(),
            osConfidence: replaceOs
                ? Value(osConfidence.name)
                : const Value.absent(),
            isGateway: Value(isGateway || existing.isGateway),
            isLocalDevice: Value(isLocalDevice || existing.isLocalDevice),
            pingConfirmed: Value(existing.pingConfirmed || pingedNow),
            lastSeenAt: Value(observedAt),
            status: Value(DeviceStatus.online.name),
          ),
        );
      }

      await _database
          .into(_database.deviceObservations)
          .insert(
            db.DeviceObservationsCompanion.insert(
              deviceId: deviceId,
              observedAt: observedAt,
              ipAddress: ipString,
              hostname: Value(discovered.hostname),
              servicesJson: Value(
                jsonEncode([
                  ...discovered.mdnsServices,
                  ...discovered.ssdpServices,
                  ?discovered.httpBanner?.describe(),
                  ?discovered.upnp?.describe(),
                ]),
              ),
              signalsJson: Value(
                jsonEncode([
                  ...discovered.signals,
                  for (final port in discovered.openPorts) 'Port $port açık',
                ]),
              ),
            ),
          );

      return deviceId;
    });
  }

  /// Match by MAC when known (a device keeps its identity across DHCP IP
  /// changes); otherwise fall back to (network, IP) as a temporary
  /// identity, upgrading that row in place the first time a MAC is learned
  /// for it rather than creating a duplicate.
  Future<db.Device?> _findExistingDevice({
    required int networkId,
    required String ipString,
    required String? mac,
  }) async {
    if (mac != null) {
      final byMac =
          await (_database.select(_database.devices)..where(
                (row) =>
                    row.networkId.equals(networkId) &
                    row.macAddress.equals(mac),
              ))
              .getSingleOrNull();
      if (byMac != null) return byMac;

      return (_database.select(_database.devices)
            ..where(
              (row) =>
                  row.networkId.equals(networkId) &
                  row.currentIp.equals(ipString) &
                  row.macAddress.isNull(),
            )
            ..limit(1))
          .getSingleOrNull();
    }

    // Several MAC-identified rows can share a stale current IP (DHCP moved
    // one of them); prefer the most recently seen.
    return (_database.select(_database.devices)
          ..where(
            (row) =>
                row.networkId.equals(networkId) &
                row.currentIp.equals(ipString),
          )
          ..orderBy([(row) => OrderingTerm.desc(row.lastSeenAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// A temp-identity (MAC-less) row at [ipString] now belongs to the device
  /// whose MAC was just learned for that IP: move its observations and
  /// traffic samples over and
  /// drop the duplicate, keeping any custom info the user entered on it.
  Future<void> _mergeTemporaryRows({
    required int networkId,
    required String ipString,
    required int intoDeviceId,
  }) async {
    final temporaryRows =
        await (_database.select(_database.devices)..where(
              (row) =>
                  row.networkId.equals(networkId) &
                  row.currentIp.equals(ipString) &
                  row.macAddress.isNull() &
                  row.id.equals(intoDeviceId).not(),
            ))
            .get();
    if (temporaryRows.isEmpty) return;

    final target = await (_database.select(
      _database.devices,
    )..where((row) => row.id.equals(intoDeviceId))).getSingle();

    for (final temp in temporaryRows) {
      await (_database.update(_database.deviceObservations)
            ..where((row) => row.deviceId.equals(temp.id)))
          .write(db.DeviceObservationsCompanion(deviceId: Value(intoDeviceId)));
      await (_database.update(_database.trafficSamples)
            ..where((row) => row.deviceId.equals(temp.id)))
          .write(db.TrafficSamplesCompanion(deviceId: Value(intoDeviceId)));
      await (_database.update(
        _database.devices,
      )..where((row) => row.id.equals(intoDeviceId))).write(
        db.DevicesCompanion(
          firstSeenAt: temp.firstSeenAt.isBefore(target.firstSeenAt)
              ? Value(temp.firstSeenAt)
              : const Value.absent(),
          customName: target.customName == null && temp.customName != null
              ? Value(temp.customName)
              : const Value.absent(),
          customDeviceType:
              target.customDeviceType == null && temp.customDeviceType != null
              ? Value(temp.customDeviceType)
              : const Value.absent(),
          note: target.note == null && temp.note != null
              ? Value(temp.note)
              : const Value.absent(),
        ),
      );
      await (_database.delete(
        _database.devices,
      )..where((row) => row.id.equals(temp.id))).go();
    }
  }

  @override
  Stream<List<Device>> watchDevicesForNetwork(int networkId) {
    final query = _database.select(_database.devices)
      ..where((row) => row.networkId.equals(networkId))
      ..orderBy([(row) => OrderingTerm.desc(row.lastSeenAt)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<Device>> getDevicesForNetwork(int networkId) async {
    final rows = await (_database.select(
      _database.devices,
    )..where((row) => row.networkId.equals(networkId))).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<Device?> watchDevice(int deviceId) {
    return (_database.select(_database.devices)
          ..where((row) => row.id.equals(deviceId)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toDomain(row));
  }

  @override
  Stream<List<DeviceObservation>> watchObservations(int deviceId) {
    final query = _database.select(_database.deviceObservations)
      ..where((row) => row.deviceId.equals(deviceId))
      ..orderBy([
        (row) => OrderingTerm.desc(row.observedAt),
        (row) => OrderingTerm.desc(row.id),
      ]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          DeviceObservation(
            id: row.id,
            deviceId: row.deviceId,
            observedAt: row.observedAt,
            ipAddress: Ipv4Address.parse(row.ipAddress),
            hostname: row.hostname,
            services: (jsonDecode(row.servicesJson) as List).cast<String>(),
            signals: (jsonDecode(row.signalsJson) as List).cast<String>(),
          ),
      ],
    );
  }

  @override
  Future<void> markUnseenDevices({
    required int networkId,
    required List<Cidr> scannedCidrs,
    required DateTime seenSince,
  }) {
    return _database.transaction(() async {
      final stale =
          await (_database.select(_database.devices)..where(
                (row) =>
                    row.networkId.equals(networkId) &
                    row.lastSeenAt.isSmallerThanValue(seenSince),
              ))
              .get();

      for (final row in stale) {
        final ip = Ipv4Address.parse(row.currentIp);
        if (!scannedCidrs.any((cidr) => cidr.contains(ip))) continue;

        final next = switch (DeviceStatus.values.byName(row.status)) {
          DeviceStatus.online => DeviceStatus.unknown,
          DeviceStatus.unknown || DeviceStatus.offline => DeviceStatus.offline,
        };
        await (_database.update(_database.devices)
              ..where((r) => r.id.equals(row.id)))
            .write(db.DevicesCompanion(status: Value(next.name)));
      }
    });
  }

  @override
  Future<void> updateUserInfo({
    required int deviceId,
    required String? customName,
    required DeviceType? customType,
    required String? note,
    required bool isKnown,
  }) async {
    String? clean(String? value) =>
        value == null || value.trim().isEmpty ? null : value.trim();
    await (_database.update(
      _database.devices,
    )..where((row) => row.id.equals(deviceId))).write(
      db.DevicesCompanion(
        customName: Value(clean(customName)),
        customDeviceType: Value(customType?.name),
        note: Value(clean(note)),
        isKnown: Value(isKnown),
      ),
    );
  }

  Device _toDomain(db.Device row) {
    return Device(
      id: row.id,
      networkId: row.networkId,
      macAddress: row.macAddress,
      currentIp: Ipv4Address.parse(row.currentIp),
      hostname: row.hostname,
      discoveredName: row.discoveredName,
      model: row.model,
      webPort: row.webPort,
      vendor: row.vendor,
      inferredType: DeviceType.values.byName(row.inferredType),
      inferredOs: row.inferredOs,
      confidence: DeviceConfidence.values.byName(row.confidence),
      osConfidence: row.osConfidence == null
          ? null
          : DeviceConfidence.values.byName(row.osConfidence!),
      inferenceReasons: (jsonDecode(row.inferenceReasonsJson) as List)
          .cast<String>(),
      customName: row.customName,
      customType: row.customDeviceType == null
          ? null
          : DeviceType.values.asNameMap()[row.customDeviceType!],
      note: row.note,
      isKnown: row.isKnown,
      pingConfirmed: row.pingConfirmed,
      isGateway: row.isGateway,
      isLocalDevice: row.isLocalDevice,
      firstSeenAt: row.firstSeenAt,
      lastSeenAt: row.lastSeenAt,
      status: DeviceStatus.values.byName(row.status),
    );
  }
}
