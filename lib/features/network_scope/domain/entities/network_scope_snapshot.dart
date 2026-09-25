import 'accessible_subnet.dart';
import 'network_interface_info.dart';

/// A point-in-time view of this Mac's network scope: every usable interface,
/// which one carries the default route, and which private `172.16.0.0/12`
/// subnets are currently reachable.
class NetworkScopeSnapshot {
  const NetworkScopeSnapshot({
    required this.interfaces,
    required this.accessibleSubnets,
    required this.detectedAt,
    this.activeInterface,
    this.defaultRouteViaVpn = false,
  });

  final List<NetworkInterfaceInfo> interfaces;

  /// The interface chosen to represent "the network you're on". This is the
  /// physical (Wi-Fi/Ethernet) default-route interface when there is one; if
  /// the default route instead goes through a VPN tunnel, it falls back to
  /// the sole physical interface so the LAN scope stays usable even with a
  /// full-tunnel VPN active (see [defaultRouteViaVpn]).
  final NetworkInterfaceInfo? activeInterface;

  /// True when the OS default route is a VPN tunnel rather than a physical
  /// interface, i.e. [activeInterface] (if any) was chosen as a fallback
  /// rather than read directly off the default route.
  final bool defaultRouteViaVpn;

  /// Reachable (or explicitly unreachable) subnets within the private
  /// `172.16.0.0/12` block, derived from the route table.
  final List<AccessibleSubnet> accessibleSubnets;

  final DateTime detectedAt;
}
