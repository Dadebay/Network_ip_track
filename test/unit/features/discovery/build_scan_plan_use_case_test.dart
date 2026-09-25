import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/errors/app_failure.dart';
import 'package:network_monitor/core/utils/cidr.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/discovery/application/build_scan_plan_use_case.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_scope_type.dart';
import 'package:network_monitor/features/network_scope/domain/entities/accessible_subnet.dart';
import 'package:network_monitor/features/network_scope/domain/entities/interface_kind.dart';
import 'package:network_monitor/features/network_scope/domain/entities/network_interface_info.dart';
import 'package:network_monitor/features/network_scope/domain/entities/network_scope_snapshot.dart';
import 'package:network_monitor/features/network_scope/domain/entities/subnet_reachability.dart';

NetworkInterfaceInfo _activeInterface() => NetworkInterfaceInfo(
  name: 'en0',
  displayName: 'Wi-Fi',
  kind: InterfaceKind.wifi,
  address: Ipv4Address.parse('172.16.14.26'),
  subnetMask: Ipv4Address.parse('255.255.255.0'),
  isDefaultRoute: true,
  gatewayAddress: Ipv4Address.parse('172.16.14.254'),
);

void main() {
  const useCase = BuildScanPlanUseCase();

  test('currentSubnet scope targets exactly the active interface CIDR', () {
    final snapshot = NetworkScopeSnapshot(
      interfaces: [_activeInterface()],
      activeInterface: _activeInterface(),
      accessibleSubnets: const [],
      detectedAt: DateTime(2026, 1, 1),
    );

    final plan = useCase(
      scopeType: ScanScopeType.currentSubnet,
      networkScope: snapshot,
    );

    expect(plan.chunks.map((c) => c.cidr.toString()).toList(), [
      '172.16.14.0/24',
    ]);
    expect(plan.totalCandidateHosts, 254);
    expect(plan.totalAddresses, 256);
  });

  test('currentSubnet scope throws when there is no active interface', () {
    final snapshot = NetworkScopeSnapshot(
      interfaces: const [],
      accessibleSubnets: const [],
      detectedAt: DateTime(2026, 1, 1),
    );

    expect(
      () => useCase(
        scopeType: ScanScopeType.currentSubnet,
        networkScope: snapshot,
      ),
      throwsA(isA<InvalidScanScopeFailure>()),
    );
  });

  test('allAccessiblePrivate172 scope targets every accessible subnet', () {
    final snapshot = NetworkScopeSnapshot(
      interfaces: [_activeInterface()],
      activeInterface: _activeInterface(),
      accessibleSubnets: [
        AccessibleSubnet(
          cidr: Cidr.parse('172.16.14.0/24'),
          reachability: SubnetReachability.directlyConnected,
        ),
        AccessibleSubnet(
          cidr: Cidr.parse('172.16.20.0/24'),
          reachability: SubnetReachability.routed,
        ),
      ],
      detectedAt: DateTime(2026, 1, 1),
    );

    final plan = useCase(
      scopeType: ScanScopeType.allAccessiblePrivate172,
      networkScope: snapshot,
    );

    expect(plan.chunks.map((c) => c.cidr.toString()).toList(), [
      '172.16.14.0/24',
      '172.16.20.0/24',
    ]);
  });

  test('customCidr scope rejects a CIDR outside 172.16.0.0/12', () {
    final snapshot = NetworkScopeSnapshot(
      interfaces: [_activeInterface()],
      activeInterface: _activeInterface(),
      accessibleSubnets: const [],
      detectedAt: DateTime(2026, 1, 1),
    );

    expect(
      () => useCase(
        scopeType: ScanScopeType.customCidr,
        networkScope: snapshot,
        customCidr: Cidr.parse('10.0.0.0/24'),
      ),
      throwsA(isA<InvalidScanScopeFailure>()),
    );
  });

  test('customCidr scope accepts a CIDR inside 172.16.0.0/12', () {
    final snapshot = NetworkScopeSnapshot(
      interfaces: [_activeInterface()],
      activeInterface: _activeInterface(),
      accessibleSubnets: const [],
      detectedAt: DateTime(2026, 1, 1),
    );

    final plan = useCase(
      scopeType: ScanScopeType.customCidr,
      networkScope: snapshot,
      customCidr: Cidr.parse('172.30.0.0/24'),
    );

    expect(plan.chunks.map((c) => c.cidr.toString()).toList(), [
      '172.30.0.0/24',
    ]);
  });

  test('fullPrivate172Block scope queues all 4096 /24 chunks', () {
    final snapshot = NetworkScopeSnapshot(
      interfaces: [_activeInterface()],
      activeInterface: _activeInterface(),
      accessibleSubnets: const [],
      detectedAt: DateTime(2026, 1, 1),
    );

    final plan = useCase(
      scopeType: ScanScopeType.fullPrivate172Block,
      networkScope: snapshot,
    );

    expect(plan.chunks, hasLength(4096));
    expect(plan.totalAddresses, 1048576);
    // Each /24's network and broadcast address is skipped.
    expect(plan.totalCandidateHosts, 4096 * 254);
  });
}
