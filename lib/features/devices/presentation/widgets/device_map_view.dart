import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/themed_huge_icon.dart';
import '../../application/device_graph.dart';
import '../../application/device_tree.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/device_status.dart';
import '../providers/device_providers.dart';

Color deviceGroupColor(DeviceGroup group) => switch (group) {
  DeviceGroup.computers => const Color(0xFF5B8DEF),
  DeviceGroup.phones => const Color(0xFF34C77B),
  DeviceGroup.tablets => const Color(0xFF2BB5A8),
  DeviceGroup.networkDevices => const Color(0xFFF2994A),
  DeviceGroup.printers => const Color(0xFFA77BF3),
  DeviceGroup.media => const Color(0xFFEF6FA5),
  DeviceGroup.iot => const Color(0xFFE5C04B),
  DeviceGroup.consoles => const Color(0xFFE5534B),
  DeviceGroup.cameras => const Color(0xFF3FB6E8),
  DeviceGroup.unknown => const Color(0xFF9AA0A6),
};

/// The device tree as an interactive node-link map: subnets and gateways
/// as hubs, type groups as clusters, devices as small dots. Pan by
/// dragging, zoom with pinch/scroll, hover to highlight a node and its
/// links, click a device to open its detail.
class DeviceMapView extends ConsumerStatefulWidget {
  const DeviceMapView({
    super.key,
    required this.roots,
    required this.onDeviceSelected,
    this.newDeviceIds = const {},
  });

  final List<DeviceTreeNode> roots;
  final ValueChanged<Device> onDeviceSelected;
  final Set<int> newDeviceIds;

  @override
  ConsumerState<DeviceMapView> createState() => _DeviceMapViewState();
}

