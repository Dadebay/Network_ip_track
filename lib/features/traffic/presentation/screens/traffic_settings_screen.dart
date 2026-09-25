import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/failure_view.dart';
import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/traffic_connection_test_result.dart';
import '../../domain/entities/traffic_settings.dart';
import '../../domain/failures/traffic_failures.dart';
import '../../domain/repositories/traffic_provider.dart';
import '../../infrastructure/fortigate/fortigate_traffic_provider.dart';
import '../widgets/fortigate_settings_section.dart';
import '../providers/traffic_providers.dart';

/// Traffic provider selection ("Keşif modu" vs. a provider), connection test,
/// collection status and retention/unit preferences.
class TrafficSettingsScreen extends ConsumerWidget {
  const TrafficSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(trafficSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Trafik kaynağı')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => FailureView(
          failure: asAppFailure(error, stackTrace),
          onRetry: () => ref.invalidate(trafficSettingsProvider),
        ),
        data: (settings) => _SettingsContent(settings: settings),
      ),
    );
  }
}

class _SettingsContent extends ConsumerStatefulWidget {
  const _SettingsContent({required this.settings});

  final TrafficSettings settings;

  @override
  ConsumerState<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends ConsumerState<_SettingsContent> {
  bool _switching = false;
  bool _testing = false;
  TrafficConnectionTestResult? _testResult;
  AppFailure? _switchFailure;

  TrafficSettings get settings => widget.settings;

  Future<void> _select(String? providerId) async {
    if (providerId == null || providerId == settings.providerId) return;
    setState(() {
      _switching = true;
      _testResult = null;
      _switchFailure = null;
    });
    try {
      await ref
          .read(trafficSettingsProvider.notifier)
          .selectProvider(providerId);
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _switchFailure = asAppFailure(error, stackTrace));
      }
    } finally {
      if (mounted) setState(() => _switching = false);
    }
  }

  Future<void> _test(TrafficProvider provider) async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final result = await provider.testConnection();
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providers = ref.watch(availableTrafficProvidersProvider);
    final selected = providers
        .where((provider) => provider.descriptor.id == settings.providerId)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Mod', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        RadioGroup<String>(
          groupValue: settings.providerId,
          onChanged: (value) {
            if (!_switching) _select(value);
          },
          child: Column(
            children: [
              RadioListTile<String>(
                value: TrafficSettings.noProviderId,
                title: const Text('Keşif modu'),
                subtitle: const Text(
                  'Cihazlar bulunur; cihaz başına trafik ölçülmez ve '
                  'uydurulmaz.',
                ),
                enabled: !_switching,
              ),
              for (final provider in providers)
                RadioListTile<String>(
                  key: ValueKey('traffic-provider-${provider.descriptor.id}'),
                  value: provider.descriptor.id,
                  title: Text(provider.descriptor.displayName),
                  subtitle: Text(provider.descriptor.description),
                  enabled: !_switching,
                ),
            ],
          ),
        ),
        if (_switching) const LinearProgressIndicator(),
        if (_switchFailure != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _switchFailure!.userMessage,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        if (settings.providerId == FortiGateTrafficProvider.providerId) ...[
          const FortiGateSettingsSection(),
        ] else
          const _RouterAdapterNotice(),
        const Divider(height: 32),
        Text('Bağlantı testi', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (selected == null)
          Text(
            'Keşif modunda test edilecek bir trafik kaynağı yok.',
            style: theme.textTheme.bodyMedium,
          )
        else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _testing || _switching ? null : () => _test(selected),
              icon: _testing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const ThemedHugeIcon(
                      HugeIcons.strokeRoundedConnect,
                      size: 18,
                    ),
              label: const Text('Bağlantıyı test et'),
            ),
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 12),
            _TestResultView(result: _testResult!),
          ],
          const SizedBox(height: 12),
          const _CollectionStatusView(),
        ],
        const Divider(height: 32),
        Text('Saklama ve birimler', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            const Expanded(child: Text('Günlük trafik geçmişi')),
            DropdownButton<int>(
              value:
                  TrafficSettings.dailyRetentionChoices.contains(
                    settings.dailyRetentionDays,
                  )
                  ? settings.dailyRetentionDays
                  : null,
              hint: Text('${settings.dailyRetentionDays} gün'),
              items: [
                for (final days in TrafficSettings.dailyRetentionChoices)
                  DropdownMenuItem(value: days, child: Text('$days gün')),
              ],
              onChanged: (days) {
                if (days != null) {
                  ref
                      .read(trafficSettingsProvider.notifier)
                      .setDailyRetentionDays(days);
                }
              },
            ),
          ],
        ),
        Text(
          'Ham örnekler 48 saat, saatlik özetler 8 gün saklanır; daha eskisi '
          'günlük toplamlara indirgenir.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Expanded(child: Text('Boyut birimi')),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('MB (1000²)')),
                ButtonSegment(value: true, label: Text('MiB (1024²)')),
              ],
              selected: {settings.useBinaryUnits},
              onSelectionChanged: (selection) => ref
                  .read(trafficSettingsProvider.notifier)
                  .setUseBinaryUnits(selection.single),
            ),
          ],
        ),
      ],
    );
  }
}

