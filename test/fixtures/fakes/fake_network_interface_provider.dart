import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/network_scope/domain/entities/interface_kind.dart';
import 'package:network_monitor/features/network_scope/domain/entities/network_interface_info.dart';
import 'package:network_monitor/features/network_scope/domain/repositories/network_interface_provider.dart';

/// Canned interface list matching the example from the spec
/// (172.16.14.26/24, gateway 172.16.14.254) — used so widget/integration
/// tests never spawn real macOS network commands.
class FakeNetworkInterfaceProvider implements NetworkInterfaceProvider {
  const FakeNetworkInterfaceProvider();

  @override
  Future<List<NetworkInterfaceInfo>> listInterfaces() async {
    return [
      NetworkInterfaceInfo(
        name: 'en0',
        displayName: 'Wi-Fi',
        kind: InterfaceKind.wifi,
        address: Ipv4Address.parse('172.16.14.26'),
        subnetMask: Ipv4Address.parse('255.255.255.0'),
        isDefaultRoute: true,
        gatewayAddress: Ipv4Address.parse('172.16.14.254'),
      ),
    ];
  }
}
