import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/shell_navigation.dart';
import '../../../../app/widgets/failure_view.dart';
import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/formatters.dart';
import '../../../traffic/presentation/widgets/device_traffic_section.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/device_confidence.dart';
import '../../domain/entities/device_observation.dart';
import '../../domain/entities/device_type.dart';
import 'device_user_info_dialog.dart';
import '../providers/device_providers.dart';
import 'device_visuals.dart';

/// Device detail: identity and network info, the user's own name/type/note,
/// inferred type/OS with their confidence and reasons, discovery signals,
/// seen services, traffic and IP history.
class DeviceDetailPanel extends ConsumerWidget {
  const DeviceDetailPanel({super.key, required this.deviceId, this.onClose});

  final int deviceId;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceProvider(deviceId));
    return deviceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          FailureView(failure: asAppFailure(error, stackTrace)),
      data: (device) {
        if (device == null) {
          return const Center(child: Text('Cihaz artık kayıtlı değil.'));
        }
        final observations =
            ref.watch(deviceObservationsProvider(deviceId)).value ?? const [];
        return _DetailContent(
          device: device,
          observations: observations,
          onClose: onClose,
        );
      },
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({
    required this.device,
    required this.observations,
    this.onClose,
  });

  final Device device;
  final List<DeviceObservation> observations;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final latest = observations.firstOrNull;
    final services = {...?latest?.services}.toList();
    final signals = {...?latest?.signals}.toList();
    final ports = [
      for (final signal in signals)
        if (signal.startsWith('Port ')) signal,
    ];
    final reasons = [
      for (final signal in signals)
        if (!signal.startsWith('Port ')) signal,
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            ThemedHugeIcon(deviceTypeIcon(device.effectiveType), size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    device.displayName,
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      DeviceStatusBadge(status: device.status),
                      DeviceTags(device: device),
                    ],
                  ),
                ],
              ),
            ),
            if (onClose != null)
              IconButton(
                tooltip: 'Detayı kapat',
                onPressed: onClose,
                icon: const ThemedHugeIcon(HugeIcons.strokeRoundedCancel01),
              ),
          ],
        ),
        _Section(
          title: 'Kimlik ve ağ',
          children: [
            _InfoRow('IP', device.currentIp.toString()),
            _InfoRow(
              'MAC',
              device.macAddress ?? 'Bilinmiyor',
              hint: device.macAddress == null
                  ? 'MAC yalnızca aynı yerel segmentteki cihazlar için '
                        'öğrenilebilir; routed alt ağlarda bilinmeyebilir.'
                  : null,
            ),
            _InfoRow('Hostname', device.hostname ?? 'Bilinmiyor'),
            _InfoRow('Üretici', device.vendor ?? 'Bilinmiyor'),
            _InfoRow('İlk görülme', formatDateTime(device.firstSeenAt)),
            _InfoRow('Son görülme', formatDateTime(device.lastSeenAt)),
          ],
        ),
        _UserInfoSection(device: device),
        _Section(
          title: 'Tahmini tür ve işletim sistemi',
          children: [
            _InfoRow(
              'Tür',
              device.inferredType == DeviceType.unknown
                  ? 'Bilinmiyor'
                  : '${device.inferredType.label} · ${device.confidence.label}',
              hint: device.customType == null
                  ? null
                  : 'Kullanıcının seçtiği tür (${device.customType!.label}) '
                        'bu tahminin önüne geçer.',
            ),
            _InfoRow('İşletim sistemi', deviceOsWithConfidence(device)),
            if (device.inferenceReasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Gerekçeler', style: theme.textTheme.labelLarge),
              for (final reason in device.inferenceReasons) _Bullet(reason),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Tür ve işletim sistemi tahmindir: MAC üreticisi, hostname, '
                'mDNS, SSDP, NetBIOS, TTL ve açık portlar yalnızca olasılık '
                'sağlar.',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
        if (reasons.isNotEmpty)
          _Section(
            title: 'Son keşif sinyalleri',
            children: [for (final reason in reasons) _Bullet(reason)],
          ),
        _Section(
          title: 'Görülen servisler',
          children: [
            if (services.isEmpty && ports.isEmpty)
              Text(
                'Son taramada servis veya açık port görülmedi.',
                style: theme.textTheme.bodySmall,
              ),
            for (final service in services) _Bullet(service),
            for (final port in ports) _Bullet(port),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: DeviceTrafficSection(
            deviceId: device.id,
            onOpenTrafficSettings: () => ref
                .read(shellDestinationProvider.notifier)
                .go(ShellDestination.settings),
          ),
        ),
        _Section(
          title: 'IP geçmişi',
          children: [
            for (final entry in _ipHistory(observations))
              _InfoRow(
                entry.ip,
                entry.first == entry.last
                    ? formatDateTime(entry.last)
                    : '${formatDateTime(entry.first)} – ${formatDateTime(entry.last)}',
              ),
          ],
        ),
      ],
    );
  }

  /// Distinct IPs from observations (newest first), each with the span it
  /// was observed at.
  static List<({String ip, DateTime first, DateTime last})> _ipHistory(
    List<DeviceObservation> observations,
  ) {
    final spans = <String, ({DateTime first, DateTime last})>{};
    for (final observation in observations) {
      final ip = observation.ipAddress.toString();
      final at = observation.observedAt;
      final span = spans[ip];
      spans[ip] = span == null
          ? (first: at, last: at)
          : (
              first: at.isBefore(span.first) ? at : span.first,
              last: at.isAfter(span.last) ? at : span.last,
            );
    }
    return [
      for (final MapEntry(:key, :value) in spans.entries)
        (ip: key, first: value.first, last: value.last),
    ]..sort((a, b) => b.last.compareTo(a.last));
  }
}

class _UserInfoSection extends ConsumerWidget {
  const _UserInfoSection({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return _Section(
      title: 'Kullanıcı bilgileri',
      children: [
        _InfoRow('Özel ad', device.customName ?? '—'),
        _InfoRow('Özel tür', device.customType?.label ?? 'Otomatik'),
        _InfoRow('Not', device.note ?? '—'),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Bu cihazı tanıyorum'),
          value: device.isKnown,
          onChanged: (value) => ref
              .read(deviceRepositoryProvider)
              .updateUserInfo(
                deviceId: device.id,
                customName: device.customName,
                customType: device.customType,
                note: device.note,
                isKnown: value,
              ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => DeviceUserInfoDialog(device: device),
            ),
            icon: const ThemedHugeIcon(HugeIcons.strokeRoundedEdit02, size: 16),
            label: const Text('Düzenle'),
          ),
        ),
        Text(
          'Kendi girdiğiniz ad, tür ve not otomatik tahminin önüne geçer ve '
          'sonraki taramalarda korunur.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.hint});

  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(value),
                if (hint != null) Text(hint!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: SelectableText(text)),
        ],
      ),
    );
  }
}
