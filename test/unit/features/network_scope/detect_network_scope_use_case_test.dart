import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/errors/app_failure.dart';
import 'package:network_monitor/core/utils/cidr.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/network_scope/application/detect_network_scope_use_case.dart';
import 'package:network_monitor/features/network_scope/domain/entities/interface_kind.dart';
import 'package:network_monitor/features/network_scope/domain/entities/network_interface_info.dart';
import 'package:network_monitor/features/network_scope/domain/entities/route_entry.dart';
import 'package:network_monitor/features/network_scope/domain/repositories/network_interface_provider.dart';
import 'package:network_monitor/features/network_scope/domain/repositories/route_provider.dart';

class _StubInterfaceProvider implements NetworkInterfaceProvider {
  _StubInterfaceProvider(this.interfaces);
  final List<NetworkInterfaceInfo> interfaces;

  @override
  Future<List<NetworkInterfaceInfo>> listInterfaces() async => interfaces;
}

class _StubRouteProvider implements RouteProvider {
  _StubRouteProvider([this.routes = const []]);

  final List<RouteEntry> routes;

  @override
  Future<List<RouteEntry>> getRouteTable() async => routes;
}

NetworkInterfaceInfo _wifi({required bool isDefaultRoute}) =>
    NetworkInterfaceInfo(
      name: 'en0',
      displayName: 'Wi-Fi',
      kind: InterfaceKind.wifi,
      address: Ipv4Address.parse('172.16.14.26'),
      subnetMask: Ipv4Address.parse('255.255.255.0'),
      isDefaultRoute: isDefaultRoute,
      gatewayAddress: isDefaultRoute
          ? Ipv4Address.parse('172.16.14.254')
          : null,
    );

NetworkInterfaceInfo _vpn({required bool isDefaultRoute}) =>
    NetworkInterfaceInfo(
      name: 'utun74',
      displayName: 'utun74',
      kind: InterfaceKind.vpn,
      address: Ipv4Address.parse('198.18.0.1'),
      subnetMask: Ipv4Address.parse('255.255.0.0'),
      isDefaultRoute: isDefaultRoute,
    );

void main() {
  test(
    'uses the physical interface directly when it carries the default route',
    () async {
      final useCase = DetectNetworkScopeUseCase(
        interfaceProvider: _StubInterfaceProvider([
          _wifi(isDefaultRoute: true),
        ]),
        routeProvider: _StubRouteProvider(),
      );

      final snapshot = await useCase();

      expect(snapshot.activeInterface?.name, 'en0');
      expect(snapshot.defaultRouteViaVpn, isFalse);
    },
  );

  test(
    'falls back to the sole physical interface when the default route is a VPN tunnel',
    () async {
      final useCase = DetectNetworkScopeUseCase(
        interfaceProvider: _StubInterfaceProvider([
          _wifi(isDefaultRoute: false),
          _vpn(isDefaultRoute: true),
        ]),
        routeProvider: _StubRouteProvider(),
      );

      final snapshot = await useCase();

      expect(snapshot.activeInterface?.name, 'en0');
      expect(snapshot.defaultRouteViaVpn, isTrue);
    },
  );

  test(
    'resolves the physical gateway from its scoped default route behind a VPN',
    () async {
      final useCase = DetectNetworkScopeUseCase(
        interfaceProvider: _StubInterfaceProvider([
          _wifi(isDefaultRoute: false),
          _vpn(isDefaultRoute: true),
        ]),
        routeProvider: _StubRouteProvider([
          RouteEntry(
            destination: Cidr.parse('0.0.0.0/0'),
            interfaceName: 'en0',
            isDefault: true,
            isDirectlyConnected: false,
            rawFlags: 'UGScIg',
            gateway: Ipv4Address.parse('172.16.14.254'),
          ),
        ]),
      );

      final snapshot = await useCase();

      expect(
        snapshot.activeInterface?.gatewayAddress,
        Ipv4Address.parse('172.16.14.254'),
      );
      expect(snapshot.defaultRouteViaVpn, isTrue);
    },
  );

  test(
    'throws AmbiguousDefaultRouteFailure with multiple physical interfaces and a non-physical default route',
    () async {
      final wifi = _wifi(isDefaultRoute: false);
      final secondPhysical = NetworkInterfaceInfo(
        name: 'en5',
        displayName: 'Ethernet',
        kind: InterfaceKind.ethernet,
        address: Ipv4Address.parse('172.16.14.40'),
        subnetMask: Ipv4Address.parse('255.255.255.0'),
        isDefaultRoute: false,
      );
      final useCase = DetectNetworkScopeUseCase(
        interfaceProvider: _StubInterfaceProvider([
          wifi,
          secondPhysical,
          _vpn(isDefaultRoute: true),
        ]),
        routeProvider: _StubRouteProvider(),
      );

      expect(useCase.call, throwsA(isA<AmbiguousDefaultRouteFailure>()));
    },
  );

  test(
    'throws NoActiveNetworkInterfaceFailure when nothing physical is available',
    () async {
      final useCase = DetectNetworkScopeUseCase(
        interfaceProvider: _StubInterfaceProvider([_vpn(isDefaultRoute: true)]),
        routeProvider: _StubRouteProvider(),
      );

      expect(useCase.call, throwsA(isA<NoActiveNetworkInterfaceFailure>()));
    },
  );
}
