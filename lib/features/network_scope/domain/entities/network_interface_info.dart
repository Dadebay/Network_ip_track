import '../../../../core/utils/cidr.dart';
import '../../../../core/utils/ipv4_address.dart';
import 'interface_kind.dart';

/// A physical/virtual network interface with its resolved IPv4 configuration.
class NetworkInterfaceInfo {
  const NetworkInterfaceInfo({
    required this.name,
    required this.displayName,
    required this.kind,
    required this.address,
    required this.subnetMask,
    required this.isDefaultRoute,
    this.gatewayAddress,
  });

  /// BSD interface name, e.g. `en0`.
  final String name;

  /// Human-readable name, e.g. `Wi-Fi` or `Ethernet`. Falls back to [name]
  /// when macOS does not report a hardware port mapping for it.
  final String displayName;

  final InterfaceKind kind;
  final Ipv4Address address;
  final Ipv4Address subnetMask;

  /// Gateway used by this interface, when known. Only reliably known for the
  /// interface currently carrying the default route.
  final Ipv4Address? gatewayAddress;

  /// True if this interface currently carries the system default route.
  final bool isDefaultRoute;

  Cidr get cidr => Cidr.fromAddressAndMask(address, subnetMask);

  Ipv4Address get broadcastAddress => cidr.broadcastAddress;

  @override
  String toString() => 'NetworkInterfaceInfo($name, $displayName, $cidr)';
}
