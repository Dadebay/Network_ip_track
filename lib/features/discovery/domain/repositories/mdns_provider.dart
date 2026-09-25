import '../../../../core/utils/ipv4_address.dart';
import '../entities/mdns_service_record.dart';

/// Platform adapter for a network-wide mDNS/Bonjour service browse.
///
/// Real Bonjour discovery browses per service type and matches results back
/// to hosts by IP, rather than querying host-by-host, so this runs once per
/// scan rather than once per candidate IP.
abstract interface class MdnsProvider {
  /// Returns each responding host's advertised services, keyed by IP.
  Future<Map<Ipv4Address, List<MdnsServiceRecord>>> browse({
    required Duration timeout,
  });
}
