import '../../../../core/utils/ipv4_address.dart';

/// One row of the OS ARP/neighbor table: a MAC address learned for an IP on
/// the local link.
class ArpEntry {
  const ArpEntry({
    required this.ipAddress,
    required this.macAddress,
    this.interfaceName,
  });

  final Ipv4Address ipAddress;

  /// Normalized lowercase `aa:bb:cc:dd:ee:ff`.
  final String macAddress;
  final String? interfaceName;
}