class _DeviceMapViewState extends ConsumerState<DeviceMapView>
    with SingleTickerProviderStateMixin {
  /// Scene coordinates are centered on 0; the painted canvas is this big
  /// with its origin in the middle.
  static const _canvas = 8000.0;
  static const _origin = Offset(_canvas / 2, _canvas / 2);

  late DeviceGraph _graph;
  late ForceLayout _layout;
  late final Ticker _ticker;
  final _transform = TransformationController();
  final _frame = ValueNotifier<int>(0);
  Size _viewport = Size.zero;
  int? _hovered;
  bool _userMoved = false;

  @override
  void initState() {
    super.initState();
    _graph = buildDeviceGraph(widget.roots);
    _layout = ForceLayout(_graph);
    _ticker = createTicker(_tick)..start();
    _transform.addListener(_onTransform);
  }

  @override
  void didUpdateWidget(DeviceMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.roots, widget.roots)) return;
    final previous = {for (final node in _graph.nodes) node.id: node};
    final next = buildDeviceGraph(widget.roots);
    var added = false;
    for (final node in next.nodes) {
      final old = previous[node.id];
      if (old == null) {
        added = true;
        continue;
      }
      node
        ..x = old.x
        ..y = old.y;
    }
    final removed = next.nodes.length != previous.length;
    _graph = next;
    final alpha = _layout.alpha;
    _layout = ForceLayout(_graph)
      ..alpha = added || removed ? max(alpha, 0.35) : alpha;
    _hovered = null;
    if (!_ticker.isActive && !_layout.settled) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transform
      ..removeListener(_onTransform)
      ..dispose();
    _frame.dispose();
    super.dispose();
  }

  void _onTransform() => _frame.value++;

  void _tick(Duration _) {
    for (var i = 0; i < 3 && !_layout.settled; i++) {
      _layout.step();
    }
    if (!_userMoved) _fit();
    _frame.value++;
    if (_layout.settled) _ticker.stop();
  }

  void _fit() {
    if (_viewport.isEmpty || _graph.nodes.isEmpty) return;
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final node in _graph.nodes) {
      minX = min(minX, node.x);
      minY = min(minY, node.y);
      maxX = max(maxX, node.x);
      maxY = max(maxY, node.y);
    }
    const padding = 120.0;
    final scale = min(
      _viewport.width / (maxX - minX + padding),
      _viewport.height / (maxY - minY + padding),
    ).clamp(0.15, 2.0);
    final center = Offset((minX + maxX) / 2, (minY + maxY) / 2) + _origin;
    _transform.value =
        Matrix4.translationValues(_viewport.width / 2, _viewport.height / 2, 0)
            .multiplied(Matrix4.diagonal3Values(scale, scale, 1))
            .multiplied(Matrix4.translationValues(-center.dx, -center.dy, 0));
  }

  int? _hitTest(Offset local) {
    final scene = local - _origin;
    final scale = _transform.value.getMaxScaleOnAxis();
    final slop = 6 / scale;
    int? best;
    var bestDistance = double.infinity;
    for (final (i, node) in _graph.nodes.indexed) {
      final distance = (Offset(node.x, node.y) - scene).distance;
      if (distance <= node.radius + slop && distance < bestDistance) {
        best = i;
        bestDistance = distance;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedId = ref.watch(selectedDeviceIdProvider);
    final hovered = _hovered == null ? null : _graph.nodes[_hovered!];

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size != _viewport) {
          _viewport = size;
          if (!_userMoved) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _fit());
          }
        }
        return Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(
                color: scheme.surfaceContainerLowest,
                child: InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: 0.1,
                  maxScale: 5,
                  onInteractionStart: (_) => _userMoved = true,
                  child: SizedBox(
                    width: _canvas,
                    height: _canvas,
                    child: MouseRegion(
                      cursor: hovered?.device != null
                          ? SystemMouseCursors.click
                          : MouseCursor.defer,
                      onHover: (event) {
                        final hit = _hitTest(event.localPosition);
                        if (hit != _hovered) setState(() => _hovered = hit);
                      },
                      onExit: (_) => setState(() => _hovered = null),
                      child: GestureDetector(
                        onTapUp: (details) {
                          final hit = _hitTest(details.localPosition);
                          final device = hit == null
                              ? null
                              : _graph.nodes[hit].device;
                          if (device != null) widget.onDeviceSelected(device);
                        },
                        child: CustomPaint(
                          painter: _MapPainter(
                            graph: _graph,
                            frame: _frame,
                            transform: _transform,
                            viewport: _viewport,
                            hovered: _hovered,
                            selectedDeviceId: selectedId,
                            newDeviceIds: widget.newDeviceIds,
                            scheme: scheme,
                            labelStyle:
                                theme.textTheme.labelMedium ??
                                const TextStyle(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Tooltip(
                message: 'Haritayı ortala',
                child: Material(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      _userMoved = false;
                      _fit();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: ThemedHugeIcon(
                        HugeIcons.strokeRoundedCenterFocus,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (hovered != null)
              Positioned(top: 12, left: 12, child: _HoverCard(node: hovered)),
            Positioned(
              left: 12,
              bottom: 12,
              right: 12,
              child: _Legend(graph: _graph),
            ),
          ],
        );
      },
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.graph,
    required Listenable frame,
    required this.transform,
    required this.viewport,
    required this.hovered,
    required this.selectedDeviceId,
    required this.newDeviceIds,
    required this.scheme,
    required this.labelStyle,
  }) : super(repaint: frame);

  final DeviceGraph graph;
  final TransformationController transform;
  final Size viewport;
  final int? hovered;
  final int? selectedDeviceId;
  final Set<int> newDeviceIds;
  final ColorScheme scheme;
  final TextStyle labelStyle;

  static const _origin = _DeviceMapViewState._origin;

  Color _nodeColor(GraphNode node) => switch (node.kind) {
    GraphNodeKind.block || GraphNodeKind.subnet => scheme.onSurface,
    GraphNodeKind.gateway => const Color(0xFFF2994A),
    GraphNodeKind.group ||
    GraphNodeKind.device => deviceGroupColor(node.group ?? DeviceGroup.unknown),
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(_origin.dx, _origin.dy);
    final nodes = graph.nodes;
    final scale = transform.value.getMaxScaleOnAxis();
    final visible = _visibleSceneRect().inflate(40 / scale);
    final focus = hovered == null
        ? null
        : {hovered!, ...graph.neighbors[hovered!]};
    bool dimmed(int i) => focus != null && !focus.contains(i);

    final edgePaint = Paint()..strokeWidth = 1 / scale.clamp(0.5, 2);
    for (final edge in graph.edges) {
      final a = nodes[edge.source];
      final b = nodes[edge.target];
      final touchesFocus =
          hovered != null && (edge.source == hovered || edge.target == hovered);
      edgePaint.color = scheme.onSurfaceVariant.withValues(
        alpha: touchesFocus ? 0.9 : (focus == null ? 0.32 : 0.08),
      );
      canvas.drawLine(Offset(a.x, a.y), Offset(b.x, b.y), edgePaint);
    }

    final fill = Paint();
    final ring = Paint()..style = PaintingStyle.stroke;
    for (final (i, node) in nodes.indexed) {
      final center = Offset(node.x, node.y);
      if (!visible.contains(center)) continue;
      final color = _nodeColor(node);
      final alpha = dimmed(i) ? 0.18 : 1.0;
      final device = node.device;
      final offline = device != null && device.status != DeviceStatus.online;
      if (offline) {
        ring
          ..color = color.withValues(alpha: alpha * 0.8)
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, node.radius - 0.75, ring);
      } else {
        fill.color = color.withValues(alpha: alpha);
        canvas.drawCircle(center, node.radius, fill);
      }
      if (device != null && device.id == selectedDeviceId) {
        ring
          ..color = scheme.onSurface
          ..strokeWidth = 2;
        canvas.drawCircle(center, node.radius + 4, ring);
      } else if (device != null && newDeviceIds.contains(device.id)) {
        ring
          ..color = scheme.primary.withValues(alpha: alpha)
          ..strokeWidth = 1.5;
        canvas.drawCircle(center, node.radius + 3, ring);
      }
    }

    for (final (i, node) in nodes.indexed) {
      final center = Offset(node.x, node.y);
      if (!visible.contains(center)) continue;
      final isHub = node.kind != GraphNodeKind.device;
      final show =
          i == hovered ||
          (focus?.contains(i) ?? false) && scale > 0.6 ||
          (isHub && scale > 0.35) ||
          (!isHub && scale > 1.4);
      if (!show) continue;
      final painter = TextPainter(
        text: TextSpan(
          text: node.label,
          style: labelStyle.copyWith(
            fontSize: (isHub ? 13 : 11) / scale.clamp(0.8, 1.6),
            fontWeight: isHub ? FontWeight.w600 : FontWeight.w500,
            color: scheme.onSurface.withValues(alpha: dimmed(i) ? 0.25 : 0.9),
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 220);
      painter.paint(
        canvas,
        center + Offset(-painter.width / 2, node.radius + 4),
      );
    }
  }

  Rect _visibleSceneRect() {
    if (viewport.isEmpty) return Rect.largest;
    final inverse = Matrix4.inverted(transform.value);
    Offset toScene(Offset point) =>
        MatrixUtils.transformPoint(inverse, point) - _origin;
    return Rect.fromPoints(
      toScene(Offset.zero),
      toScene(Offset(viewport.width, viewport.height)),
    );
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.graph != graph ||
      old.hovered != hovered ||
      old.selectedDeviceId != selectedDeviceId ||
      old.scheme != scheme ||
      old.viewport != viewport ||
      old.newDeviceIds != newDeviceIds;
}

class _HoverCard extends StatelessWidget {
  const _HoverCard({required this.node});

  final GraphNode node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final device = node.device;
    final lines = device == null
        ? const <String>[]
        : [
            device.currentIp.toString(),
            ?device.model,
            ?device.vendor,
            device.displayType,
          ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Material(
        color: scheme.surfaceContainerHigh,
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                node.label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              for (final line in lines)
                Text(
                  line,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              if (device != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Detay için tıklayın',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.graph});

  final DeviceGraph graph;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final counts = <DeviceGroup, int>{};
    for (final node in graph.nodes) {
      if (node.kind == GraphNodeKind.device) {
        counts.update(node.group!, (c) => c + 1, ifAbsent: () => 1);
      }
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.bottomLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final group in DeviceGroup.values)
            if (counts[group] case final count?)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: deviceGroupColor(group),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${group.label} $count',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
