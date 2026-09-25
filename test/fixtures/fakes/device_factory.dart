import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/devices/domain/entities/device.dart';
import 'package:network_monitor/features/devices/domain/entities/device_confidence.dart';
import 'package:network_monitor/features/devices/domain/entities/device_status.dart';
import 'package:network_monitor/features/devices/domain/entities/device_type.dart';

Device makeDevice(
  int id,
  String ip, {
  String? mac,
  String? hostname,
  String? vendor,
  String? customName,
  DeviceType type = DeviceType.unknown,
  DeviceConfidence confidence = DeviceConfidence.unknown,
  DeviceStatus status = DeviceStatus.online,
  bool isGateway = false,
  bool isLocalDevice = false,
  DateTime? lastSeenAt,
}) {
  final seen = lastSeenAt ?? DateTime(2026, 9, 1, 12);
  return Device(
    id: id,
    networkId: 1,
    currentIp: Ipv4Address.parse(ip),
    macAddress: mac,
    hostname: hostname,
    vendor: vendor,
    customName: customName,
    inferredType: type,
    confidence: confidence,
    status: status,
    isGateway: isGateway,
    isLocalDevice: isLocalDevice,
    firstSeenAt: seen,
    lastSeenAt: seen,
  );
}
