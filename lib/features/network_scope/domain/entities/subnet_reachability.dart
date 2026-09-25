/// How a private-172 subnet was determined to be reachable.
enum SubnetReachability {
  /// On the same local link as one of this Mac's interfaces.
  directlyConnected,

  /// Reachable through a gateway per the route table, but not local.
  routed,

  /// Within `172.16.0.0/12` but no route exists to it.
  unreachable,
}
