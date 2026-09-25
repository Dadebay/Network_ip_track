import '../../../../core/utils/ipv4_address.dart';

/// Platform adapter for a network-wide SSDP/UPnP discovery search
/// (`M-SEARCH`). Runs once per scan chunk, like [MdnsProvider].
abstract interface class SsdpProvider {
  /// Returns each responding host's advertised SSDP device/service
  /// descriptions, keyed by IP.
  Future<Map<Ipv4Address, List<String>>> search({required Duration timeout});
}
