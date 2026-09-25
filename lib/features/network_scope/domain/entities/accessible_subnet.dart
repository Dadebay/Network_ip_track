import '../../../../core/utils/cidr.dart';
import '../../../../core/utils/ipv4_address.dart';
import 'subnet_reachability.dart';

/// A private `172.16.0.0/12` subnet the app has determined is reachable (or
/// explicitly not reachable) from this Mac, derived from the route table.
class AccessibleSubnet {
  const AccessibleSubnet({
    required this.cidr,
    required this.reachability,
    this.viaInterface,
    this.gateway,
  });

  final Cidr cidr;
  final SubnetReachability reachability;
  final String? viaInterface;
  final Ipv4Address? gateway;

  @override
  bool operator ==(Object other) =>
      other is AccessibleSubnet &&
      other.cidr == cidr &&
      other.reachability == reachability &&
      other.viaInterface == viaInterface &&
      other.gateway == gateway;

  @override
  int get hashCode => Object.hash(cidr, reachability, viaInterface, gateway);

  @override
  String toString() =>
      'AccessibleSubnet($cidr, $reachability, via $viaInterface)';
}
