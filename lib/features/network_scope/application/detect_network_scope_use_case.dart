import '../../../core/errors/app_failure.dart';
import '../../../core/utils/ipv4_address.dart';
import '../domain/entities/interface_kind.dart';
import '../domain/entities/network_interface_info.dart';
import '../domain/entities/network_scope_snapshot.dart';
import '../domain/entities/route_entry.dart';
import '../domain/repositories/network_interface_provider.dart';
import '../domain/repositories/route_provider.dart';
import 'derive_accessible_subnets.dart';

/// Detects this Mac's active network and the private `172.16.0.0/12`
/// subnets it can currently reach.
class DetectNetworkScopeUseCase {
  const DetectNetworkScopeUseCase({
    required NetworkInterfaceProvider interfaceProvider,
    required RouteProvider routeProvider,
  }) : _interfaceProvider = interfaceProvider,
       _routeProvider = routeProvider;

  final NetworkInterfaceProvider _interfaceProvider;
  final RouteProvider _routeProvider;

  Future<NetworkScopeSnapshot> call() async {
    final interfaces = await _interfaceProvider.listInterfaces();
    if (interfaces.isEmpty) {
      throw NoActiveNetworkInterfaceFailure(
        technicalDetail: 'listInterfaces() bir IPv4 arayüzü döndürmedi.',
      );
    }

    final defaultRouteInterfaces = interfaces
        .where((interface) => interface.isDefaultRoute)
        .toList();
    if (defaultRouteInterfaces.length > 1) {
      throw AmbiguousDefaultRouteFailure(
        technicalDetail:
            'Birden fazla arayüz varsayılan route taşıyor: ${defaultRouteInterfaces.map((i) => i.name).join(', ')}',
      );
    }
    final defaultRouteInterface = defaultRouteInterfaces.isEmpty
        ? null
        : defaultRouteInterfaces.single;

    final routes = await _routeProvider.getRouteTable();
    final accessibleSubnets = deriveAccessibleSubnets(routes);

    final (selectedInterface, defaultRouteViaVpn) = _selectActiveInterface(
      interfaces,
      defaultRouteInterface,
    );
    if (selectedInterface == null) {
      throw NoActiveNetworkInterfaceFailure(
        technicalDetail:
            'Ne varsayılan route ne de fiziksel bir arayüz bulunamadı.',
      );
    }

    final activeInterface = _withResolvedGateway(selectedInterface, routes);

    return NetworkScopeSnapshot(
      interfaces: interfaces,
      activeInterface: activeInterface,
      defaultRouteViaVpn: defaultRouteViaVpn,
      accessibleSubnets: accessibleSubnets,
      detectedAt: DateTime.now(),
    );
  }

  /// A full-tunnel VPN owns `route get default`, so the interface provider
  /// cannot attach the LAN gateway to the physical fallback. The complete
  /// route table still contains the physical interface's scoped default route
  /// (for example `default 172.16.14.254 ... en12`). Enrich the selected
  /// interface from that entry without making infrastructure concerns leak
  /// into the presentation layer.
  NetworkInterfaceInfo _withResolvedGateway(
    NetworkInterfaceInfo interface,
    List<RouteEntry> routes,
  ) {
    if (interface.gatewayAddress != null) return interface;

    Ipv4Address? gateway;
    for (final route in routes) {
      if (route.isDefault &&
          route.interfaceName == interface.name &&
          route.gateway != null) {
        gateway = route.gateway;
        break;
      }
    }
    if (gateway == null) return interface;

    return NetworkInterfaceInfo(
      name: interface.name,
      displayName: interface.displayName,
      kind: interface.kind,
      address: interface.address,
      subnetMask: interface.subnetMask,
      isDefaultRoute: interface.isDefaultRoute,
      gatewayAddress: gateway,
    );
  }

  /// Prefers the physical (Wi-Fi/Ethernet) default-route interface. When the
  /// default route instead goes through a VPN tunnel, falls back to the sole
  /// physical interface so a full-tunnel VPN doesn't hide the LAN the user is
  /// actually plugged into. With more than one physical candidate and an
  /// unclear default route, this is genuinely ambiguous and must be resolved
  /// by the user rather than guessed.
  (NetworkInterfaceInfo?, bool) _selectActiveInterface(
    List<NetworkInterfaceInfo> interfaces,
    NetworkInterfaceInfo? defaultRouteInterface,
  ) {
    if (defaultRouteInterface != null &&
        defaultRouteInterface.kind.isPhysicalCandidate) {
      return (defaultRouteInterface, false);
    }

    final physicalInterfaces = interfaces
        .where((interface) => interface.kind.isPhysicalCandidate)
        .toList();
    final defaultRouteViaVpn = defaultRouteInterface?.kind == InterfaceKind.vpn;

    if (physicalInterfaces.length == 1) {
      return (physicalInterfaces.single, defaultRouteViaVpn);
    }
    if (physicalInterfaces.length > 1) {
      throw AmbiguousDefaultRouteFailure(
        technicalDetail:
            'Varsayılan route fiziksel değil ve birden fazla fiziksel arayüz var: '
            '${physicalInterfaces.map((i) => i.name).join(', ')}',
      );
    }
    return (null, defaultRouteViaVpn);
  }
}
