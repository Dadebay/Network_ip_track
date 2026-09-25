import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/failure_view.dart';
import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/device_traffic_summary.dart';
import '../../domain/entities/traffic_reliability.dart';
import '../formatting/byte_format.dart';
import '../providers/traffic_providers.dart';
import '../screens/traffic_settings_screen.dart';
import 'traffic_bar_chart.dart';

/// Traffic block for the device detail screen: today's download/upload/total,
/// the last 24 hours by hour and the last 7 days by day.
///
/// Without a traffic provider it explains that per-device traffic is not
/// available — it never shows `0 MB` for unknown usage.
class DeviceTrafficSection extends ConsumerWidget {
  const DeviceTrafficSection({
    super.key,
    required this.deviceId,
    this.onOpenTrafficSettings,
  });

  final int deviceId;

  /// Opens the traffic setup. Defaults to pushing [TrafficSettingsScreen].
  final VoidCallback? onOpenTrafficSettings;

  static const unavailableMessage =
      'Bu router cihaz başına trafik verisi sağlamıyor veya entegrasyon '
      'kurulmadı';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trafficAsync = ref.watch(deviceTrafficProvider(deviceId));
    final openSettings =
        onOpenTrafficSettings ??
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const TrafficSettingsScreen(),
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: trafficAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => FailureView(
            failure: asAppFailure(error, stackTrace),
            onRetry: () => ref.invalidate(deviceTrafficProvider(deviceId)),
          ),
          data: (state) => switch (state) {
            DeviceTrafficUnavailable() => _Unavailable(
              onOpenSettings: openSettings,
            ),
            DeviceTrafficAvailable() => _TrafficContent(state: state),
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({this.trailing});

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ThemedHugeIcon(HugeIcons.strokeRoundedArrowDataTransferVertical),
        const SizedBox(width: 8),
        Expanded(
          child: Text('Trafik', style: Theme.of(context).textTheme.titleMedium),
        ),
        ?trailing,
      ],
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(),
        const SizedBox(height: 12),
        Text(
          DeviceTrafficSection.unavailableMessage,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Cihaz başına trafik için router API\'si, NetFlow/sFlow/IPFIX veya '
          'gateway üzerinde çalışan bir ölçüm sistemi gerekir.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onOpenSettings,
          icon: const ThemedHugeIcon(
            HugeIcons.strokeRoundedSettings02,
            size: 18,
          ),
          label: const Text('Trafik entegrasyonunu kur'),
        ),
      ],
    );
  }
}

class _TrafficContent extends StatelessWidget {
  const _TrafficContent({required this.state});

  final DeviceTrafficAvailable state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = state.summary;
    final binary = state.useBinaryUnits;
    final isDemo =
        state.provider.isDemo ||
        summary.worstReliability == TrafficReliability.simulated;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          trailing: isDemo
              ? const _DemoBadge()
              : Text(
                  state.provider.displayName,
                  style: theme.textTheme.labelSmall,
                ),
        ),
        if (isDemo) ...[
          const SizedBox(height: 8),
          Text(
            'Demo verisi: simüle edilmiştir, gerçek kullanım değildir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (!summary.hasAnyData)
          Text(
            'Bu cihaz için henüz trafik örneği toplanmadı. Sağlayıcı '
            'sayaçları okudukça veriler burada görünür.',
            style: theme.textTheme.bodyMedium,
          )
        else ...[
          Text('Bugün', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          if (summary.hasTodayData)
            _TodayTotals(
              key: const ValueKey('traffic-today-totals'),
              totals: summary.today,
              binary: binary,
            )
          else
            Text(
              'Bugün için henüz örnek yok.',
              style: theme.textTheme.bodyMedium,
            ),
          if (summary.worstReliability == TrafficReliability.estimated) ...[
            const SizedBox(height: 8),
            Text(
              'Gün sınırını aşan ölçüm aralıkları günlere orantılı '
              'dağıtıldı; bu kısımlar tahminidir.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text('Son 24 saat', style: theme.textTheme.labelLarge),
              ),
              const TrafficChartLegend(),
            ],
          ),
          const SizedBox(height: 8),
          TrafficBarChart(
            key: const ValueKey('traffic-hourly-chart'),
            buckets: summary.hourly,
            useBinaryUnits: binary,
            bottomLabel: (index, bucket) =>
                index % 6 == 0 ? _twoDigits(bucket.start.hour) : null,
            tooltipLabel: (bucket) =>
                '${_twoDigits(bucket.start.hour)}:00–'
                '${_twoDigits(bucket.end.hour)}:00',
          ),
          const SizedBox(height: 20),
          Text('Son 7 gün', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          TrafficBarChart(
            key: const ValueKey('traffic-daily-chart'),
            buckets: summary.daily,
            useBinaryUnits: binary,
            bottomLabel: (index, bucket) => _weekdays[bucket.start.weekday - 1],
            tooltipLabel: (bucket) =>
                '${_weekdays[bucket.start.weekday - 1]} '
                '${bucket.start.day}.${_twoDigits(bucket.start.month)}',
          ),
        ],
      ],
    );
  }

  static const _weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _TodayTotals extends StatelessWidget {
  const _TodayTotals({super.key, required this.totals, required this.binary});

  final TrafficTotals totals;
  final bool binary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 12,
      children: [
        _Stat(
          label: 'İndirme',
          value: formatBytes(totals.downloadBytes, binary: binary),
        ),
        _Stat(
          label: 'Yükleme',
          value: formatBytes(totals.uploadBytes, binary: binary),
        ),
        _Stat(
          label: 'Toplam',
          value: formatBytes(totals.totalBytes, binary: binary),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.titleLarge),
      ],
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'DEMO',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onErrorContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
