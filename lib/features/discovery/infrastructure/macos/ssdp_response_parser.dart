import '../../domain/entities/ssdp_response.dart';

export '../../domain/entities/ssdp_response.dart';

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
