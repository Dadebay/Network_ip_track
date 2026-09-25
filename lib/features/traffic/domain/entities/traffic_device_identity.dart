import '../../../../core/utils/ipv4_address.dart';
import '../../../../core/utils/mac_address.dart';

/// The MAC/IP binding a traffic provider reported for a device at the moment
/// of a reading. Stored with every sample, because the same IP can belong to
/// a different device later (DHCP) and the same MAC can move between IPs.
class TrafficDeviceIdentity {
  const TrafficDeviceIdentity._({this.macAddress, this.ipAddress});

  /// Normalizes [macAddress] (`aa:bb:cc:dd:ee:ff`) and [ipAddress]; invalid
  /// values are dropped. Returns null when neither is usable.
  static TrafficDeviceIdentity? tryCreate({
    String? macAddress,
    String? ipAddress,
  }) {
    final mac = macAddress == null ? null : normalizeMacAddress(macAddress);
    final ip = ipAddress == null
        ? null
        : Ipv4Address.tryParse(ipAddress.trim())?.toString();
    if (mac == null && ip == null) return null;
    return TrafficDeviceIdentity._(macAddress: mac, ipAddress: ip);
  }

  /// Binding not recorded (e.g. rows written by an older version). Never
  /// produced by providers.
  static const unknown = TrafficDeviceIdentity._();

  final String? macAddress;
  final String? ipAddress;

  /// Counter-continuity key. MAC is preferred because it survives DHCP
  /// changes; IP is only used when the provider does not report a MAC.
  String get counterKey => macAddress != null
      ? 'mac:$macAddress'
      : ipAddress != null
      ? 'ip:$ipAddress'
      : 'unknown';

  @override
  bool operator ==(Object other) =>
      other is TrafficDeviceIdentity &&
      other.macAddress == macAddress &&
      other.ipAddress == ipAddress;

  @override
  int get hashCode => Object.hash(macAddress, ipAddress);

  @override
  String toString() =>
      'TrafficDeviceIdentity(mac: $macAddress, ip: $ipAddress)';
}
