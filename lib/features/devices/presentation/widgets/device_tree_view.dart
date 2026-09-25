import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../network_scope/domain/entities/subnet_reachability.dart';
import '../../../traffic/presentation/formatting/byte_format.dart';
import '../../../traffic/presentation/providers/traffic_providers.dart';
import '../../application/device_tree.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/device_type.dart';
import '../providers/device_providers.dart';
import 'device_visuals.dart';

const double _indentWidth = 22;
const double _headerRowHeight = 52;
const double _gatewayRowHeight = 46;
const double _groupRowHeight = 46;
const double _deviceRowHeight = 44;

double _rowHeight(DeviceTreeNode node) => switch (node) {
  BlockTreeNode() || SubnetTreeNode() => _headerRowHeight,
  GatewayTreeNode() => _gatewayRowHeight,
  GroupTreeNode() => _groupRowHeight,
  DeviceLeafNode() => _deviceRowHeight,
};

/// The network as a top-to-bottom outline tree: 172.16.0.0/12 → subnets →
/// gateway → device groups → devices. A single lazily-built vertical list —
/// no canvas, no pan/zoom/scale-to-fit — so it stays readable and smooth
/// whether there are 5 devices or 5,000: only the rows currently on screen
/// (plus a small cache margin) are ever built.
class DeviceTreeView extends ConsumerStatefulWidget {
  const DeviceTreeView({
    super.key,
    required this.roots,
    required this.onDeviceSelected,
    this.forceExpandAll = false,
  });

  final List<DeviceTreeNode> roots;
  final ValueChanged<Device> onDeviceSelected;

  /// True while a search/filter is active: the device list feeding [roots]
  /// is already filtered, so every remaining group is forced open instead
  /// of hiding its (already-matching) devices behind its closed default.
  final bool forceExpandAll;

  @override
  ConsumerState<DeviceTreeView> createState() => _DeviceTreeViewState();
}

