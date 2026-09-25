import '../../../../core/errors/app_failure.dart';
import '../../../../core/platform/mac_process_runner.dart';
import '../../domain/entities/route_entry.dart';
import '../../domain/repositories/route_provider.dart';
import 'macos_route_table_parser.dart';

/// [RouteProvider] backed by macOS `netstat -rn -f inet`.
class MacosRouteProvider implements RouteProvider {
  const MacosRouteProvider({
    this.processRunner = const MacProcessRunner(),
    this.parser = const MacosRouteTableParser(),
  });

  final MacProcessRunner processRunner;
  final MacosRouteTableParser parser;

  @override
  Future<List<RouteEntry>> getRouteTable() async {
    final result = await processRunner.run('netstat', ['-rn', '-f', 'inet']);
    if (!result.succeeded) {
      throw RouteTableUnavailableFailure(
        technicalDetail:
            'netstat -rn -f inet exited with ${result.exitCode}: ${result.stderr}',
      );
    }
    return parser.parse(result.stdout);
  }
}
