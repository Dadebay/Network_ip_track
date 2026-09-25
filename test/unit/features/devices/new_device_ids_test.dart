import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/devices/domain/entities/device.dart';
import 'package:network_monitor/features/devices/domain/entities/device_confidence.dart';
import 'package:network_monitor/features/devices/domain/entities/device_status.dart';
import 'package:network_monitor/features/devices/domain/entities/device_type.dart';
import 'package:network_monitor/features/devices/presentation/widgets/device_visuals.dart';

Device seen(int id, DateTime firstSeen) => Device(
  id: id,
  networkId: 1,
  currentIp: Ipv4Address.parse('172.16.14.$id'),
  inferredType: DeviceType.unknown,
  confidence: DeviceConfidence.unknown,
  isGateway: false,
  isLocalDevice: false,
  firstSeenAt: firstSeen,
  lastSeenAt: firstSeen,
  status: DeviceStatus.online,
);

void main() {
  final now = DateTime(2026, 9, 25, 12);

  test('the first scan never marks devices new', () {
    final devices = [
      seen(1, now.subtract(const Duration(hours: 2))),
      seen(2, now.subtract(const Duration(hours: 2, minutes: -5))),
    ];
    expect(newDeviceIds(devices, now: now), isEmpty);
  });

  test('later arrivals within a day are new; older ones are not', () {
    final devices = [
      seen(1, now.subtract(const Duration(days: 5))),
      seen(2, now.subtract(const Duration(hours: 3))),
      seen(3, now.subtract(const Duration(days: 2))),
    ];
    expect(newDeviceIds(devices, now: now), {2});
  });
}
