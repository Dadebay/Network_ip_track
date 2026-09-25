import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/cidr.dart';
import 'package:network_monitor/features/devices/application/device_tree.dart';
import 'package:network_monitor/features/devices/domain/entities/device_type.dart';
import 'package:network_monitor/features/network_scope/domain/entities/accessible_subnet.dart';
import 'package:network_monitor/features/network_scope/domain/entities/subnet_reachability.dart';

import '../../../fixtures/fakes/device_factory.dart';

void main() {
  final subnets = [
    AccessibleSubnet(
      cidr: Cidr.parse('172.16.14.0/24'),
      reachability: SubnetReachability.directlyConnected,
    ),
    AccessibleSubnet(
      cidr: Cidr.parse('172.16.20.0/24'),
      reachability: SubnetReachability.routed,
    ),
    AccessibleSubnet(
      cidr: Cidr.parse('172.20.0.0/16'),
      reachability: SubnetReachability.unreachable,
    ),
  ];
  final devices = [
    makeDevice(
      1,
      '172.16.14.254',
      isGateway: true,
      type: DeviceType.routerGateway,
    ),
    makeDevice(2, '172.16.14.12', type: DeviceType.phone),
    makeDevice(3, '172.16.14.26', type: DeviceType.mac, isLocalDevice: true),
    makeDevice(4, '172.16.14.40'),
    makeDevice(5, '172.16.30.7'),
    makeDevice(6, '192.168.1.10'),
  ];

  test(
    'matches the spec shape: block > subnet > gateway > groups > devices',
    () {
      final roots = buildDeviceTree(devices: devices, subnets: subnets);

      expect(roots, hasLength(2));
      final block = roots.first as BlockTreeNode;
      expect(block.cidr.toString(), '172.16.0.0/12');
      expect(block.children.map((n) => (n as SubnetTreeNode).cidr.toString()), [
        '172.16.14.0/24',
        '172.16.20.0/24',
        '172.16.30.0/24', // known only from device history
        '172.20.0.0/16',
      ]);

      final local = block.children.first as SubnetTreeNode;
      expect(local.reachability, SubnetReachability.directlyConnected);
      expect(local.deviceCount, 4);
      final gateway = local.children.single as GatewayTreeNode;
      expect(gateway.device.id, 1);
      final groups = gateway.children.cast<GroupTreeNode>();
      expect(groups.map((g) => g.group), [
        DeviceGroup.phones,
        DeviceGroup.computers,
        DeviceGroup.unknown,
      ]);
      expect(groups.map((g) => g.count), [1, 1, 1]);

      final history = block.children[2] as SubnetTreeNode;
      expect(history.reachability, isNull);
      final unreachable = block.children.last as SubnetTreeNode;
      expect(unreachable.reachability, SubnetReachability.unreachable);
      expect(unreachable.deviceCount, 0);

      // Outside 172.16.0.0/12: its own top-level node.
      final outside = roots.last as SubnetTreeNode;
      expect(outside.cidr.toString(), '192.168.1.0/24');
    },
  );

  test('groups start closed; blocks/subnets/gateways start open', () {
    final roots = buildDeviceTree(devices: devices, subnets: subnets);
    final rows = flattenDeviceTree(roots, const {});

    expect(rows.first.depth, 0);
    expect(rows.first.node, isA<BlockTreeNode>());
    expect(rows.first.isExpanded, isTrue);

    // No device leaves visible: every group is collapsed by default.
    expect(
      rows.whereType<DeviceTreeRow>().where((r) => r.node is DeviceLeafNode),
      isEmpty,
    );

    final localSubnetRow = rows.firstWhere(
      (r) => r.node.id == 'subnet:172.16.14.0/24',
    );
    expect(localSubnetRow.isExpanded, isTrue);
    final gatewayRow = rows.firstWhere((r) => r.node is GatewayTreeNode);
    expect(gatewayRow.isExpanded, isTrue);
    final groupRow = rows.firstWhere((r) => r.node is GroupTreeNode);
    expect(groupRow.isExpanded, isFalse);
  });

  test('toggling a group reveals exactly its own devices', () {
    final roots = buildDeviceTree(devices: devices, subnets: subnets);
    final phonesGroupId = flattenDeviceTree(roots, const {})
        .firstWhere(
          (r) =>
              r.node is GroupTreeNode &&
              (r.node as GroupTreeNode).group == DeviceGroup.phones,
        )
        .node
        .id;

    final rows = flattenDeviceTree(roots, {phonesGroupId});
    final phonesRow = rows.firstWhere((r) => r.node.id == phonesGroupId);
    expect(phonesRow.isExpanded, isTrue);

    final visibleLeaves = rows
        .whereType<DeviceTreeRow>()
        .where((r) => r.node is DeviceLeafNode)
        .map((r) => (r.node as DeviceLeafNode).device.id);
    expect(visibleLeaves, [2]); // only the phone
  });

  test('toggle ids are stable across rebuilds with new device data', () {
    final roots = buildDeviceTree(devices: devices, subnets: subnets);
    final all = flattenDeviceTree(roots, const {});

    final rebuilt = buildDeviceTree(devices: devices, subnets: subnets);
    expect(
      flattenDeviceTree(rebuilt, const {}).map((r) => r.node.id),
      all.map((r) => r.node.id),
    );
  });

  test(
    'forceExpanded opens every node regardless of toggles (search behavior)',
    () {
      final roots = buildDeviceTree(devices: devices, subnets: subnets);
      final rows = flattenDeviceTree(
        roots,
        const {},
        forceExpanded: allTreeNodeIds(roots),
      );

      expect(
        rows.whereType<DeviceTreeRow>().where((r) => r.node is DeviceLeafNode),
        hasLength(5),
      );
      expect(rows.every((r) => !r.hasChildren || r.isExpanded), isTrue);
    },
  );

  test('parentId lets a row locate its parent', () {
    final roots = buildDeviceTree(devices: devices, subnets: subnets);
    final rows = flattenDeviceTree(roots, const {});
    final root = rows.first;
    expect(root.parentId, isNull);

    final localSubnetRow = rows.firstWhere(
      (r) => r.node.id == 'subnet:172.16.14.0/24',
    );
    expect(localSubnetRow.parentId, root.node.id);
  });
}
