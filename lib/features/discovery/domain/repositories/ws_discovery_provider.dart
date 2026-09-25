import '../../../../core/utils/ipv4_address.dart';
import '../entities/ws_discovery_match.dart';

/// Platform adapter for a WS-Discovery `Probe` (UDP 3702 multicast). Runs
/// once per scan chunk, like [SsdpProvider].
abstract interface class WsDiscoveryProvider {
  Future<Map<Ipv4Address, List<WsDiscoveryMatch>>> probe({
    required Duration timeout,
  });
}
