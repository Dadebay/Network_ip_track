import '../../../../core/utils/ipv4_address.dart';
import '../entities/ssdp_response.dart';

/// Platform adapter for a network-wide SSDP/UPnP discovery search
/// (`M-SEARCH`). Runs once per scan chunk, like [MdnsProvider].
abstract interface class SsdpProvider {
  /// Returns each responding host's SSDP responses, keyed by IP.
  Future<Map<Ipv4Address, List<SsdpResponse>>> search({
    required Duration timeout,
  });
}
