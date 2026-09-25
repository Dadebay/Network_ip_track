import '../../../core/utils/private_network_blocks.dart';
import '../domain/entities/accessible_subnet.dart';
import '../domain/entities/route_entry.dart';
import '../domain/entities/subnet_reachability.dart';

/// Turns a raw IPv4 route table into the list of private `172.16.0.0/12`
/// subnets this Mac can currently reach.
///
/// - Routes outside `172.16.0.0/12` are dropped (never blind-scan
///   `172.0.0.0/8`).
/// - Host routes (`/32`) are dropped; they are not scan targets.
/// - Exact duplicate destinations are normalized, preferring a directly
///   connected route.
/// - Overlapping routes with different prefixes are retained. A more-specific
///   route wins for addresses inside it, but it does not make the rest of the
///   broader route unreachable. Phase 2's scan queue owns per-address
///   deduplication.
List<AccessibleSubnet> deriveAccessibleSubnets(List<RouteEntry> routes) {
  final byDestination = <String, AccessibleSubnet>{};

  for (final route in routes) {
    if (route.destination.prefixLength >= 32) continue;
    if (!isWithinPrivate172Block(route.destination)) continue;

    final reachability = route.isDirectlyConnected
        ? SubnetReachability.directlyConnected
        : SubnetReachability.routed;
    final key = route.destination.toString();
    final existing = byDestination[key];
    if (existing == null ||
        _rank(reachability) > _rank(existing.reachability)) {
      byDestination[key] = AccessibleSubnet(
        cidr: route.destination,
        reachability: reachability,
        viaInterface: route.interfaceName,
        gateway: route.gateway,
      );
    }
  }

  final normalized = byDestination.values.toList();

  normalized.sort((a, b) {
    final addressComparison = a.cidr.networkAddress.compareTo(
      b.cidr.networkAddress,
    );
    if (addressComparison != 0) return addressComparison;
    return a.cidr.prefixLength.compareTo(b.cidr.prefixLength);
  });
  return normalized;
}

int _rank(SubnetReachability reachability) => switch (reachability) {
  SubnetReachability.directlyConnected => 2,
  SubnetReachability.routed => 1,
  SubnetReachability.unreachable => 0,
};
