import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/cidr.dart';
import 'package:network_monitor/features/devices/application/device_query.dart';
import 'package:network_monitor/features/devices/domain/entities/device.dart';
import 'package:network_monitor/features/devices/domain/entities/device_status.dart';
import 'package:network_monitor/features/devices/domain/entities/device_type.dart';

import '../../../fixtures/fakes/device_factory.dart';

void main() {
  final devices = [
    makeDevice(
      1,
      '172.16.14.254',
      hostname: 'router',
      isGateway: true,
      type: DeviceType.routerGateway,
      mac: 'ac:de:48:aa:bb:cc',
    ),
    makeDevice(
      2,
      '172.16.14.12',
      hostname: 'iPhone',
      vendor: 'Apple',
      lastSeenAt: DateTime(2026, 9, 3),
    ),
    makeDevice(
      3,
      '172.16.14.9',
      customName: 'Yazıcım',
      status: DeviceStatus.offline,
      lastSeenAt: DateTime(2026, 8, 1),
    ),
    makeDevice(4, '172.16.20.5', status: DeviceStatus.unknown),
  ];

  // These tests predate the "hide uninformative offline" default and cover
  // sorting/searching/other filters, so they opt out of it.
  List<int> ids(DeviceQuery q) => applyDeviceQuery(
    devices,
    q.copyWith(hideUninformativeOffline: false),
  ).map((d) => d.id).toList();

  test('sorts by IP numerically, not lexically', () {
    expect(ids(const DeviceQuery()), [3, 2, 1, 4]);
    expect(ids(const DeviceQuery(ascending: false)), [4, 1, 2, 3]);
  });

  test('sorts by name and by last seen', () {
    expect(ids(const DeviceQuery(sortField: DeviceSortField.name)), [
      4, // "172.16.20.5" (no name, falls back to IP)
      2, // iPhone
      1, // router
      3, // Yazıcım
    ]);
    expect(
      ids(
        const DeviceQuery(
          sortField: DeviceSortField.lastSeen,
          ascending: false,
        ),
      ).first,
      2,
    );
  });

  test(
    'searches IP, MAC (with or without separators), hostname, vendor, custom name',
    () {
      expect(ids(const DeviceQuery(search: '14.12')), [2]);
      expect(ids(const DeviceQuery(search: 'AC:DE:48')), [1]);
      expect(ids(const DeviceQuery(search: 'acde48aa')), [1]);
      expect(ids(const DeviceQuery(search: 'iphone')), [2]);
      expect(ids(const DeviceQuery(search: 'apple')), [2]);
      expect(ids(const DeviceQuery(search: 'yazıcım')), [3]);
    },
  );

  test('filters by status, type and subnet', () {
    expect(
      ids(
        const DeviceQuery(
          statuses: {DeviceStatus.offline, DeviceStatus.unknown},
        ),
      ),
      [3, 4],
    );
    expect(ids(const DeviceQuery(types: {DeviceType.routerGateway})), [1]);
    expect(ids(DeviceQuery(subnet: Cidr.parse('172.16.20.0/24'))), [4]);
  });

  test(
    'daily traffic sort puts devices without data last in both directions',
    () {
      const traffic = {1: 500, 2: 9000};
      List<int> sorted({required bool ascending}) => applyDeviceQuery(
        devices,
        DeviceQuery(
          sortField: DeviceSortField.dailyTraffic,
          ascending: ascending,
          hideUninformativeOffline: false,
        ),
        dailyTrafficBytes: traffic,
      ).map((d) => d.id).toList();

      expect(sorted(ascending: false), [2, 1, 3, 4]);
      expect(sorted(ascending: true).take(2), [1, 2]);
      expect(sorted(ascending: true).skip(2).toSet(), {3, 4});
    },
  );

  test(
    'filters by OS and vendor, with "Bilinmiyor" matching missing values',
    () {
      expect(ids(const DeviceQuery(vendors: {'Apple'})), [2]);
      expect(ids(const DeviceQuery(vendors: {DeviceQuery.unknownValue})), [
        3,
        1,
        4,
      ]);
      expect(ids(const DeviceQuery(osNames: {DeviceQuery.unknownValue})), [
        3,
        2,
        1,
        4,
      ]);
    },
  );

  test('type filter uses the user\'s type over the inferred one', () {
    final overridden = [makeDevice(1, '172.16.14.5', type: DeviceType.unknown)];
    final withCustom = [
      for (final d in overridden)
        Device(
          id: d.id,
          networkId: d.networkId,
          currentIp: d.currentIp,
          inferredType: d.inferredType,
          confidence: d.confidence,
          isGateway: false,
          isLocalDevice: false,
          firstSeenAt: d.firstSeenAt,
          lastSeenAt: d.lastSeenAt,
          status: d.status,
          customType: DeviceType.printer,
        ),
    ];
    expect(
      applyDeviceQuery(
        withCustom,
        const DeviceQuery(types: {DeviceType.printer}),
      ),
      hasLength(1),
    );
    expect(
      applyDeviceQuery(
        withCustom,
        const DeviceQuery(types: {DeviceType.unknown}),
      ),
      isEmpty,
    );
  });

  test('hides offline devices with no info by default; keeps named ones', () {
    // Device 4: unknown status, no MAC/name/vendor -> a ghost.
    // Device 3: offline but the user named it "Yazıcım" -> kept.
    final visible = applyDeviceQuery(
      devices,
      const DeviceQuery(),
    ).map((d) => d.id).toList();
    expect(visible, isNot(contains(4)));
    expect(visible, contains(3));
    // Turning the option off brings the ghost back.
    expect(
      applyDeviceQuery(
        devices,
        const DeviceQuery(hideUninformativeOffline: false),
      ).map((d) => d.id),
      contains(4),
    );
    // An online device with no info is never hidden.
    final onlineGhost = [makeDevice(9, '172.16.14.99')];
    expect(
      applyDeviceQuery(onlineGhost, const DeviceQuery()).map((d) => d.id),
      [9],
    );
  });
}
