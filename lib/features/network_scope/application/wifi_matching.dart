import '../domain/entities/wifi_scan.dart';

/// Wi-Fi networks an access point with LAN MAC [mac] most likely
/// broadcasts, best match first.
///
/// An access point's radio MACs (BSSIDs) are usually its LAN MAC with a
/// small offset in the last byte, or the same address with the
/// "locally administered" bit set on the first byte for extra SSIDs. Both
/// are heuristics, so callers present matches as estimates.
List<WifiNetwork> wifiNetworksFor(String? mac, List<WifiNetwork> networks) {
  final device = _bytes(mac);
  if (device == null) return const [];
  final scored = <(WifiNetwork, int)>[];
  for (final network in networks) {
    final radio = _bytes(network.bssid);
    if (radio == null || network.ssid == null) continue;
    final distance = _distance(device, radio);
    if (distance != null) scored.add((network, distance));
  }
  scored.sort((a, b) {
    final byDistance = a.$2.compareTo(b.$2);
    return byDistance != 0 ? byDistance : b.$1.rssi.compareTo(a.$1.rssi);
  });
  final seen = <String>{};
  return [
    for (final (network, _) in scored)
      if (seen.add('${network.ssid}|${network.band}')) network,
  ];
}

/// Offset of the last byte when the addresses otherwise match (ignoring the
/// locally-administered bit); null when they're unrelated.
int? _distance(List<int> device, List<int> radio) {
  if ((device[0] | 0x02) != (radio[0] | 0x02)) return null;
  for (var i = 1; i < 5; i++) {
    if (device[i] != radio[i]) return null;
  }
  final offset = (device[5] - radio[5]).abs();
  if (offset > 16) return null;
  return offset + (device[0] == radio[0] ? 0 : 1);
}

List<int>? _bytes(String? mac) {
  if (mac == null) return null;
  final parts = mac.toLowerCase().split(RegExp('[:-]'));
  if (parts.length != 6) return null;
  final bytes = [for (final part in parts) int.tryParse(part, radix: 16)];
  if (bytes.any((b) => b == null || b < 0 || b > 255)) return null;
  return bytes.cast<int>();
}

/// `HENRY3 (2,4 GHz), HENRY3_5G (5 GHz)`-style summary.
String describeWifiNetworks(List<WifiNetwork> networks) =>
    {for (final network in networks) network.ssid!}.join(', ');