class _RouterAdapterNotice extends StatelessWidget {
  const _RouterAdapterNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ThemedHugeIcon(
            HugeIcons.strokeRoundedRouter,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bu ağın gateway\'i bir FortiGate. FortiGate seçilince cihaz '
              'başına trafik, güvenlik duvarının trafik loglarından salt '
              'okunur olarak alınır. Başka bir router için adapter ancak '
              'marka/model ve API bilgisiyle eklenir. Kimlik bilgileri '
              'yalnızca macOS Keychain\'de saklanır.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _TestResultView extends ConsumerWidget {
  const _TestResultView({required this.result});

  final TrafficConnectionTestResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final failure = result.failure;
    final color = failure == null
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ThemedHugeIcon(
          failure == null
              ? HugeIcons.strokeRoundedCheckmarkCircle02
              : HugeIcons.strokeRoundedAlertCircle,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(failure?.userMessage ?? result.message ?? ''),
              if (result.deviceCount != null && failure == null)
                Text(
                  '${result.deviceCount} cihaz için sayaç bulundu.',
                  style: theme.textTheme.bodySmall,
                ),
              if (failure is FortiGateUntrustedCertificateFailure) ...[
                const SizedBox(height: 6),
                SelectableText(
                  'SHA-256: ${failure.presentedSha256}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Menlo',
                  ),
                ),
                const SizedBox(height: 6),
                OutlinedButton(
                  onPressed: () => ref
                      .read(fortiGateConfigProvider.notifier)
                      .trustCertificate(failure.presentedSha256),
                  child: const Text('Parmak izi aynı — bu sertifikaya güven'),
                ),
              ],
              if (failure != null && failure.technicalDetail != null)
                Text(
                  failure.technicalDetail!,
                  style: theme.textTheme.bodySmall,
                ),
              if (failure != null)
                Text(
                  'Hata kimliği: ${failure.correlationId}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollectionStatusView extends ConsumerWidget {
  const _CollectionStatusView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(trafficCollectionProvider);
    final theme = Theme.of(context);
    final report = status.lastReport;
    final lastPoll = status.lastPollAt;

    final lines = <String>[
      if (lastPoll == null)
        'Henüz sayaç okunmadı.'
      else
        'Son okuma: ${_time(lastPoll)}',
      if (report != null) ...[
        '${report.readings} kayıt okundu, ${report.samplesWritten} örnek '
            'kaydedildi.',
        if (report.counterResets > 0)
          '${report.counterResets} sayaç resetlendi; negatif fark kullanım '
              'sayılmadı.',
        if (report.truncated)
          'Kaynakta tek okumada alınabilecekten fazla kayıt vardı; bazı eski '
              'kayıtlar atlanmış olabilir.',
        if (report.unresolvedDevices > 0)
          '${report.unresolvedDevices} sayaç bilinen bir cihazla '
              'eşleşmedi.',
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines) Text(line, style: theme.textTheme.bodySmall),
        if (status.lastFailure != null)
          Text(
            status.lastFailure!.userMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
      ],
    );
  }

  static String _time(DateTime time) {
    final local = time.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}
