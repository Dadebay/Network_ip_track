import '../../../../core/utils/ipv4_address.dart';
import '../repositories/http_banner_provider.dart';
import 'mdns_service_record.dart';

/// One host's accumulated discovery signals for a single scan pass, streamed
/// to the UI/repository as soon as it's known — the pipeline enriches this
/// incrementally (ARP → ping → ports → reverse DNS/NetBIOS) rather than
/// waiting for every stage to finish before reporting anything.
class DiscoveredDevice {
  const DiscoveredDevice({
    required this.ipAddress,
    required this.respondedAt,
    this.macAddress,
    this.hostname,
    this.netbiosName,
    this.ttl,
    this.httpBanner,
    this.mdnsRecords = const [],
    this.ssdpServices = const [],
    this.openPorts = const [],
    this.signals = const [],
  });

  final Ipv4Address ipAddress;
  final DateTime respondedAt;

  /// Normalized lowercase `aa:bb:cc:dd:ee:ff`, or null if not learned (only
  /// reliably known for hosts on the same L2 segment — see spec limitation
  /// #8).
  final String? macAddress;

  final String? hostname;
  final String? netbiosName;

  /// TTL of the ICMP echo reply, when one arrived.
  final int? ttl;

  /// What the device's web interface says about itself, if it has one.
  final HttpBanner? httpBanner;

  final List<MdnsServiceRecord> mdnsRecords;
  final List<String> ssdpServices;
  final List<int> openPorts;

  /// Free-text discovery facts (e.g. "ICMP yanıtı", "ARP yanıtı") kept in
  /// `device_observations` for the detail view.
  final List<String> signals;

  List<String> get mdnsServices => [
    for (final record in mdnsRecords) record.describe(),
  ];

  DiscoveredDevice merge(DiscoveredDevice other) {
    return DiscoveredDevice(
      ipAddress: ipAddress,
      respondedAt: other.respondedAt.isAfter(respondedAt)
          ? other.respondedAt
          : respondedAt,
      macAddress: other.macAddress ?? macAddress,
      hostname: other.hostname ?? hostname,
      netbiosName: other.netbiosName ?? netbiosName,
      ttl: other.ttl ?? ttl,
      httpBanner: other.httpBanner ?? httpBanner,
      mdnsRecords: [...mdnsRecords, ...other.mdnsRecords],
      ssdpServices: {...ssdpServices, ...other.ssdpServices}.toList(),
      openPorts: {...openPorts, ...other.openPorts}.toList(),
      signals: {...signals, ...other.signals}.toList(),
    );
  }
}
