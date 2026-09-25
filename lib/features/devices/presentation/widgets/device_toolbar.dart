import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/utils/cidr.dart';
import '../../application/device_query.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/device_type.dart';
import '../providers/device_providers.dart';

/// Search, tree/list toggle, filters and sort.
class DeviceToolbar extends ConsumerStatefulWidget {
  const DeviceToolbar({
    super.key,
    required this.subnets,
    this.osNames = const [],
    this.vendors = const [],
    required this.visibleCount,
    required this.totalCount,
  });

  /// Subnets offered in the subnet filter.
  final List<Cidr> subnets;

  /// OS names and vendors present among the devices (plus "Bilinmiyor").
  final List<String> osNames;
  final List<String> vendors;

  final int visibleCount;
  final int totalCount;

  @override
  ConsumerState<DeviceToolbar> createState() => _DeviceToolbarState();
}

class _DeviceToolbarState extends ConsumerState<DeviceToolbar> {
  late final _searchController = TextEditingController(
    text: ref.read(deviceQueryProvider).search,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _update(DeviceQuery Function(DeviceQuery) change) =>
      ref.read(deviceQueryProvider.notifier).update(change);

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(deviceQueryProvider);
    final viewMode = ref.watch(deviceViewModeProvider);
    final filterCount =
        query.statuses.length +
        query.types.length +
        query.osNames.length +
        query.vendors.length +
        (query.subnet != null ? 1 : 0) +
        (query.onlyPingConfirmed ? 1 : 0);

    final search = _SearchField(
      controller: _searchController,
      showClear: query.search.isNotEmpty,
      onChanged: (value) => _update((q) => q.copyWith(search: value)),
      onClear: () {
        _searchController.clear();
        _update((q) => q.copyWith(search: ''));
      },
    );
    final viewToggle = _ViewModeToggle(
      value: viewMode,
      onChanged: ref.read(deviceViewModeProvider.notifier).set,
    );
    final filter = _filterMenu(context, query, filterCount);
    final sort = _sortMenu(query);
    final count = _CountLabel(
      visible: widget.visibleCount,
      total: widget.totalCount,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            return Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: search,
                        ),
                      ),
                      const SizedBox(width: 12),
                      viewToggle,
                      const SizedBox(width: 8),
                      filter,
                      const SizedBox(width: 8),
                      sort,
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                count,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              search,
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [viewToggle, filter, sort, count],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterMenu(BuildContext context, DeviceQuery query, int filterCount) {
    return MenuAnchor(
      menuChildren: [
        CheckboxMenuButton(
          value: query.hideUninformativeOffline,
          closeOnActivate: false,
          onChanged: (_) => _update(
            (q) => q.copyWith(
              hideUninformativeOffline: !q.hideUninformativeOffline,
            ),
          ),
          child: const Text('Bilgisi olmayan çevrimdışı cihazları gizle'),
        ),
        CheckboxMenuButton(
          value: query.onlyPingConfirmed,
          closeOnActivate: false,
          onChanged: (_) => _update(
            (q) => q.copyWith(onlyPingConfirmed: !q.onlyPingConfirmed),
          ),
          child: const Text('Yalnızca ping\'e cevap veren cihazlar'),
        ),
        const Divider(),
        _heading(context, 'Durum'),
        for (final status in DeviceStatus.values)
          CheckboxMenuButton(
            value: query.statuses.contains(status),
            closeOnActivate: false,
            onChanged: (_) => _update(
              (q) => q.copyWith(statuses: _toggle(q.statuses, status)),
            ),
            child: Text(status.label),
          ),
        const Divider(),
        _heading(context, 'Tür'),
        for (final type in DeviceType.values)
          CheckboxMenuButton(
            value: query.types.contains(type),
            closeOnActivate: false,
            onChanged: (_) =>
                _update((q) => q.copyWith(types: _toggle(q.types, type))),
            child: Text(type.label),
          ),
        if (widget.osNames.isNotEmpty) ...[
          const Divider(),
          _heading(context, 'İşletim sistemi'),
          for (final os in widget.osNames)
            CheckboxMenuButton(
              value: query.osNames.contains(os),
              closeOnActivate: false,
              onChanged: (_) =>
                  _update((q) => q.copyWith(osNames: _toggle(q.osNames, os))),
              child: Text(os),
            ),
        ],
        if (widget.vendors.isNotEmpty) ...[
          const Divider(),
          _heading(context, 'Üretici'),
          for (final vendor in widget.vendors)
            CheckboxMenuButton(
              value: query.vendors.contains(vendor),
              closeOnActivate: false,
              onChanged: (_) => _update(
                (q) => q.copyWith(vendors: _toggle(q.vendors, vendor)),
              ),
              child: Text(vendor),
            ),
        ],
        if (widget.subnets.isNotEmpty) ...[
          const Divider(),
          _heading(context, 'Alt ağ'),
          for (final subnet in widget.subnets)
            CheckboxMenuButton(
              value: query.subnet == subnet,
              closeOnActivate: false,
              onChanged: (_) => _update(
                (q) => q.copyWith(
                  subnet: () => q.subnet == subnet ? null : subnet,
                ),
              ),
              child: Text(subnet.toString()),
            ),
        ],
        const Divider(),
        MenuItemButton(
          onPressed: query.hasFilters
              ? () {
                  _searchController.clear();
                  ref.read(deviceQueryProvider.notifier).reset();
                }
              : null,
          child: const Text('Filtreleri temizle'),
        ),
      ],
      builder: (context, controller, _) => _ToolbarButton(
        icon: HugeIcons.strokeRoundedFilter,
        label: 'Filtre',
        badge: filterCount == 0 ? null : '$filterCount',
        active: filterCount > 0,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }

  Widget _sortMenu(DeviceQuery query) {
    return MenuAnchor(
      menuChildren: [
        for (final field in DeviceSortField.values)
          RadioMenuButton<DeviceSortField>(
            value: field,
            groupValue: query.sortField,
            onChanged: (value) => _update((q) => q.copyWith(sortField: value)),
            child: Text(field.label),
          ),
        const Divider(),
        CheckboxMenuButton(
          value: !query.ascending,
          onChanged: (_) => _update((q) => q.copyWith(ascending: !q.ascending)),
          child: const Text('Azalan sıra'),
        ),
      ],
      builder: (context, controller, _) => _ToolbarButton(
        icon: HugeIcons.strokeRoundedSorting01,
        label: 'Sırala: ${query.sortField.label}${query.ascending ? '' : ' ↓'}',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Text(text, style: Theme.of(context).textTheme.labelMedium),
  );

  static Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};
}

const _controlHeight = 40.0;
const _controlRadius = 10.0;

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.showClear,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final bool showClear;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(_controlRadius),
          borderSide: BorderSide(color: color, width: width),
        );
    return SizedBox(
      height: _controlHeight,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        expands: true,
        maxLines: null,
        textAlignVertical: TextAlignVertical.center,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHigh,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: ThemedHugeIcon(
              HugeIcons.strokeRoundedSearch01,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(),
          hintText: 'IP, MAC, hostname, üretici veya ad ara',
          hintStyle: TextStyle(color: scheme.onSurfaceVariant),
          border: border(Colors.transparent),
          enabledBorder: border(scheme.outlineVariant.withValues(alpha: 0.5)),
          focusedBorder: border(scheme.primary, 1.5),
          suffixIcon: showClear
              ? IconButton(
                  tooltip: 'Aramayı temizle',
                  visualDensity: VisualDensity.compact,
                  icon: const ThemedHugeIcon(
                    HugeIcons.strokeRoundedCancel01,
                    size: 16,
                  ),
                  onPressed: onClear,
                )
              : null,
        ),
      ),
    );
  }
}

