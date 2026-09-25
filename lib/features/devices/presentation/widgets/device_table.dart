import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/device_query.dart';
import '../../domain/entities/device.dart';
import '../providers/device_providers.dart';
import 'device_visuals.dart';

enum DeviceColumn {
  status('Durum', 110, DeviceSortField.lastSeen),
  name('Cihaz adı', 200, DeviceSortField.name),
  ip('IP', 130, DeviceSortField.ip),
  mac('MAC', 150, null),
  vendor('Üretici', 140, null),
  model('Model', 170, null),
  typeOs('Tür/OS', 200, null),
  lastSeen('Son görülme', 150, DeviceSortField.lastSeen);

  const DeviceColumn(this.label, this.defaultWidth, this.sortField);

  final String label;
  final double defaultWidth;
  final DeviceSortField? sortField;
}

/// Virtualized device list with resizable, hideable columns.
class DeviceTable extends ConsumerStatefulWidget {
  const DeviceTable({
    super.key,
    required this.devices,
    required this.onDeviceSelected,
    this.newDeviceIds = const {},
  });

  final List<Device> devices;
  final ValueChanged<Device> onDeviceSelected;

  /// Devices to mark "Yeni".
  final Set<int> newDeviceIds;

  @override
  ConsumerState<DeviceTable> createState() => _DeviceTableState();
}

class _DeviceTableState extends ConsumerState<DeviceTable> {
  static const _minColumnWidth = 60.0;
  static const _rowHeight = 40.0;

  final Map<DeviceColumn, double> _widths = {
    for (final column in DeviceColumn.values) column: column.defaultWidth,
  };
  final Set<DeviceColumn> _hidden = {};
  final _horizontal = ScrollController();
  final _vertical = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  List<DeviceColumn> get _visible => [
    for (final column in DeviceColumn.values)
      if (!_hidden.contains(column)) column,
  ];

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(deviceQueryProvider);
    final selectedId = ref.watch(selectedDeviceIdProvider);
    final columns = _visible;
    final totalWidth =
        columns.fold<double>(0, (sum, column) => sum + _widths[column]!) + 48;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = totalWidth > constraints.maxWidth
            ? totalWidth
            : constraints.maxWidth;
        return Scrollbar(
          controller: _horizontal,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: Column(
                children: [
                  _header(context, columns, query),
                  const Divider(height: 1),
                  Expanded(
                    child: Scrollbar(
                      controller: _vertical,
                      child: ListView.builder(
                        controller: _vertical,
                        itemCount: widget.devices.length,
                        itemExtent: _rowHeight,
                        itemBuilder: (context, index) {
                          final device = widget.devices[index];
                          return _row(
                            context,
                            columns,
                            device,
                            selected: device.id == selectedId,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(
    BuildContext context,
    List<DeviceColumn> columns,
    DeviceQuery query,
  ) {
    final theme = Theme.of(context);
    return Container(
      height: 40,
      color: theme.colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          for (final column in columns)
            SizedBox(
              width: _widths[column],
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: column.sortField == null
                          ? null
                          : () => ref
                                .read(deviceQueryProvider.notifier)
                                .update(
                                  (q) => q.sortField == column.sortField
                                      ? q.copyWith(ascending: !q.ascending)
                                      : q.copyWith(
                                          sortField: column.sortField,
                                          ascending: true,
                                        ),
                                ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                column.label,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelLarge,
                              ),
                            ),
                            if (column.sortField != null &&
                                column.sortField == query.sortField &&
                                column != DeviceColumn.status)
                              Text(query.ascending ? ' ↑' : ' ↓'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _resizeHandle(column),
                ],
              ),
            ),
          SizedBox(
            width: 48,
            child: PopupMenuButton<DeviceColumn>(
              tooltip: 'Kolonları göster/gizle',
              icon: const ThemedHugeIcon(
                HugeIcons.strokeRoundedColumnInsert,
                size: 18,
              ),
              onSelected: (column) => setState(() {
                if (!_hidden.remove(column) && _visible.length > 1) {
                  _hidden.add(column);
                }
              }),
              itemBuilder: (context) => [
                for (final column in DeviceColumn.values)
                  CheckedPopupMenuItem(
                    value: column,
                    checked: !_hidden.contains(column),
                    child: Text(column.label),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resizeHandle(DeviceColumn column) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => setState(() {
          _widths[column] = (_widths[column]! + details.delta.dx).clamp(
            _minColumnWidth,
            600,
          );
        }),
        child: Semantics(
          label: '${column.label} kolon genişliği',
          child: SizedBox(
            width: 8,
            child: Center(
              child: Container(
                width: 1,
                height: 20,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    List<DeviceColumn> columns,
    Device device, {
    required bool selected,
  }) {
    final theme = Theme.of(context);
    return Semantics(
      label:
          '${device.displayName}, ${device.currentIp}, ${device.status.label}',
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: Material(
        color: selected ? theme.colorScheme.secondaryContainer : null,
        child: InkWell(
          onTap: () => widget.onDeviceSelected(device),
          child: Row(
            children: [
              for (final column in columns)
                SizedBox(
                  width: _widths[column],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _cell(context, column, device),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(BuildContext context, DeviceColumn column, Device device) {
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.outline,
    );
    Text text(String value) => Text(value, overflow: TextOverflow.ellipsis);

    return switch (column) {
      DeviceColumn.status => DeviceStatusBadge(
        status: device.status,
        dense: true,
      ),
      DeviceColumn.name => Row(
        children: [
          Flexible(child: text(device.displayName)),
          const SizedBox(width: 6),
          DeviceTags(
            device: device,
            isNew: widget.newDeviceIds.contains(device.id),
          ),
          const Spacer(),
          if (device.webUri != null) OpenWebUiButton(device: device),
        ],
      ),
      DeviceColumn.ip => text(device.currentIp.toString()),
      DeviceColumn.mac =>
        device.macAddress == null
            ? Text('Bilinmiyor', style: muted)
            : text(device.macAddress!),
      DeviceColumn.vendor =>
        device.vendor == null
            ? Text('Bilinmiyor', style: muted)
            : text(device.vendor!),
      DeviceColumn.model =>
        device.model == null ? Text('—', style: muted) : text(device.model!),
      DeviceColumn.typeOs => Tooltip(
        message:
            'Tür: ${deviceTypeWithConfidence(device)}\n'
            'OS: ${deviceOsWithConfidence(device)}',
        child: text(
          device.inferredOs == null
              ? deviceTypeWithConfidence(device)
              : '${deviceTypeWithConfidence(device)} / '
                    '${deviceOsWithConfidence(device)}',
        ),
      ),
      DeviceColumn.lastSeen => text(formatDateTime(device.lastSeenAt)),
    };
  }
}
