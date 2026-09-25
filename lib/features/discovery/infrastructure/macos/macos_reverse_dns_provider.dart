import '../../../../core/platform/mac_process_runner.dart';
import '../../../../core/utils/ipv4_address.dart';
import '../../domain/repositories/reverse_dns_provider.dart';
import 'macos_dscacheutil_parser.dart';

/// [ReverseDnsProvider] backed by macOS `dscacheutil`, the system directory
/// service cache — always present (unlike `dig`, which needs Xcode Command
/// Line Tools) and backed by the same resolver mDNSResponder uses.
class MacosReverseDnsProvider implements ReverseDnsProvider {
  const MacosReverseDnsProvider({
    this.processRunner = const MacProcessRunner(),
  });

  final MacProcessRunner processRunner;

  @override
  Future<String?> lookup(
    Ipv4Address address, {
    required Duration timeout,
  }) async {
    final result = await processRunner.run('dscacheutil', [
      '-q',
      'host',
      '-a',
      'ip_address',
      address.toString(),
    ], timeout: timeout);
    if (!result.succeeded) return null;
    return parseDscacheutilHostName(result.stdout);
  }
}
