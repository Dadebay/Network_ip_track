/// A parsed SSDP `M-SEARCH` response's classification-relevant headers.
class SsdpResponse {
  const SsdpResponse({this.server, this.st, this.location});
  final String? server;
  final String? st;
  final String? location;

  bool get isEmpty => server == null && st == null && location == null;

  /// Human-readable one-line summary for [DiscoveredDevice.ssdpServices].
  String describe() {
    final parts = [?server, if (st != null) 'ST: $st'];
    return parts.isEmpty ? 'SSDP yanıtı' : parts.join(' · ');
  }
}

/// Parses one SSDP HTTP-like response datagram. Pure and fixture-testable.
SsdpResponse parseSsdpResponse(String raw) {
  String? server;
  String? st;
  String? location;

  for (final line in raw.split('\r\n')) {
    final separatorIndex = line.indexOf(':');
    if (separatorIndex == -1) continue;
    final header = line.substring(0, separatorIndex).trim().toUpperCase();
    final value = line.substring(separatorIndex + 1).trim();
    switch (header) {
      case 'SERVER':
        server = value;
      case 'ST':
        st = value;
      case 'LOCATION':
        location = value;
    }
  }

  return SsdpResponse(server: server, st: st, location: location);
}
