import '../../../../core/errors/app_failure.dart';
import '../../../../core/platform/mac_process_runner.dart';
import '../../../../core/utils/ipv4_address.dart';
import '../../domain/entities/ping_reply.dart';
import '../../domain/repositories/ping_provider.dart';
import 'macos_ping_parser.dart';

/// [PingProvider] backed by macOS `ping -c 1 -W <ms>`.
///
/// A single echo request only — this is a liveness probe for discovery, not
/// a diagnostic tool, and the spec explicitly requires low-rate probing.
class MacosPingProvider implements PingProvider {
  const MacosPingProvider({this.processRunner = const MacProcessRunner()});

  final MacProcessRunner processRunner;

  @override
  Future<PingReply?> ping(
    Ipv4Address address, {
    required Duration timeout,
  }) async {
    final result = await processRunner.run('ping', [
      '-n',
      '-c',
      '1',
      '-W',
      '${timeout.inMilliseconds}',
      address.toString(),
    ], timeout: timeout + const Duration(seconds: 1));
    if (result.succeeded) {
      return parsePingReply(result.stdout) ?? const PingReply();
    }
    // Exit code 2 is the normal "no reply"; a socket permission error means
    // every probe would silently fail, so surface it instead.
    final stderr = result.stderr.toLowerCase();
    if (stderr.contains('not permitted') ||
        stderr.contains('permission denied')) {
      throw NetworkProbePermissionFailure(
        technicalDetail: 'ping exit ${result.exitCode}: ${result.stderr}',
      );
    }
    return null;
  }
}
