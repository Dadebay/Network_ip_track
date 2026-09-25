import '../../../../core/utils/cidr.dart';
import '../../../../core/utils/ipv4_address.dart';

/// A single IPv4 route table entry, as reported by the OS routing table.
class RouteEntry {
  const RouteEntry({
    required this.destination,
    required this.interfaceName,
    required this.isDefault,
    required this.isDirectlyConnected,
    required this.rawFlags,
    this.gateway,
  });

  final Cidr destination;

  /// Null when the route has no next-hop IP (e.g. a directly-connected
  /// link-layer route reported as `link#N`).
  final Ipv4Address? gateway;

  final String interfaceName;
  final bool isDefault;

  /// True when the route table marks this destination as reachable without
  /// a gateway hop (no `G` flag) — i.e. it is on the local link.
  final bool isDirectlyConnected;

  /// Raw flags column, kept for diagnostics/logging.
  final String rawFlags;

  @override
  String toString() =>
      'RouteEntry($destination via ${gateway ?? 'link'} on $interfaceName, flags=$rawFlags)';
}
