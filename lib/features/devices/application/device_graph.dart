import 'dart:math';

import '../domain/entities/device.dart';
import 'device_tree.dart';

enum GraphNodeKind { block, subnet, gateway, group, device }

class GraphNode {
  GraphNode({
    required this.id,
    required this.kind,
    required this.label,
    this.device,
    this.group,
  });

  final String id;
  final GraphNodeKind kind;
  final String label;
  final Device? device;

  /// The device group this node belongs to (group hubs and devices).
  final DeviceGroup? group;

  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;

  double get radius => switch (kind) {
    GraphNodeKind.block => 16,
    GraphNodeKind.subnet => 13,
    GraphNodeKind.gateway => 12,
    GraphNodeKind.group => 9,
    GraphNodeKind.device => 5.5,
  };

  /// Repulsion strength: hubs push harder so clusters spread out.
  double get charge => switch (kind) {
    GraphNodeKind.device => 1,
    GraphNodeKind.group => 3,
    _ => 5,
  };
}

class GraphEdge {
  const GraphEdge(this.source, this.target, this.length);

  final int source;
  final int target;

  /// Rest length of the spring.
  final double length;
}

class DeviceGraph {
  DeviceGraph(this.nodes, this.edges)
    : neighbors = List.generate(nodes.length, (_) => <int>{}) {
    for (final edge in edges) {
      neighbors[edge.source].add(edge.target);
      neighbors[edge.target].add(edge.source);
    }
  }

  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final List<Set<int>> neighbors;
}

/// The device tree as a node-link graph: block → subnets → gateway →
/// type groups → devices. Initial positions are a radial layout around
/// each parent, so the force layout starts close to its final shape.
DeviceGraph buildDeviceGraph(List<DeviceTreeNode> roots) {
  final nodes = <GraphNode>[];
  final edges = <GraphEdge>[];

  int add(GraphNode node, int? parent, double length) {
    nodes.add(node);
    final index = nodes.length - 1;
    if (parent != null) edges.add(GraphEdge(parent, index, length));
    return index;
  }

  void visit(DeviceTreeNode node, int? parent, int siblings) {
    final (graphNode, length) = switch (node) {
      BlockTreeNode(:final cidr) => (
        GraphNode(
          id: node.id,
          kind: GraphNodeKind.block,
          label: cidr.toString(),
        ),
        0.0,
      ),
      SubnetTreeNode(:final cidr) => (
        GraphNode(
          id: node.id,
          kind: GraphNodeKind.subnet,
          label: cidr.toString(),
        ),
        200.0,
      ),
      GatewayTreeNode(:final device) => (
        GraphNode(
          id: node.id,
          kind: GraphNodeKind.gateway,
          label: 'Gateway ${device.currentIp}',
          device: device,
        ),
        70.0,
      ),
      GroupTreeNode(:final group, :final count) => (
        GraphNode(
          id: node.id,
          kind: GraphNodeKind.group,
          label: '${group.label} ($count)',
          group: group,
        ),
        110.0 + sqrt(count) * 6,
      ),
      DeviceLeafNode(:final device) => (
        GraphNode(
          id: node.id,
          kind: GraphNodeKind.device,
          label: device.hasName ? device.displayName : '${device.currentIp}',
          device: device,
          group: DeviceGroup.of(device.effectiveType),
        ),
        30.0 + sqrt(siblings) * 5,
      ),
    };
    final index = add(graphNode, parent, length);
    for (final child in node.children) {
      visit(child, index, node.children.length);
    }
  }

  for (final root in roots) {
    visit(root, null, roots.length);
  }
  _placeRadially(nodes, edges);
  return DeviceGraph(nodes, edges);
}

