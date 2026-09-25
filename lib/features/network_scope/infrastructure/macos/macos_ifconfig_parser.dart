import '../../../../core/utils/ipv4_address.dart';
import '../../../../core/utils/subnet_mask.dart';

/// One `ifconfig` interface block, before it is combined with route/hardware
/// port information into a domain [NetworkInterfaceInfo].
class ParsedIfconfigInterface {
  const ParsedIfconfigInterface({
    required this.name,
    required this.flags,
    this.inetAddress,
    this.netmask,
    this.etherAddress,
  });

  final String name;
  final Set<String> flags;
  final Ipv4Address? inetAddress;
  final Ipv4Address? netmask;
  final String? etherAddress;

  bool get isUp => flags.contains('UP');
  bool get isLoopback => flags.contains('LOOPBACK');
}

final _interfaceHeaderPattern = RegExp(r'^(\S+):\s+flags=\d+<([^>]*)>');
// Point-to-point interfaces (VPN/utun) report `inet <local> --> <peer>
// netmask <mask>`; the `--> peer` segment is optional.
final _inetLinePattern = RegExp(
  r'^inet\s+(\S+)(?:\s+-->\s+\S+)?\s+netmask\s+(\S+)',
);
final _etherLinePattern = RegExp(r'^ether\s+(\S+)');

/// Parses the full stdout of macOS `ifconfig` (no arguments) into one entry
/// per interface. Pure and fixture-testable — no process spawning here.
List<ParsedIfconfigInterface> parseIfconfigOutput(String raw) {
  final interfaces = <ParsedIfconfigInterface>[];

  String? currentName;
  Set<String> currentFlags = const {};
  Ipv4Address? currentInet;
  Ipv4Address? currentNetmask;
  String? currentEther;

  void flush() {
    if (currentName == null) return;
    interfaces.add(
      ParsedIfconfigInterface(
        name: currentName,
        flags: currentFlags,
        inetAddress: currentInet,
        netmask: currentNetmask,
        etherAddress: currentEther,
      ),
    );
  }

  for (final rawLine in raw.split('\n')) {
    if (rawLine.isEmpty) continue;
    final isHeaderLine = !rawLine.startsWith(RegExp(r'\s'));

    if (isHeaderLine) {
      final match = _interfaceHeaderPattern.firstMatch(rawLine);
      if (match == null) continue;
      flush();
      currentName = match.group(1);
      currentFlags = match
          .group(2)!
          .split(',')
          .where((flag) => flag.isNotEmpty)
          .toSet();
      currentInet = null;
      currentNetmask = null;
      currentEther = null;
      continue;
    }

    if (currentName == null) continue;
    final trimmed = rawLine.trim();

    if (currentInet == null) {
      final inetMatch = _inetLinePattern.firstMatch(trimmed);
      if (inetMatch != null) {
        currentInet = Ipv4Address.tryParse(inetMatch.group(1)!);
        currentNetmask = _tryParseNetmask(inetMatch.group(2)!);
        continue;
      }
    }

    if (currentEther == null) {
      final etherMatch = _etherLinePattern.firstMatch(trimmed);
      if (etherMatch != null) {
        currentEther = etherMatch.group(1);
      }
    }
  }
  flush();

  return interfaces;
}

Ipv4Address? _tryParseNetmask(String raw) {
  try {
    return parseHexNetmask(raw);
  } on FormatException {
    return null;
  }
}
