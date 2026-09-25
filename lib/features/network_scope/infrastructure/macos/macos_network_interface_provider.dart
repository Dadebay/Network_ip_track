import '../../../../core/platform/mac_process_runner.dart';
import '../../domain/entities/interface_kind.dart';
import '../../domain/entities/network_interface_info.dart';
import '../../domain/repositories/network_interface_provider.dart';
import 'macos_default_route_parser.dart';
import 'macos_hardware_port_parser.dart';
import 'macos_ifconfig_parser.dart';

const _vpnPrefixes = ['utun', 'ppp', 'ipsec', 'gif', 'stf'];
const _virtualPrefixes = ['awdl', 'llw', 'anpi', 'ap', 'vmenet'];

/// [NetworkInterfaceProvider] backed by macOS `ifconfig`,
/// `route -n get default` and `networksetup -listallhardwareports`.
class MacosNetworkInterfaceProvider implements NetworkInterfaceProvider {
  const MacosNetworkInterfaceProvider({
    this.processRunner = const MacProcessRunner(),
  });

  final MacProcessRunner processRunner;

  @override
  Future<List<NetworkInterfaceInfo>> listInterfaces() async {
    final ifconfigResult = await processRunner.run('ifconfig', const []);
    final parsedInterfaces = ifconfigResult.succeeded
        ? parseIfconfigOutput(ifconfigResult.stdout)
        : const [];

    final hardwarePortsResult = await processRunner.run('networksetup', const [
      '-listallhardwareports',
    ]);
    final hardwarePorts = hardwarePortsResult.succeeded
        ? parseHardwarePorts(hardwarePortsResult.stdout)
        : const <String, String>{};

    final defaultRouteResult = await processRunner.run('route', const [
      '-n',
      'get',
      'default',
    ]);
    final defaultRoute = defaultRouteResult.succeeded
        ? parseDefaultRouteOutput(defaultRouteResult.stdout)
        : const ParsedDefaultRoute(interfaceName: null);

    final interfaces = <NetworkInterfaceInfo>[];
    for (final parsed in parsedInterfaces) {
      final address = parsed.inetAddress;
      final netmask = parsed.netmask;
      if (address == null || netmask == null) continue;

      final hardwarePortName = hardwarePorts[parsed.name];
      final kind = _classify(parsed.name, hardwarePortName, parsed.isLoopback);
      final isDefaultRoute = defaultRoute.interfaceName == parsed.name;

      interfaces.add(
        NetworkInterfaceInfo(
          name: parsed.name,
          displayName: hardwarePortName ?? parsed.name,
          kind: kind,
          address: address,
          subnetMask: netmask,
          isDefaultRoute: isDefaultRoute,
          gatewayAddress: isDefaultRoute ? defaultRoute.gateway : null,
        ),
      );
    }

    return interfaces;
  }

  InterfaceKind _classify(
    String name,
    String? hardwarePortName,
    bool isLoopback,
  ) {
    if (isLoopback || name.startsWith('lo')) return InterfaceKind.loopback;
    if (_vpnPrefixes.any(name.startsWith)) return InterfaceKind.vpn;
    if (name.startsWith('bridge')) return InterfaceKind.bridge;
    if (_virtualPrefixes.any(name.startsWith)) return InterfaceKind.virtual;

    final port = hardwarePortName?.toLowerCase();
    if (port != null) {
      if (port.contains('wi-fi') || port.contains('wifi')) {
        return InterfaceKind.wifi;
      }
      if (port.contains('ethernet') || port.contains('thunderbolt')) {
        return InterfaceKind.ethernet;
      }

      // USB and third-party wired adapters often expose a product name (for
      // example `SZNX.10/100`) instead of including the word "Ethernet".
      // A BSD `en*` device that macOS lists as a hardware port is still a
      // physical network candidate unless it matched a virtual kind above.
      if (name.startsWith('en')) return InterfaceKind.ethernet;
    }
    return InterfaceKind.other;
  }
}
