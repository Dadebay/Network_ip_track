import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/shell_navigation.dart';
import '../../../../app/widgets/failure_view.dart';
import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/cidr.dart';
import '../../../discovery/presentation/widgets/scan_status_strip.dart';
import '../../../network_scope/presentation/providers/network_scope_providers.dart';
import '../../../traffic/presentation/providers/traffic_providers.dart';
import '../../application/device_query.dart';
import '../../application/device_tree.dart';
import '../../domain/entities/device.dart';
import '../providers/device_providers.dart';
import '../widgets/device_detail_panel.dart';
import '../widgets/device_map_view.dart';
import '../widgets/device_table.dart';
import '../widgets/device_toolbar.dart';
import '../widgets/device_tree_view.dart';
import '../widgets/device_visuals.dart';

/// Main view: the discovered devices of the active network as a tree or a
/// list, updating live while a scan streams results in.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  static const _detailPaneBreakpoint = 1000.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkAsync = ref.watch(activeNetworkProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cihazlar'),
        actions: [
          IconButton(
            tooltip: 'Ağı yeniden algıla',
            icon: const ThemedHugeIcon(HugeIcons.strokeRoundedRefresh),
            onPressed: () => ref.invalidate(networkScopeProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          const ScanStatusStrip(),
          Expanded(
            child: networkAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => FailureView(
                failure: asAppFailure(error, stackTrace),
                onRetry: () => ref.invalidate(networkScopeProvider),
              ),
              data: (network) => network.networkId == null
                  ? const Center(
                      child: Text('Aktif bir ağ arayüzü tespit edilemedi.'),
                    )
                  : _DevicesBody(network: network),
            ),
          ),
        ],
      ),
    );
  }
}

class _DevicesBody extends ConsumerWidget {
  const _DevicesBody({required this.network});

  final ActiveNetwork network;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(networkDevicesProvider(network.networkId!));
    final query = ref.watch(deviceQueryProvider);
    final viewMode = ref.watch(deviceViewModeProvider);
    final selectedId = ref.watch(selectedDeviceIdProvider);
    final traffic = ref.watch(todayTrafficTotalsProvider).value;

    return devicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          FailureView(failure: asAppFailure(error, stackTrace)),
      data: (devices) {
        if (devices.isEmpty) return const _EmptyDevices();

        final visible = applyDeviceQuery(
          devices,
          query,
          dailyTrafficBytes: {
            for (final MapEntry(:key, :value)
                in (traffic?.byDevice ?? const {}).entries)
              key: value.totalBytes,
          },
        );
        final newIds = newDeviceIds(devices);
        final subnets =
            <Cidr>{
                for (final subnet in network.snapshot.accessibleSubnets)
                  subnet.cidr,
                ?network.snapshot.activeInterface?.cidr,
              }.toList()
              ..sort((a, b) => a.networkAddress.compareTo(b.networkAddress));

        return LayoutBuilder(
          builder: (context, constraints) {
            final showPane =
                constraints.maxWidth >= DevicesScreen._detailPaneBreakpoint;

            void select(Device device) {
              ref.read(selectedDeviceIdProvider.notifier).select(device.id);
              if (!showPane) {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Cihaz detayı')),
                      body: DeviceDetailPanel(deviceId: device.id),
                    ),
                  ),
                );
              }
            }

            final content = visible.isEmpty && viewMode == DeviceViewMode.list
                ? const Center(child: Text('Filtrelerle eşleşen cihaz yok.'))
                : switch (viewMode) {
                    DeviceViewMode.tree => DeviceTreeView(
                      roots: buildDeviceTree(
                        devices: visible,
                        subnets: network.snapshot.accessibleSubnets,
                        activeSubnet: network.snapshot.activeInterface?.cidr,
                      ),
                      forceExpandAll: query.hasFilters,
                      newDeviceIds: newIds,
                      onDeviceSelected: select,
                    ),
                    DeviceViewMode.list => DeviceTable(
                      devices: visible,
                      newDeviceIds: newIds,
                      onDeviceSelected: select,
                    ),
                    DeviceViewMode.map => DeviceMapView(
                      roots: buildDeviceTree(
                        devices: visible,
                        subnets: network.snapshot.accessibleSubnets,
                        activeSubnet: network.snapshot.activeInterface?.cidr,
                      ),
                      newDeviceIds: newIds,
                      onDeviceSelected: select,
                    ),
                  };

            return Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      DeviceToolbar(
                        subnets: subnets,
                        osNames: _valuesOf(devices, (d) => d.inferredOs),
                        vendors: _valuesOf(devices, (d) => d.vendor),
                        visibleCount: visible.length,
                        totalCount: devices.length,
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: KeyedSubtree(
                            key: ValueKey(viewMode),
                            child: content,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showPane && selectedId != null) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: 400,
                    child: DeviceDetailPanel(
                      key: ValueKey(selectedId),
                      deviceId: selectedId,
                      onClose: () => ref
                          .read(selectedDeviceIdProvider.notifier)
                          .select(null),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

/// Distinct values present among [devices], sorted, with "Bilinmiyor" last
/// when some device has none.
List<String> _valuesOf(List<Device> devices, String? Function(Device) of) {
  final values = <String>{};
  var hasUnknown = false;
  for (final device in devices) {
    final value = of(device);
    if (value == null) {
      hasUnknown = true;
    } else {
      values.add(value);
    }
  }
  return [
    ...values.toList()..sort(),
    if (hasUnknown && values.isNotEmpty) DeviceQuery.unknownValue,
  ];
}

class _EmptyDevices extends ConsumerWidget {
  const _EmptyDevices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedHugeIcon(
              HugeIcons.strokeRoundedRadar01,
              size: 40,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu ağda henüz cihaz bulunmadı. Bir tarama başlatın; bulunan '
              'cihazlar tarama bitmeden burada görünür.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ref
                  .read(shellDestinationProvider.notifier)
                  .go(ShellDestination.scanScopes),
              icon: const ThemedHugeIcon(HugeIcons.strokeRoundedPlay, size: 18),
              label: const Text('Taramaya git'),
            ),
          ],
        ),
      ),
    );
  }
}
