import '../../../../core/platform/mac_process_runner.dart';
import '../../../../core/utils/ipv4_address.dart';
import '../../domain/entities/arp_entry.dart';
import '../../domain/repositories/arp_table_provider.dart';
import 'macos_arp_table_parser.dart';

/// [ArpTableProvider] backed by macOS `arp`.
class MacosArpTableProvider implements ArpTableProvider {
  const MacosArpTableProvider({
    this.processRunner = const MacProcessRunner(),
    this.parser = const MacosArpTableParser(),
  });

  final MacProcessRunner processRunner;
  final MacosArpTableParser parser;

  @override
  Future<List<ArpEntry>> getArpTable() async {
    final result = await processRunner.run('arp', const [
      '-a',
      '-n',
    ], timeout: const Duration(seconds: 5));
    if (!result.succeeded) return const [];
    return parser.parse(result.stdout);
  }

  @override
  Future<ArpEntry?> lookup(Ipv4Address address) async {
    final result = await processRunner.run('arp', [
      '-n',
      address.toString(),
    ], timeout: const Duration(seconds: 2));
    if (!result.succeeded) return null;
    final entries = parser.parse(result.stdout);
    for (final entry in entries) {
      if (entry.ipAddress == address) return entry;
    }
    return null;
  }
}
