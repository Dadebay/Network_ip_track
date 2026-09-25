import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/shell_navigation.dart';
import '../../../../app/widgets/failure_view.dart';
import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/cidr.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/private_network_blocks.dart';
import '../../../network_scope/presentation/providers/network_scope_providers.dart';
import '../../domain/entities/scan_plan.dart';
import '../../domain/entities/scan_scope_type.dart';
import '../../domain/entities/scan_session_record.dart';
import '../../domain/entities/scan_session_status.dart';
import '../providers/scan_providers.dart';
import '../widgets/scan_labels.dart';
import '../widgets/scan_progress_panel.dart';

/// Scope selection, the pre-scan preview (CIDRs, host count, estimated
/// duration, methods, concurrency/timeouts), and scan control/progress.
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkAsync = ref.watch(activeNetworkProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tarama kapsamları')),
      body: networkAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => FailureView(
          failure: asAppFailure(error, stackTrace),
          onRetry: () => ref.invalidate(networkScopeProvider),
        ),
        data: (network) => _ScanBody(network: network),
      ),
    );
  }
}

class _ScanBody extends ConsumerStatefulWidget {
  const _ScanBody({required this.network});

  final ActiveNetwork network;

  @override
  ConsumerState<_ScanBody> createState() => _ScanBodyState();
}

class _ScanBodyState extends ConsumerState<_ScanBody> {
  ScanScopeType _scope = ScanScopeType.allAccessiblePrivate172;
  final _cidrController = TextEditingController();

  @override
  void dispose() {
    _cidrController.dispose();
    super.dispose();
  }

  /// Validation message for the custom CIDR field, or null when valid.
  String? get _cidrError {
    final text = _cidrController.text.trim();
    if (text.isEmpty) return null;
    final Cidr cidr;
    try {
      cidr = Cidr.parse(text);
    } on FormatException {
      return 'Geçerli bir CIDR girin (ör. 172.16.20.0/24).';
    } on ArgumentError {
      return 'Prefix 0 ile 32 arasında olmalı.';
    }
    if (!isWithinPrivate172Block(cidr)) {
      return 'Yalnızca 172.16.0.0/12 içindeki ağlar taranabilir.';
    }
    return null;
  }

  (ScanPlan?, String?) _buildPlan() {
    Cidr? customCidr;
    if (_scope == ScanScopeType.customCidr) {
      final error = _cidrError;
      if (error != null) return (null, error);
      if (_cidrController.text.trim().isNotEmpty) {
        customCidr = Cidr.parse(_cidrController.text);
      }
    }
    try {
      final plan = ref.read(buildScanPlanUseCaseProvider)(
        scopeType: _scope,
        networkScope: widget.network.snapshot,
        settings: ref.watch(scanSettingsProvider),
        customCidr: customCidr,
      );
      return (plan, null);
    } on AppFailure catch (failure) {
      return (null, failure.userMessage);
    }
  }

  Future<void> _start(ScanPlan plan) async {
    if (plan.requiresConfirmation) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _LargeScanDialog(plan: plan),
      );
      if (confirmed != true) return;
    }
    await ref
        .read(scanControllerProvider.notifier)
        .start(plan, widget.network, confirmed: plan.requiresConfirmation);
  }

  Future<void> _resume(ScanSessionRecord session) =>
      ref.read(scanControllerProvider.notifier).resume(session, widget.network);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scanState = ref.watch(scanControllerProvider);
    final resumable = ref.watch(resumableSessionProvider).value;
    final (plan, planError) = _buildPlan();
    final progress = scanState.progress;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _AuthorizationNotice(),
        if (resumable != null && !scanState.isRunning)
          _ResumeBanner(
            session: resumable,
            onResume: () => _resume(resumable),
            onDiscard: () =>
                ref.read(scanControllerProvider.notifier).discard(resumable),
          ),
        if (scanState.failure != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(child: FailureView(failure: scanState.failure!)),
          ),
        if (progress != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ScanProgressPanel(
              progress: progress,
              onPause: ref.read(scanControllerProvider.notifier).pause,
              onCancel: ref.read(scanControllerProvider.notifier).cancel,
              onResume:
                  progress.status == ScanSessionStatus.paused &&
                      resumable?.id == progress.sessionId
                  ? () => _resume(resumable!)
                  : null,
            ),
          ),
        Text('Kapsam', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        RadioGroup<ScanScopeType>(
          groupValue: _scope,
          onChanged: (value) {
            if (value != null && !scanState.isRunning) {
              setState(() => _scope = value);
            }
          },
          child: Column(
            children: [
              for (final scope in ScanScopeType.values)
                RadioListTile<ScanScopeType>(
                  value: scope,
                  enabled: !scanState.isRunning,
                  title: Text(
                    scope == ScanScopeType.allAccessiblePrivate172
                        ? '${scope.label} (önerilen)'
                        : scope.label,
                  ),
                  subtitle: Text(_scopeDescription(scope)),
                ),
            ],
          ),
        ),
        if (_scope == ScanScopeType.customCidr)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _cidrController,
              enabled: !scanState.isRunning,
              decoration: InputDecoration(
                labelText: 'CIDR',
                hintText: '172.16.20.0/24',
                helperText: '172.16.0.0/12 içinde ve yetkili olduğunuz bir ağ',
                errorText: _cidrError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        const SizedBox(height: 16),
        Text('Tarama önizlemesi', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (plan == null)
          Text(planError ?? 'Kapsam seçin.', style: theme.textTheme.bodyMedium)
        else
          _PlanPreview(plan: plan),
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton.icon(
              onPressed: plan == null || scanState.isRunning
                  ? null
                  : () => _start(plan),
              icon: const ThemedHugeIcon(HugeIcons.strokeRoundedPlay, size: 18),
              label: Text(
                scanState.isRunning ? 'Tarama sürüyor' : 'Taramayı başlat',
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => ref
                  .read(shellDestinationProvider.notifier)
                  .go(ShellDestination.settings),
              child: const Text('Tarama ayarları'),
            ),
          ],
        ),
      ],
    );
  }

  String _scopeDescription(ScanScopeType scope) {
    final snapshot = widget.network.snapshot;
    return switch (scope) {
      ScanScopeType.currentSubnet =>
        snapshot.activeInterface == null
            ? 'Aktif arayüz yok'
            : '${snapshot.activeInterface!.cidr} · ${snapshot.activeInterface!.displayName}',
      ScanScopeType.allAccessiblePrivate172 =>
        snapshot.accessibleSubnets.isEmpty
            ? 'Route tablosunda erişilebilir özel 172 alt ağı yok'
            : snapshot.accessibleSubnets.map((s) => s.cidr).join(', '),
      ScanScopeType.customCidr =>
        'Yalnızca 172.16.0.0/12 içinde, yetkili olduğunuz bir CIDR',
      ScanScopeType.fullPrivate172Block =>
        'Gelişmiş: 1.048.576 adres. Onay gerektirir; parçalı kuyruk, '
            'duraklat/devam et desteği.',
    };
  }
}

