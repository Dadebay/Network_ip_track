import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/devices/application/device_graph.dart';
import 'package:network_monitor/features/devices/application/device_tree.dart';
import 'package:network_monitor/features/devices/domain/entities/device_type.dart';

import '../../../fixtures/fakes/device_factory.dart';

void main() {
  final devices = [
    makeDevice(
      1,
      '172.16.14.254',
      isGateway: true,
      type: DeviceType.routerGateway,
    ),
    for (var i = 2; i < 12; i++)
      makeDevice(i, '172.16.14.$i', type: DeviceType.camera),
    for (var i = 12; i < 20; i++)
      makeDevice(i, '172.16.14.$i', type: DeviceType.windowsComputer),
  ];

  test(
    'mirrors the tree: hubs, groups and every device, linked to parents',
    () {
      final graph = buildDeviceGraph(
        buildDeviceTree(devices: devices, subnets: const []),
      );
      final kinds = graph.nodes.map((n) => n.kind).toList();
      expect(kinds.where((k) => k == GraphNodeKind.gateway), hasLength(1));
      expect(kinds.where((k) => k == GraphNodeKind.group), hasLength(2));
      expect(kinds.where((k) => k == GraphNodeKind.device), hasLength(18));
      // A tree: every node but the root has exactly one parent edge.
      expect(graph.edges, hasLength(graph.nodes.length - 1));
    },
  );

  test('the force layout settles and keeps devices apart', () {
    final graph = buildDeviceGraph(
      buildDeviceTree(devices: devices, subnets: const []),
    );
    final layout = ForceLayout(graph);
    var steps = 0;
    while (!layout.settled && steps++ < 2000) {
      layout.step();
    }
    expect(layout.settled, isTrue);
    final points = [
      for (final node in graph.nodes)
        if (node.kind == GraphNodeKind.device) (node.x, node.y),
    ];
    for (var i = 0; i < points.length; i++) {
      for (var j = i + 1; j < points.length; j++) {
        final dx = points[i].$1 - points[j].$1;
        final dy = points[i].$2 - points[j].$2;
        expect(dx * dx + dy * dy, greaterThan(4 * 4));
      }
    }
  });
}