class _DeviceTreeViewState extends ConsumerState<DeviceTreeView> {
  final _scrollController = ScrollController();
  final _focusNode = FocusNode(debugLabel: 'DeviceTreeView');
  final Map<String, GlobalKey> _rowKeys = {};
  String? _focusedId;

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _ensureVisible(String nodeId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _rowKeys[nodeId]?.currentContext;
      if (context == null || !mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 150),
      );
    });
  }

  KeyEventResult _handleKey(
    List<DeviceTreeRow> rows,
    FocusNode node,
    KeyEvent event,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (rows.isEmpty) return KeyEventResult.ignored;

    final currentIndex = _focusedId == null
        ? -1
        : rows.indexWhere((r) => r.node.id == _focusedId);

    void focusIndex(int index) {
      final clamped = index.clamp(0, rows.length - 1);
      setState(() => _focusedId = rows[clamped].node.id);
      _ensureVisible(rows[clamped].node.id);
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        focusIndex(currentIndex < 0 ? 0 : currentIndex + 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        focusIndex(currentIndex < 0 ? 0 : currentIndex - 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        if (currentIndex < 0) return KeyEventResult.ignored;
        final row = rows[currentIndex];
        if (row.hasChildren && !row.isExpanded) {
          ref.read(treeNodeTogglesProvider.notifier).toggle(row.node.id);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowLeft:
        if (currentIndex < 0) return KeyEventResult.ignored;
        final row = rows[currentIndex];
        if (row.hasChildren && row.isExpanded) {
          ref.read(treeNodeTogglesProvider.notifier).toggle(row.node.id);
        } else if (row.parentId != null) {
          final parentIndex = rows.indexWhere((r) => r.node.id == row.parentId);
          if (parentIndex != -1) focusIndex(parentIndex);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.numpadEnter:
        if (currentIndex < 0) return KeyEventResult.ignored;
        final row = rows[currentIndex];
        _activate(row);
        return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _activate(DeviceTreeRow row) {
    final device = switch (row.node) {
      DeviceLeafNode(:final device) || GatewayTreeNode(:final device) => device,
      _ => null,
    };
    if (device != null) {
      widget.onDeviceSelected(device);
    } else if (row.hasChildren) {
      ref.read(treeNodeTogglesProvider.notifier).toggle(row.node.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final toggled = ref.watch(treeNodeTogglesProvider);
    final selectedId = ref.watch(selectedDeviceIdProvider);
    final traffic = ref.watch(todayTrafficTotalsProvider).value;
    final rows = flattenDeviceTree(
      widget.roots,
      toggled,
      forceExpanded: widget.forceExpandAll
          ? allTreeNodeIds(widget.roots)
          : const {},
    );

    _rowKeys.removeWhere((id, _) => rows.every((r) => r.node.id != id));

    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) => _handleKey(rows, node, event),
      child: Scrollbar(
        controller: _scrollController,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final row = rows[index];
            final key = _rowKeys.putIfAbsent(row.node.id, GlobalKey.new);
            final device = switch (row.node) {
              DeviceLeafNode(:final device) ||
              GatewayTreeNode(:final device) => device,
              _ => null,
            };
            return _TreeRow(
              key: key,
              row: row,
              selected: device != null && device.id == selectedId,
              focused: row.node.id == _focusedId,
              traffic: traffic,
              onTap: () {
                _focusNode.requestFocus();
                setState(() => _focusedId = row.node.id);
                _activate(row);
              },
              onToggle: () => ref
                  .read(treeNodeTogglesProvider.notifier)
                  .toggle(row.node.id),
            );
          },
        ),
      ),
    );
  }
}

class _TreeRow extends StatelessWidget {
  const _TreeRow({
    super.key,
    required this.row,
    required this.selected,
    required this.focused,
    required this.traffic,
    required this.onTap,
    required this.onToggle,
  });

  final DeviceTreeRow row;
  final bool selected;
  final bool focused;
  final TodayTrafficTotals? traffic;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final node = row.node;
    return Semantics(
      label: _semanticLabel(node),
      selected: selected,
      expanded: row.hasChildren ? row.isExpanded : null,
      button: true,
      child: SizedBox(
        height: _rowHeight(node),
        child: switch (node) {
          BlockTreeNode() || SubnetTreeNode() => _HeaderRow(
            row: row,
            focused: focused,
            onTap: onTap,
          ),
          GatewayTreeNode(:final device) => _GatewayRow(
            row: row,
            device: device,
            selected: selected,
            focused: focused,
            onTap: onTap,
          ),
          GroupTreeNode() => _GroupRow(
            row: row,
            focused: focused,
            onTap: onTap,
          ),
          DeviceLeafNode(:final device) => _DeviceRow(
            row: row,
            device: device,
            selected: selected,
            focused: focused,
            traffic: traffic,
            onTap: onTap,
          ),
        },
      ),
    );
  }

  String _semanticLabel(DeviceTreeNode node) {
    final depthLabel = 'Seviye ${row.depth + 1}';
    return switch (node) {
      BlockTreeNode(:final cidr) => '$cidr, özel 172 ağı, $depthLabel',
      SubnetTreeNode(:final cidr, :final deviceCount) =>
        '$cidr, $deviceCount cihaz, $depthLabel',
      GatewayTreeNode(:final device) =>
        'Gateway, ${device.currentIp}, $depthLabel',
      GroupTreeNode(:final group, :final count) =>
        '${group.label}, $count cihaz, $depthLabel',
      DeviceLeafNode(:final device) =>
        '${device.displayName}, ${device.currentIp}, ${device.status.label}, $depthLabel',
    };
  }
}

/// The indentation guides to the left of a row's content: one thin vertical
/// line per ancestor level, with a short elbow at the row's own level. Kept
/// deliberately faint — a wayfinding cue, not a decoration competing with
/// the text (per design spec).
class _TreeGuides extends StatelessWidget {
  const _TreeGuides({required this.depth});

  final int depth;

  @override
  Widget build(BuildContext context) {
    if (depth == 0) return const SizedBox(width: 4);
    final lineColor = Theme.of(
      context,
    ).colorScheme.outlineVariant.withValues(alpha: 0.6);
    return SizedBox(
      width: depth * _indentWidth,
      child: Row(
        children: [
          for (var level = 0; level < depth; level++)
            SizedBox(
              width: _indentWidth,
              child: level == depth - 1
                  ? CustomPaint(painter: _ElbowPainter(lineColor))
                  : Center(child: Container(width: 1, color: lineColor)),
            ),
        ],
      ),
    );
  }
}

class _ElbowPainter extends CustomPainter {
  const _ElbowPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final midX = size.width / 2;
    final midY = size.height / 2;
    canvas.drawLine(Offset(midX, 0), Offset(midX, midY), paint);
    canvas.drawLine(Offset(midX, midY), Offset(size.width, midY), paint);
  }

  @override
  bool shouldRepaint(_ElbowPainter old) => old.color != color;
}

/// Shared tap/hover/focus chrome so every row type reacts the same way.
class _RowChrome extends StatefulWidget {
  const _RowChrome({
    required this.depth,
    required this.onTap,
    required this.child,
    this.selected = false,
    this.focused = false,
    this.expandable = false,
    this.expanded = false,
    this.onToggle,
    this.background,
  });

  final int depth;
  final VoidCallback onTap;
  final Widget child;
  final bool selected;
  final bool focused;
  final bool expandable;
  final bool expanded;
  final VoidCallback? onToggle;
  final Color? background;

  @override
  State<_RowChrome> createState() => _RowChromeState();
}

class _RowChromeState extends State<_RowChrome> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = widget.selected
        ? scheme.primaryContainer.withValues(alpha: 0.45)
        : _hovering
        ? scheme.onSurface.withValues(alpha: 0.04)
        : widget.background;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: background,
            border: Border(
              left: BorderSide(
                color: widget.selected ? scheme.primary : Colors.transparent,
                width: 3,
              ),
              bottom: widget.focused
                  ? BorderSide(color: scheme.primary, width: 1)
                  : BorderSide.none,
            ),
          ),
          child: Row(
            children: [
              _TreeGuides(depth: widget.depth),
              if (widget.expandable)
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  turns: widget.expanded ? 0.25 : 0,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 16,
                    tooltip: widget.expanded ? 'Daralt' : 'Genişlet',
                    onPressed: widget.onToggle,
                    icon: ThemedHugeIcon(
                      HugeIcons.strokeRoundedArrowRight01,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                const SizedBox(width: 12),
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.row,
    required this.focused,
    required this.onTap,
  });

  final DeviceTreeRow row;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final node = row.node;
    final isRoot = node is BlockTreeNode;
    final unreachable =
        node is SubnetTreeNode &&
        node.reachability == SubnetReachability.unreachable;

    final (icon, title, subtitle, count) = switch (node) {
      BlockTreeNode(:final cidr) => (
        HugeIcons.strokeRoundedGlobe02,
        '$cidr',
        'Özel 172 ağı',
        null,
      ),
      SubnetTreeNode(:final cidr, :final reachability, :final deviceCount) => (
        switch (reachability) {
          SubnetReachability.directlyConnected => HugeIcons.strokeRoundedLink01,
          SubnetReachability.routed => HugeIcons.strokeRoundedRoute01,
          SubnetReachability.unreachable => HugeIcons.strokeRoundedUnlink01,
          null => HugeIcons.strokeRoundedTime01,
        },
        '$cidr',
        switch (reachability) {
          SubnetReachability.directlyConnected => 'Doğrudan bağlı',
          SubnetReachability.routed => 'Router üzerinden',
          SubnetReachability.unreachable => 'Erişilemiyor',
          null => 'Önceki taramalardan',
        },
        deviceCount,
      ),
      _ => (HugeIcons.strokeRoundedGlobe02, '', null, null),
    };

    final iconColor = unreachable
        ? scheme.error
        : (isRoot ? scheme.primary : scheme.secondary);

    return _RowChrome(
      depth: row.depth,
      selected: false,
      focused: focused,
      expandable: row.hasChildren,
      expanded: row.isExpanded,
      onToggle: onTap,
      onTap: onTap,
      background: isRoot
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerLow,
      child: Row(
        children: [
          ThemedHugeIcon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: unreachable ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (count != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                '$count cihaz',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GatewayRow extends StatelessWidget {
  const _GatewayRow({
    required this.row,
    required this.device,
    required this.selected,
    required this.focused,
    required this.onTap,
  });

  final DeviceTreeRow row;
  final Device device;
  final bool selected;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _RowChrome(
      depth: row.depth,
      selected: selected,
      focused: focused,
      expandable: row.hasChildren,
      expanded: row.isExpanded,
      onToggle: () {},
      onTap: onTap,
      background: scheme.tertiaryContainer.withValues(alpha: 0.3),
      child: Row(
        children: [
          ThemedHugeIcon(
            HugeIcons.strokeRoundedRouter01,
            size: 18,
            color: scheme.tertiary,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              device.shortHostname ?? 'Gateway',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            device.currentIp.toString(),
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: DeviceStatusBadge(status: device.status, dense: true),
          ),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.row,
    required this.focused,
    required this.onTap,
  });

  final DeviceTreeRow row;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final node = row.node as GroupTreeNode;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final icon = deviceTypeIcon(_representativeType(node.group));

    return _RowChrome(
      depth: row.depth,
      focused: focused,
      expandable: true,
      expanded: row.isExpanded,
      onToggle: onTap,
      onTap: onTap,
      child: Row(
        children: [
          ThemedHugeIcon(icon, size: 17, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              node.group.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('${node.count}', style: theme.textTheme.labelSmall),
          ),
        ],
      ),
    );
  }

  DeviceType _representativeType(DeviceGroup group) => switch (group) {
    DeviceGroup.phones => DeviceType.phone,
    DeviceGroup.tablets => DeviceType.tablet,
    DeviceGroup.computers => DeviceType.windowsComputer,
    DeviceGroup.networkDevices => DeviceType.routerGateway,
    DeviceGroup.printers => DeviceType.printer,
    DeviceGroup.media => DeviceType.smartTvMedia,
    DeviceGroup.iot => DeviceType.iotSmartHome,
    DeviceGroup.consoles => DeviceType.gameConsole,
    DeviceGroup.cameras => DeviceType.camera,
    DeviceGroup.unknown => DeviceType.unknown,
  };
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.row,
    required this.device,
    required this.selected,
    required this.focused,
    required this.traffic,
    required this.onTap,
  });

  final DeviceTreeRow row;
  final Device device;
  final bool selected;
  final bool focused;
  final TodayTrafficTotals? traffic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final secondary = device.vendor ?? deviceOsWithConfidence(device);

    return _RowChrome(
      depth: row.depth,
      selected: selected,
      focused: focused,
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 420;
          final veryNarrow = constraints.maxWidth < 320;
          return Row(
            children: [
              _StatusDot(status: device.status),
              const SizedBox(width: 6),
              ThemedHugeIcon(
                deviceTypeIcon(device.effectiveType),
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              // Wrapped in Flexible so a genuinely tight row (see the narrow
              // layout below) can still shrink this instead of overflowing,
              // but a plain SizedBox always *asks* for the full 190 — so on
              // every normal-width row the name column ends at the same x
              // regardless of how long this device's name is, and IP/vendor
              // line up into clean columns underneath instead of drifting
              // per row.
              Flexible(
                child: SizedBox(
                  width: 190,
                  // The IP always has its own column, so an unnamed device
                  // shows a muted placeholder rather than the IP in the
                  // name column and a gap where the IP should be.
                  child: device.hasName
                      ? Text(
                          device.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : Text(
                          'Adsız',
                          maxLines: 1,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 108,
                child: Text(
                  device.currentIp.toString(),
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              if (!narrow) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ] else
                const Spacer(),
              if (!veryNarrow)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _TrafficLabel(device: device, traffic: traffic),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: deviceStatusColor(context, status),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Never a fake "0 MB": without a provider, or without samples for this
/// device today, the label says there is no data.
class _TrafficLabel extends StatelessWidget {
  const _TrafficLabel({required this.device, required this.traffic});

  final Device device;
  final TodayTrafficTotals? traffic;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.outline,
    );
    final trafficValue = traffic;
    final totals = trafficValue?.byDevice[device.id];
    if (trafficValue == null || totals == null) {
      return Tooltip(
        message: trafficValue == null
            ? 'Trafik verisi mevcut değil'
            : 'Bu cihaz için bugün trafik örneği yok',
        child: Text('Veri yok', style: style),
      );
    }
    final text = formatBytes(
      totals.totalBytes,
      binary: trafficValue.useBinaryUnits,
    );
    return Text(
      trafficValue.isDemo ? '$text (demo)' : text,
      style: style?.copyWith(color: null),
    );
  }
}
