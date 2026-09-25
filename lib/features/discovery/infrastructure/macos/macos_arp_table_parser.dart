import '../../../../core/utils/ipv4_address.dart';
import '../../../../core/utils/mac_address.dart';
import '../../domain/entities/arp_entry.dart';

final _arpLinePattern = RegExp(
  r'^\S+\s+\(([\d.]+)\)\s+at\s+(\S+)\s+on\s+(\S+)',
);

/// Parses macOS `arp -a` output. Pure and fixture-testable.
class MacosArpTableParser {
  const MacosArpTableParser();

  List<ArpEntry> parse(String raw) {
    final entries = <ArpEntry>[];
    for (final line in raw.split('\n')) {
      final match = _arpLinePattern.firstMatch(line.trim());
      if (match == null) continue;

      final address = Ipv4Address.tryParse(match.group(1)!);
      if (address == null) continue;

      final macRaw = match.group(2)!;
      if (macRaw == '(incomplete)') continue;
      final mac = normalizeMacAddress(macRaw);
      if (mac == null) continue;

      entries.add(
        ArpEntry(
          ipAddress: address,
          macAddress: mac,
          interfaceName: match.group(3),
        ),
      );
    }
    return entries;
  }
}
