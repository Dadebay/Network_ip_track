/// A parsed SSDP `M-SEARCH` response's classification-relevant headers.
class SsdpResponse {
  const SsdpResponse({this.server, this.st, this.location});
  final String? server;
  final String? st;

  /// URL of the device's UPnP description XML.
  final String? location;

  bool get isEmpty => server == null && st == null && location == null;

  /// Human-readable one-line summary for [DiscoveredDevice.ssdpServices].
  String describe() {
    final parts = [?server, if (st != null) 'ST: $st'];
    return parts.isEmpty ? 'SSDP yanıtı' : parts.join(' · ');
  }
}