class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.value, required this.onChanged});

  final DeviceViewMode value;
  final ValueChanged<DeviceViewMode> onChanged;

  static const _segmentWidth = 96.0;
  static const _inset = 3.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const modes = DeviceViewMode.values;
    return Container(
      height: _controlHeight,
      width: _segmentWidth * modes.length + _inset * 2,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(_controlRadius),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment(-1 + 2 * value.index / (modes.length - 1), 0),
            child: Container(
              width: _segmentWidth,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(_controlRadius - _inset),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _segment(
                context,
                DeviceViewMode.tree,
                'Ağaç',
                'Alt ağ ve cihaz türüne göre gruplu',
                HugeIcons.strokeRoundedHierarchy,
              ),
              _segment(
                context,
                DeviceViewMode.list,
                'Liste',
                'Sütunlu, sıralanabilir tablo',
                HugeIcons.strokeRoundedLeftToRightListBullet,
              ),
              _segment(
                context,
                DeviceViewMode.map,
                'Harita',
                'Ağ haritası: alt ağlar, gruplar ve cihazlar',
                HugeIcons.strokeRoundedAiNetwork,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    DeviceViewMode mode,
    String label,
    String tooltip,
    List<List<dynamic>> icon,
  ) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = mode == value;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: Semantics(
        button: true,
        selected: selected,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(mode),
            child: SizedBox(
              width: _segmentWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ThemedHugeIcon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Flexible(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: (theme.textTheme.labelLarge ?? const TextStyle())
                          .copyWith(
                            color: selected ? scheme.primary : color,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.badge,
    this.active = false,
  });

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onPressed;
  final String? badge;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = active ? scheme.onPrimaryContainer : scheme.onSurface;
    return Material(
      color: active ? scheme.primaryContainer : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(_controlRadius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(_controlRadius),
        child: Container(
          height: _controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ThemedHugeIcon(
                icon,
                size: 16,
                color: active ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (badge case final badge?) ...[
                const SizedBox(width: 8),
                Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    badge,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountLabel extends StatelessWidget {
  const _CountLabel({required this.visible, required this.total});

  final int visible;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$visible',
            style: muted?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: ' / $total cihaz'),
        ],
      ),
      style: muted,
    );
  }
}
