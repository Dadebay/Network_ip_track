import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/shell_navigation.dart';
import '../../../../app/widgets/failure_view.dart';
import '../../../../app/widgets/page_layout.dart';
import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/formatters.dart';
import '../../../network_scope/presentation/providers/network_scope_providers.dart';
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
    final latest = observations.firstOrNull;
    final services = {...?latest?.services}.toList();
    final signals = {...?latest?.signals}.toList();
    final history = _ipHistory(observations);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _Header(device: device, onClose: onClose),
        const SizedBox(height: 16),
        _Card(
          title: 'Genel',
          children: [
            _InfoRow('IP', device.currentIp.toString()),
            _InfoRow(
              'MAC',
              device.macAddress ?? 'Bilinmiyor',
              hint: device.macAddress == null
                  ? 'Yalnızca aynı yerel segmentteki cihazlarda öğrenilir.'
                  : null,
            ),
            if (device.model != null) _InfoRow('Model', device.model!),
            if (ref.watch(wifiNetworksForMacProvider(device.macAddress))
                case final wifi when wifi.isNotEmpty)
              _InfoRow(
                'Wi-Fi',
                [
                  for (final n in wifi) '${n.ssid} (${n.band}, ${n.rssi} dBm)',
                ].join('\n'),
                hint:
                    'Tahmini: yayın adresi (BSSID) cihazın MAC adresine çok '
                    'yakın.',
              ),
            if (device.vendor != null) _InfoRow('Üretici', device.vendor!),
            if (device.hostname != null &&
                device.shortHostname != device.displayName)
              _InfoRow('Hostname', device.hostname!),
            _InfoRow('Son görülme', formatDateTime(device.lastSeenAt)),
            _InfoRow('İlk görülme', formatDateTime(device.firstSeenAt)),
          ],
        ),
        _UserInfoCard(device: device),
        _GuessCard(device: device),
        if (signals.isNotEmpty)
          _Card(
            title: 'Keşif sinyalleri',
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [for (final signal in signals) _Chip(signal)],
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: DeviceTrafficSection(
            deviceId: device.id,
            onOpenTrafficSettings: () => ref
                .read(shellDestinationProvider.notifier)
                .go(ShellDestination.settings),
          ),
        ),
        if (services.isNotEmpty || history.length > 1)
          _Card(
            title: 'Teknik ayrıntılar',
            collapsible: true,
            children: [
              if (services.isNotEmpty) ...[
                _SubTitle('Görülen servisler'),
                for (final service in services) _Bullet(service),
              ],
              if (history.length > 1) ...[
                _SubTitle('IP geçmişi'),
                for (final entry in history)
                  _InfoRow(
                    entry.ip,
                    entry.first == entry.last
                        ? formatDateTime(entry.last)
                        : '${formatDateTime(entry.first)} – '
                              '${formatDateTime(entry.last)}',
                  ),
              ],
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

class _Header extends ConsumerWidget {
  const _Header({required this.device, this.onClose});

  final Device device;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final subtitle = [
      if (device.effectiveType != DeviceType.unknown) device.displayType,
      ?device.inferredOs,
    ].join(' · ');
    final webUri = device.webUri;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: deviceTypeIcon(device.effectiveType), size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    device.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
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
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => DeviceUserInfoDialog(device: device),
              ),
              icon: const ThemedHugeIcon(
                HugeIcons.strokeRoundedEdit02,
                size: 16,
              ),
              label: const Text('Düzenle'),
            ),
            if (webUri != null)
              OutlinedButton.icon(
                onPressed: () => openDeviceWebUi(webUri),
                icon: const ThemedHugeIcon(
                  HugeIcons.strokeRoundedLinkSquare02,
                  size: 16,
                ),
                label: const Text('Web arayüzü'),
              ),
          ],
        ),
      ],
    );
  }
}

class _UserInfoCard extends ConsumerWidget {
  const _UserInfoCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasInfo =
        device.customName != null ||
        device.customType != null ||
        device.note != null;
    return _Card(
      title: 'Kullanıcı bilgileri',
      children: [
        if (device.customName != null) _InfoRow('Özel ad', device.customName!),
        if (device.customType != null)
          _InfoRow('Özel tür', device.customType!.label),
        if (device.note != null) _InfoRow('Not', device.note!),
        if (!hasInfo)
          Text(
            'Ad, tür veya not eklemediniz. "Düzenle" ile ekleyebilirsiniz; '
            'otomatik tahminin önüne geçer.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
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
      ],
    );
  }
}

class _GuessCard extends StatelessWidget {
  const _GuessCard({required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = device.inferredType == DeviceType.unknown
        ? 'Bilinmiyor'
        : '${device.inferredType.label} · ${device.confidence.label}';
    return _Card(
      title: 'Otomatik tahmin',
      children: [
        _InfoRow(
          'Tür',
          type,
          hint: device.customType == null
              ? null
              : 'Seçtiğiniz tür (${device.customType!.label}) bu tahminin '
                    'önüne geçer.',
        ),
        _InfoRow('İşletim sistemi', deviceOsWithConfidence(device)),
        if (device.inferenceReasons.isNotEmpty)
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              dense: true,
              title: Text('Neden?', style: theme.textTheme.labelLarge),
              expandedAlignment: Alignment.centerLeft,
              children: [
                for (final reason in device.inferenceReasons) _Bullet(reason),
                const SizedBox(height: 4),
                Text(
                  'Tahmindir: üretici, hostname, mDNS, SSDP, NetBIOS, TTL ve '
                  'açık portlar yalnızca olasılık sağlar.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.children,
    this.collapsible = false,
  });

  final String title;
  final List<Widget> children;
  final bool collapsible;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = Semantics(
      header: true,
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SurfaceCard(
        padding: EdgeInsets.fromLTRB(14, collapsible ? 2 : 12, 14, 12),
        child: collapsible
            ? Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: heading,
                  expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [heading, const SizedBox(height: 8), ...children],
              ),
      ),
    );
  }
}

class _SubTitle extends StatelessWidget {
  const _SubTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
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
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hint != null)
                  Text(
                    hint!,
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: theme.textTheme.labelMedium),
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
          Expanded(
            child: SelectableText(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
