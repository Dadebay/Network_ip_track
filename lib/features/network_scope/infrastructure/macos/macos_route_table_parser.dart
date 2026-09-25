import '../../../../core/utils/cidr.dart';
import '../../../../core/utils/ipv4_address.dart';
import '../../domain/entities/route_entry.dart';

/// Parses the stdout of `netstat -rn -f inet` into [RouteEntry] values.
/// Pure and fixture-testable — never invoked with live shell output outside
/// of [MacosRouteProvider].
class MacosRouteTableParser {
  const MacosRouteTableParser();

  List<RouteEntry> parse(String raw) {
    final entries = <RouteEntry>[];
    var inIpv4Section = false;

    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line == 'Internet:') {
        inIpv4Section = true;
        continue;
      }
      if (line == 'Internet6:') {
        inIpv4Section = false;
        continue;
      }
      if (!inIpv4Section || line.isEmpty || line.startsWith('Destination')) {
        continue;
      }

      final columns = line.split(RegExp(r'\s+'));
      if (columns.length < 4) continue;

      final destinationRaw = columns[0];
      final gatewayRaw = columns[1];
      final flags = columns[2];
      final interfaceName = columns[3];

      final destination = _parseDestination(destinationRaw);
      if (destination == null) continue;

      entries.add(
        RouteEntry(
          destination: destination,
          gateway: gatewayRaw.startsWith('link#')
              ? null
              : Ipv4Address.tryParse(gatewayRaw),
          interfaceName: interfaceName,
          isDefault: destinationRaw == 'default',
          isDirectlyConnected: !flags.contains('G'),
          rawFlags: flags,
        ),
      );
    }

    return entries;
  }

  Cidr? _parseDestination(String raw) {
    if (raw == 'default') {
      return Cidr.parse('0.0.0.0/0');
    }

    final slashIndex = raw.indexOf('/');
    String addressPart;
    int prefixLength;

    if (slashIndex != -1) {
      addressPart = raw.substring(0, slashIndex);
      final parsedPrefix = int.tryParse(raw.substring(slashIndex + 1));
      if (parsedPrefix == null) return null;
      prefixLength = parsedPrefix;
    } else {
      // macOS netstat omits the /prefix for "natural" boundaries and instead
      // drops trailing zero octets, e.g. `172.16.14` means `172.16.14.0/24`.
      addressPart = raw;
      final octetCount = raw.split('.').length;
      prefixLength = switch (octetCount) {
        1 => 8,
        2 => 16,
        3 => 24,
        _ => 32,
      };
    }

    final octets = addressPart.split('.');
    while (octets.length < 4) {
      octets.add('0');
    }
    if (octets.length != 4) return null;

    final address = Ipv4Address.tryParse(octets.join('.'));
    if (address == null) return null;
    if (prefixLength < 0 || prefixLength > 32) return null;

    return Cidr.fromAddressAndPrefix(address, prefixLength);
  }
}
