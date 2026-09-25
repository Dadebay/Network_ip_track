/// The staged discovery methods from the spec's "Cihaz keşfi" section,
/// run in this order for every scan.
enum DiscoveryMethod {
  arpTable,
  icmpPing,
  reverseDns,
  mdns,
  ssdp,
  netbios,
  limitedPortScan,
  httpBanner,
  wsDiscovery;

  String get label => switch (this) {
    DiscoveryMethod.arpTable => 'ARP/neighbor tablosu',
    DiscoveryMethod.icmpPing => 'ICMP ping',
    DiscoveryMethod.reverseDns => 'Reverse DNS',
    DiscoveryMethod.mdns => 'mDNS/Bonjour',
    DiscoveryMethod.ssdp => 'SSDP/UPnP',
    DiscoveryMethod.netbios => 'NetBIOS',
    DiscoveryMethod.limitedPortScan => 'Sınırlı port kontrolü',
    DiscoveryMethod.httpBanner => 'Web arayüzü başlığı',
    DiscoveryMethod.wsDiscovery => 'WS-Discovery/ONVIF',
  };
}
