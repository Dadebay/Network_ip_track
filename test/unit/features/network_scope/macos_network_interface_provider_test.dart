import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/platform/mac_process_runner.dart';
import 'package:network_monitor/features/network_scope/domain/entities/interface_kind.dart';
import 'package:network_monitor/features/network_scope/infrastructure/macos/macos_network_interface_provider.dart';

class _ActualAdapterFixtureRunner extends MacProcessRunner {
  const _ActualAdapterFixtureRunner();

  @override
  Future<MacProcessResult> run(
    String executable,
    List<String> arguments, {
    Duration? timeout,
  }) async {
    return switch (executable) {
      'ifconfig' => const MacProcessResult(
        exitCode: 0,
        stdout: '''
en12: flags=8863<UP,BROADCAST,SMART,RUNNING,SIMPLEX,MULTICAST> mtu 1500
\tether 00:aa:34:58:89:0a
\tinet 172.16.14.26 netmask 0xffffff00 broadcast 172.16.14.255
\tstatus: active
utun74: flags=8051<UP,POINTOPOINT,RUNNING,MULTICAST> mtu 1500
\tinet 198.18.0.1 --> 198.18.0.1 netmask 0xffff0000
''',
        stderr: '',
      ),
      'networksetup' => const MacProcessResult(
        exitCode: 0,
        stdout: '''
Hardware Port: SZNX.10/100
Device: en12
Ethernet Address: 00:aa:34:58:89:0a
''',
        stderr: '',
      ),
      'route' => const MacProcessResult(
        exitCode: 0,
        stdout: '''
   route to: default
destination: default
       mask: default
  interface: utun74
''',
        stderr: '',
      ),
      _ => MacProcessResult(
        exitCode: 1,
        stdout: '',
        stderr: 'Unexpected executable: $executable',
      ),
    };
  }
}

void main() {
  test(
    'treats a named en hardware port as physical ethernet behind a VPN',
    () async {
      final provider = MacosNetworkInterfaceProvider(
        processRunner: const _ActualAdapterFixtureRunner(),
      );

      final interfaces = await provider.listInterfaces();
      final adapter = interfaces.singleWhere((item) => item.name == 'en12');

      expect(adapter.displayName, 'SZNX.10/100');
      expect(adapter.kind, InterfaceKind.ethernet);
      expect(adapter.isDefaultRoute, isFalse);
    },
  );
}