void _placeRadially(List<GraphNode> nodes, List<GraphEdge> edges) {
  final children = <int, List<GraphEdge>>{};
  final hasParent = <int>{};
  for (final edge in edges) {
    (children[edge.source] ??= []).add(edge);
    hasParent.add(edge.target);
  }
  final random = Random(7);

  void place(int index, double angle, double spread) {
    final kids = children[index] ?? const [];
    for (final (i, edge) in kids.indexed) {
      final childAngle = kids.length == 1
          ? angle
          : angle - spread / 2 + spread * (i + 0.5) / kids.length;
      final child = nodes[edge.target];
      final distance = nodes[edge.target].kind == GraphNodeKind.device
          ? edge.length * (1 + random.nextDouble())
          : edge.length;
      child
        ..x = nodes[index].x + cos(childAngle) * distance
        ..y = nodes[index].y + sin(childAngle) * distance;
      final isHub = child.kind != GraphNodeKind.device;
      place(
        edge.target,
        childAngle,
        isHub && kids.length > 1 ? pi * 1.2 : 2 * pi,
      );
    }
  }

  final roots = [
    for (var i = 0; i < nodes.length; i++)
      if (!hasParent.contains(i)) i,
  ];
  for (final (i, root) in roots.indexed) {
    nodes[root]
      ..x = (i - (roots.length - 1) / 2) * 600
      ..y = 0;
    place(root, -pi / 2, 2 * pi);
  }
}

/// A small d3-force style simulation: pairwise repulsion, edge springs and
/// a weak pull to the center, cooled by [alpha] until it settles.
class ForceLayout {
  ForceLayout(this.graph);

  final DeviceGraph graph;
  double alpha = 1;

  static const _repulsion = 900.0;
  static const _spring = 0.08;
  static const _gravity = 0.004;
  static const _damping = 0.6;
  static const _maxStep = 40.0;

  bool get settled => alpha < 0.02;

  void step() {
    final nodes = graph.nodes;
    final n = nodes.length;
    for (var i = 0; i < n; i++) {
      final a = nodes[i];
      for (var j = i + 1; j < n; j++) {
        final b = nodes[j];
        var dx = a.x - b.x;
        var dy = a.y - b.y;
        var distanceSquared = dx * dx + dy * dy;
        if (distanceSquared < 1) {
          dx = (i - j) * 0.1;
          dy = 0.1;
          distanceSquared = dx * dx + dy * dy;
        }
        // Far-apart pairs barely interact; skipping them keeps big maps
        // fast without visibly changing the layout.
        if (distanceSquared > 250000) continue;
        final distance = sqrt(distanceSquared);
        final force = _repulsion * a.charge * b.charge / distanceSquared;
        final fx = dx / distance * force;
        final fy = dy / distance * force;
        a
          ..vx += fx / a.charge
          ..vy += fy / a.charge;
        b
          ..vx -= fx / b.charge
          ..vy -= fy / b.charge;
      }
    }
    for (final edge in graph.edges) {
      final a = nodes[edge.source];
      final b = nodes[edge.target];
      final dx = b.x - a.x;
      final dy = b.y - a.y;
      final distance = max(sqrt(dx * dx + dy * dy), 0.01);
      final force = _spring * (distance - edge.length);
      final fx = dx / distance * force;
      final fy = dy / distance * force;
      // Hubs move less than leaves, keeping the overall structure stable.
      final aShare = b.charge / (a.charge + b.charge);
      a
        ..vx += fx * aShare
        ..vy += fy * aShare;
      b
        ..vx -= fx * (1 - aShare)
        ..vy -= fy * (1 - aShare);
    }
    for (final node in nodes) {
      node
        ..vx -= node.x * _gravity
        ..vy -= node.y * _gravity;
      final dx = (node.vx * alpha).clamp(-_maxStep, _maxStep);
      final dy = (node.vy * alpha).clamp(-_maxStep, _maxStep);
      node
        ..x += dx
        ..y += dy
        ..vx *= _damping
        ..vy *= _damping;
    }
    alpha *= 0.985;
  }
}
