import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/page_layout.dart';
import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../devices/domain/entities/device.dart';
import '../../../devices/presentation/providers/device_providers.dart';
import '../../application/wifi_matching.dart';
import '../../domain/entities/wifi_scan.dart';
import '../providers/network_scope_providers.dart';

/// Nearby Wi-Fi networks, each with the LAN device that most likely
/// broadcasts it.
class WifiNetworksSection extends ConsumerWidget {
  const WifiNetworksSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanAsync = ref.watch(wifiScanProvider);
    final scan = scanAsync.value;
    if (scan?.status == WifiScanStatus.unsupported) {
      return const SizedBox.shrink();
    }
    final networkId = ref.watch(activeNetworkProvider).value?.networkId;
    final devices = networkId == null
        ? const <Device>[]
        : ref.watch(networkDevicesProvider(networkId)).value ??
              const <Device>[];

    return PageSection(
      title: 'Çevredeki Wi-Fi ağları',
      subtitle:
          'Mac\'in Wi-Fi\'sinin gördüğü ağlar ve onları yayınlayan tahmini '
          'cihaz.',
      child: SurfaceCard(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(switch (scan?.currentSsid) {
                    final ssid? => 'Bu Mac şu an "$ssid" ağına bağlı.',
                    _ => scanAsync.isLoading ? 'Taranıyor…' : '',
                  }, style: Theme.of(context).textTheme.bodySmall),
                ),
                IconButton(
                  tooltip: 'Wi-Fi ağlarını yeniden tara',
                  onPressed: scanAsync.isLoading
                      ? null
                      : () => ref.invalidate(wifiScanProvider),
                  icon: const ThemedHugeIcon(
                    HugeIcons.strokeRoundedRefresh,
                    size: 18,
                  ),
                ),
              ],
            ),
            if (scan != null) ..._body(context, scan, devices),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(
    BuildContext context,
    WifiScan scan,
    List<Device> devices,
  ) {
    final theme = Theme.of(context);
    final message = switch (scan.status) {
      WifiScanStatus.denied =>
        'macOS, Wi-Fi adlarını yalnızca Konum izni olan uygulamalara '
            'gösterir. Sistem Ayarları › Gizlilik ve Güvenlik › Konum '
            'Servisleri\'nden bu uygulamaya izin verin, sonra yeniden tarayın.',
      WifiScanStatus.wifiOff => 'Wi-Fi kapalı. Açıp yeniden tarayın.',
      WifiScanStatus.noWifi => 'Bu Mac\'te Wi-Fi arayüzü bulunamadı.',
      WifiScanStatus.error => 'Wi-Fi taraması başarısız oldu.',
      _ => null,
    };
    if (message != null) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 8, 8),
          child: Text(message, style: theme.textTheme.bodyMedium),
        ),
      ];
    }
    final networks = [
      for (final network in scan.networks)
        if (network.ssid != null) network,
    ]..sort((a, b) => b.rssi.compareTo(a.rssi));
    if (networks.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 8, 8),
          child: Text(
            'Wi-Fi ağı görülmedi.',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ];
    }
    return [
      for (final (i, network) in networks.indexed) ...[
        if (i > 0) const Divider(height: 1),
        _WifiRow(
          network: network,
          connected:
              network.bssid != null && network.bssid == scan.currentBssid,
          device: devices
              .where((d) => wifiNetworksFor(d.macAddress, [network]).isNotEmpty)
              .firstOrNull,
        ),
      ],
    ];
  }
}

class _WifiRow extends StatelessWidget {
  const _WifiRow({
    required this.network,
    required this.connected,
    required this.device,
  });

  final WifiNetwork network;
  final bool connected;
  final Device? device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final strength = network.rssi >= -60
        ? scheme.primary
        : network.rssi >= -75
        ? scheme.tertiary
        : scheme.outline;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 8, 10),
      child: Row(
        children: [
          IconBadge(
            icon: HugeIcons.strokeRoundedWifi01,
            color: strength,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        network.ssid!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (connected) ...[
                      const SizedBox(width: 8),
                      StatusPill(text: 'Bağlı', color: Colors.green.shade400),
                    ],
                  ],
                ),
                Text(
                  [
                    network.band,
                    if (network.channel != null) 'kanal ${network.channel}',
                    '${network.rssi} dBm',
                    ?network.bssid,
                  ].where((part) => part.isNotEmpty).join(' · '),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (device case final device?)
            Tooltip(
              message:
                  'Tahmini: yayın adresi bu cihazın MAC adresine çok yakın.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    device.hasName ? device.displayName : 'Adsız',
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    device.currentIp.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              'Ağda eşleşme yok',
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
            ),
        ],
      ),
    );
  }
}
