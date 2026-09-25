import 'package:network_monitor/core/utils/cidr.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/network_scope/domain/entities/route_entry.dart';
import 'package:network_monitor/features/network_scope/domain/repositories/route_provider.dart';

/// Canned route table used so widget/integration tests never spawn a real
/// `netstat` process or reach the real network.
class FakeRouteProvider implements RouteProvider {
  const FakeRouteProvider();

  @override
  Future<List<RouteEntry>> getRouteTable() async {
    return [
      RouteEntry(
        destination: Cidr.parse('172.16.14.0/24'),
        interfaceName: 'en0',
        isDefault: false,
        isDirectlyConnected: true,
        rawFlags: 'UCS',
      ),
      RouteEntry(
        destination: Cidr.parse('172.16.20.0/24'),
        gateway: Ipv4Address.parse('172.16.14.254'),
        interfaceName: 'en0',
        isDefault: false,
        isDirectlyConnected: false,
        rawFlags: 'UGSc',
      ),
    ];
  }
}

/// A route table like one seen on a real network: the local /24 plus a
/// route for the whole private `172.16.0.0/12` block, which makes the
/// "all accessible private 172 subnets" scope resolve to ~1M addresses.
class FakeWholeBlockRouteProvider implements RouteProvider {
  const FakeWholeBlockRouteProvider();

  @override
  Future<List<RouteEntry>> getRouteTable() async {
    return [
      RouteEntry(
        destination: Cidr.parse('172.16.14.0/24'),
        interfaceName: 'en0',
        isDefault: false,
        isDirectlyConnected: true,
        rawFlags: 'UCS',
      ),
      RouteEntry(
        destination: Cidr.parse('172.16.0.0/12'),
        gateway: Ipv4Address.parse('172.16.14.254'),
        interfaceName: 'en0',
        isDefault: false,
        isDirectlyConnected: false,
        rawFlags: 'UGSc',
      ),
    ];
  }
}
