import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/shell_navigation.dart';
import '../../../../app/widgets/failure_view.dart';
import '../../../../app/widgets/page_layout.dart';
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
    final scanState = ref.watch(scanControllerProvider);
    final resumable = ref.watch(resumableSessionProvider).value;
    final (plan, planError) = _buildPlan();
    final progress = scanState.progress;
    final running = scanState.isRunning;

    final scopeSection = PageSection(
      title: 'Kapsam',
      subtitle: 'Hangi adreslerin taranacağını seçin.',
      child: RadioGroup<ScanScopeType>(
        groupValue: _scope,
        onChanged: (value) {
          if (value != null && !running) setState(() => _scope = value);
        },
        child: Column(
          children: [
            for (final scope in ScanScopeType.values)
              _ScopeOption(
                scope: scope,
                description: _scopeDescription(scope),
                selected: scope == _scope,
                enabled: !running,
                onTap: () => setState(() => _scope = scope),
                child: scope == ScanScopeType.customCidr
                    ? TextField(
                        controller: _cidrController,
                        enabled: !running,
                        decoration: InputDecoration(
                          labelText: 'CIDR',
                          hintText: '172.16.20.0/24',
                          helperText:
                              '172.16.0.0/12 içinde ve yetkili olduğunuz bir ağ',
                          errorText: _cidrError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );

    final previewSection = PageSection(
      title: 'Tarama önizlemesi',
      subtitle: 'Başlatmadan önce ne yapılacağını kontrol edin.',
      child: _PlanPreview(
        plan: plan,
        error: planError,
        running: running,
        onStart: plan == null || running ? null : () => _start(plan),
        onOpenSettings: () => ref
            .read(shellDestinationProvider.notifier)
            .go(ShellDestination.settings),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        return PageListView(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: InfoBanner(
                icon: HugeIcons.strokeRoundedShield01,
                title: 'Yalnızca yetkili olduğunuz ağlarda kullanın',
                message:
                    'Tarama düşük hızdadır ve yalnızca cihaz keşfi yapar: '
                    'güvenlik açığı arama, parola deneme veya kapsamlı port '
                    'taraması yapılmaz.',
              ),
            ),
            if (resumable != null && !running)
              _ResumeBanner(
                session: resumable,
                onResume: () => _resume(resumable),
                onDiscard: () => ref
                    .read(scanControllerProvider.notifier)
                    .discard(resumable),
              ),
            if (scanState.failure != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(child: FailureView(failure: scanState.failure!)),
              ),
            if (progress != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
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
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 11, child: scopeSection),
                  const SizedBox(width: 24),
                  Expanded(flex: 9, child: previewSection),
                ],
              )
            else ...[
              scopeSection,
              const SizedBox(height: 28),
              previewSection,
            ],
          ],
        );
      },
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
        '1.048.576 adres. Onay gerektirir; parçalı kuyruk, '
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

/// A selectable card for one scope option; the radio stays in the card so
/// the whole card and the radio both select it.
class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.scope,
    required this.description,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.child,
  });

  final ScanScopeType scope;
  final String description;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  /// Extra input shown inside the card while it is selected.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, badge) = switch (scope) {
      ScanScopeType.currentSubnet => (HugeIcons.strokeRoundedWifi01, null),
      ScanScopeType.allAccessiblePrivate172 => (
        HugeIcons.strokeRoundedHierarchySquare02,
        StatusPill(text: 'Önerilen', color: scheme.primary),
      ),
      ScanScopeType.customCidr => (HugeIcons.strokeRoundedEdit02, null),
      ScanScopeType.fullPrivate172Block => (
        HugeIcons.strokeRoundedGlobe02,
        StatusPill(text: 'Gelişmiş', color: scheme.tertiary),
      ),
    };
    final radius = BorderRadius.circular(14);

    return Opacity(
      opacity: enabled || selected ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer.withValues(alpha: 0.35)
                : scheme.surfaceContainerLow,
            borderRadius: radius,
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: radius,
              onTap: enabled ? onTap : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? scheme.primary.withValues(alpha: 0.15)
                                : scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ThemedHugeIcon(
                            icon,
                            size: 20,
                            color: selected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    scope.label,
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  ?badge,
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Radio<ScanScopeType>(value: scope, enabled: enabled),
                      ],
                    ),
                    if (selected && child != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(54, 14, 8, 0),
                        child: child,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
  const _PlanPreview({
    required this.plan,
    required this.error,
    required this.running,
    required this.onStart,
    required this.onOpenSettings,
  });

  final ScanPlan? plan;
  final String? error;
  final bool running;
  final VoidCallback? onStart;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final plan = this.plan;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (plan == null)
            Row(
              children: [
                ThemedHugeIcon(
                  HugeIcons.strokeRoundedInformationCircle,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error ?? 'Kapsam seçin.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            )
          else
            _stats(plan),
          const SizedBox(height: 16),
          // Right under the summary, so it's visible without scrolling.
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: onStart,
              icon: const ThemedHugeIcon(HugeIcons.strokeRoundedPlay, size: 18),
              label: Text(running ? 'Tarama sürüyor' : 'Taramayı başlat'),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: TextButton.icon(
              onPressed: onOpenSettings,
              icon: const ThemedHugeIcon(
                HugeIcons.strokeRoundedSettings01,
                size: 16,
              ),
              label: const Text('Tarama ayarları'),
            ),
          ),
          if (plan != null) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 16),
            ..._details(context, plan),
          ],
        ],
      ),
    );
  }

  Widget _stats(ScanPlan plan) => Row(
    children: [
      Expanded(
        child: _StatTile(
          icon: HugeIcons.strokeRoundedGridView,
          label: 'Aday IP',
          value: formatCount(plan.totalCandidateHosts),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatTile(
          icon: HugeIcons.strokeRoundedTimer02,
          label: 'Tahmini süre',
          value: formatDuration(plan.estimatedDuration),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatTile(
          icon: HugeIcons.strokeRoundedLayers01,
          label: 'Parça',
          value: formatCount(plan.chunks.length),
        ),
      ),
    ],
  );

  List<Widget> _details(BuildContext context, ScanPlan plan) {
    final settings = plan.settings;
    const shownCidrs = 12;
    final cidrs = plan.chunks.map((c) => c.cidr.toString()).toList();
    return [
      _Detail(
        label: 'CIDR listesi (${formatCount(cidrs.length)} parça)',
        child: SelectableText(
          cidrs.length <= shownCidrs
              ? cidrs.join(', ')
              : '${cidrs.take(shownCidrs).join(', ')} … ve '
                    '${formatCount(cidrs.length - shownCidrs)} parça daha',
        ),
      ),
      _Detail(
        label: 'Toplam aday IP',
        child: Text(
          '${formatCount(plan.totalCandidateHosts)} '
          '(${formatCount(plan.totalAddresses)} adres; her parçanın ağ ve '
          'broadcast adresi atlanır)',
        ),
      ),
      _Detail(
        label: 'Keşif yöntemleri',
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final method in plan.methods) _Tag(method.label)],
        ),
      ),
      _Detail(
        label: 'Eşzamanlılık / zaman aşımı',
        child: Text(
          '${settings.concurrency} eşzamanlı · ping '
          '${settings.pingTimeout.inMilliseconds} ms · port '
          '${settings.portProbeTimeout.inMilliseconds} ms',
        ),
      ),
      _Detail(
        label: 'Kontrol edilen portlar',
        last: true,
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final port in settings.limitedPorts) _Tag('$port', mono: true),
          ],
        ),
      ),
    ];
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ThemedHugeIcon(icon, size: 14, color: scheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.child, this.last = false});

  final String label;
  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          DefaultTextStyle.merge(
            style: theme.textTheme.bodyMedium,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.mono = false});

  final String text;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
        ),
      ),
    );
  }
}
