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
  });

  /// Subnets offered in the subnet filter.
  final List<Cidr> subnets;

  /// OS names and vendors present among the devices (plus "Bilinmiyor").
  final List<String> osNames;
  final List<String> vendors;

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
        (query.subnet != null ? 1 : 0) +
        (query.onlyPingConfirmed ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(10),
                  child: ThemedHugeIcon(
                    HugeIcons.strokeRoundedSearch01,
                    size: 18,
                  ),
                ),
                hintText: 'IP, MAC, hostname, üretici veya ad ara',
                border: const OutlineInputBorder(),
                suffixIcon: query.search.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Aramayı temizle',
                        icon: const ThemedHugeIcon(
                          HugeIcons.strokeRoundedCancel01,
                          size: 16,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _update((q) => q.copyWith(search: ''));
                        },
                      ),
              ),
              onChanged: (value) => _update((q) => q.copyWith(search: value)),
            ),
          ),
          SegmentedButton<DeviceViewMode>(
            segments: const [
              ButtonSegment(
                value: DeviceViewMode.tree,
                label: Text('Ağaç'),
                icon: ThemedHugeIcon(
                  HugeIcons.strokeRoundedHierarchy,
                  size: 16,
                ),
              ),
              ButtonSegment(
                value: DeviceViewMode.list,
                label: Text('Liste'),
                icon: ThemedHugeIcon(
                  HugeIcons.strokeRoundedLeftToRightListBullet,
                  size: 16,
                ),
              ),
            ],
            selected: {viewMode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                ref.read(deviceViewModeProvider.notifier).set(selection.single),
          ),
          MenuAnchor(
            menuChildren: [
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
                    onChanged: (_) => _update(
                      (q) => q.copyWith(osNames: _toggle(q.osNames, os)),
                    ),
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
            builder: (context, controller, _) => OutlinedButton.icon(
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              icon: const ThemedHugeIcon(
                HugeIcons.strokeRoundedFilter,
                size: 16,
              ),
              label: Text(
                filterCount == 0 ? 'Filtre' : 'Filtre ($filterCount)',
              ),
            ),
          ),
          MenuAnchor(
            menuChildren: [
              for (final field in DeviceSortField.values)
                RadioMenuButton<DeviceSortField>(
                  value: field,
                  groupValue: query.sortField,
                  onChanged: (value) =>
                      _update((q) => q.copyWith(sortField: value)),
                  child: Text(field.label),
                ),
              const Divider(),
              CheckboxMenuButton(
                value: !query.ascending,
                onChanged: (_) =>
                    _update((q) => q.copyWith(ascending: !q.ascending)),
                child: const Text('Azalan sıra'),
              ),
            ],
            builder: (context, controller, _) => OutlinedButton.icon(
              onPressed: () =>
                  controller.isOpen ? controller.close() : controller.open(),
              icon: const ThemedHugeIcon(
                HugeIcons.strokeRoundedSorting01,
                size: 16,
              ),
              label: Text(
                'Sırala: ${query.sortField.label}${query.ascending ? '' : ' ↓'}',
              ),
            ),
          ),
        ],
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
