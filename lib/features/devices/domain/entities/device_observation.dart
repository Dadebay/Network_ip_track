import '../../../../core/utils/ipv4_address.dart';

/// One discovery pass's raw signals for a device — mirrors
/// `device_observations`. Kept even after the device's current fields move
/// on (e.g. DHCP reassigns its IP) so IP history is never lost.
class DeviceObservation {
  const DeviceObservation({
    required this.id,
    required this.deviceId,
    required this.observedAt,
    required this.ipAddress,
    required this.services,
    required this.signals,
    this.hostname,
  });

  final int id;
  final int deviceId;
  final DateTime observedAt;
  final Ipv4Address ipAddress;
  final String? hostname;
  final List<String> services;
  final List<String> signals;
}