/// Shown for any plan over one /24's worth of hosts, whichever scope option
/// produced it.
class _LargeScanDialog extends StatelessWidget {
  const _LargeScanDialog({required this.plan});

  final ScanPlan plan;

  @override
  Widget build(BuildContext context) {
    final targets = {
      for (final chunk in plan.chunks) chunk.cidr.toString(),
    }.toList();
    final isFullBlock = plan.scopeType == ScanScopeType.fullPrivate172Block;
    return AlertDialog(
      title: const Text('Büyük tarama başlatılsın mı?'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Text(
          '${plan.scopeType.label}: ${formatCount(plan.totalCandidateHosts)} '
          'adres, ${formatCount(plan.chunks.length)} parça '
          '(${targets.length <= 3 ? targets.join(', ') : '${targets.take(3).join(', ')} …'}). '
          'Tahmini süre: ${formatDuration(plan.estimatedDuration)}.\n\n'
          '${isFullBlock ? 'Route bulunmayan alt ağlara giden istekler cevapsız kalır. ' : ''}'
          'Yalnızca bu adreslerin tamamını yönetme yetkiniz varsa başlatın. '
          'Tarama istediğiniz an duraklatılıp daha sonra — uygulama yeniden '
          'açıldıktan sonra bile — devam ettirilebilir.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yetkiliyim, başlat'),
        ),
      ],
    );
  }
}

class _AuthorizationNotice extends StatelessWidget {
  const _AuthorizationNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          ThemedHugeIcon(
            HugeIcons.strokeRoundedShield01,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Yalnızca yönetme izniniz olan ağlarda kullanın. Tarama düşük '
              'hızdadır ve yalnızca cihaz keşfi yapar: güvenlik açığı arama, '
              'parola deneme veya kapsamlı port taraması yapılmaz.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({
    required this.session,
    required this.onResume,
    required this.onDiscard,
  });

  final ScanSessionRecord session;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final chunks = session.checkpoint?.chunks ?? const [];
    final total = chunks.fold(0, (sum, c) => sum + c.hostsTotal);
    final done = chunks.fold(0, (sum, c) => sum + c.hostsScanned);
    final percent = total == 0 ? 0 : (done * 100 / total).round();
    final targets = session.targetCidrs.length <= 3
        ? session.targetCidrs.join(', ')
        : '${session.targetCidrs.take(3).join(', ')} ve '
              '${session.targetCidrs.length - 3} parça daha';

    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const ThemedHugeIcon(HugeIcons.strokeRoundedPause),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tamamlanmamış tarama: $targets · %$percent · '
                '${formatDateTime(session.startedAt)} tarihinde başladı',
              ),
            ),
            TextButton(onPressed: onDiscard, child: const Text('Vazgeç')),
            const SizedBox(width: 8),
            FilledButton(onPressed: onResume, child: const Text('Devam et')),
          ],
        ),
      ),
    );
  }
}

class _PlanPreview extends StatelessWidget {
  const _PlanPreview({required this.plan});

  final ScanPlan plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = plan.settings;
    const shownCidrs = 12;
    final cidrs = plan.chunks.map((c) => c.cidr.toString()).toList();

    Widget row(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            row(
              'CIDR listesi (${formatCount(cidrs.length)} parça)',
              cidrs.length <= shownCidrs
                  ? cidrs.join(', ')
                  : '${cidrs.take(shownCidrs).join(', ')} … ve '
                        '${formatCount(cidrs.length - shownCidrs)} parça daha',
            ),
            row(
              'Toplam aday IP',
              '${formatCount(plan.totalCandidateHosts)} '
                  '(${formatCount(plan.totalAddresses)} adres; her parçanın '
                  'ağ ve broadcast adresi atlanır)',
            ),
            row('Tahmini süre', formatDuration(plan.estimatedDuration)),
            row(
              'Keşif yöntemleri',
              plan.methods.map((method) => method.label).join(', '),
            ),
            row(
              'Eşzamanlılık / zaman aşımı',
              '${settings.concurrency} eşzamanlı · ping '
                  '${settings.pingTimeout.inMilliseconds} ms · port '
                  '${settings.portProbeTimeout.inMilliseconds} ms',
            ),
            row('Kontrol edilen portlar', settings.limitedPorts.join(', ')),
          ],
        ),
      ),
    );
  }
}
