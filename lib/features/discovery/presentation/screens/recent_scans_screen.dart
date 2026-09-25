import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/shell_navigation.dart';
import '../../../../app/widgets/failure_view.dart';
import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/scan_session_record.dart';
import '../providers/scan_providers.dart';
import '../widgets/scan_labels.dart';

/// History of scan sessions, newest first.
class RecentScansScreen extends ConsumerWidget {
  const RecentScansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(recentSessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Son taramalar')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => FailureView(
          failure: asAppFailure(error, stackTrace),
          onRetry: () => ref.invalidate(recentSessionsProvider),
        ),
        data: (sessions) => sessions.isEmpty
            ? const Center(child: Text('Henüz tarama yapılmadı.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: sessions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _SessionCard(session: sessions[index]),
              ),
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  const _SessionCard({required this.session});

  final ScanSessionRecord session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chunks = session.checkpoint?.chunks ?? const [];
    final total = chunks.fold(0, (sum, c) => sum + c.hostsTotal);
    final targets = session.targetCidrs.length <= 4
        ? session.targetCidrs.join(', ')
        : '${session.targetCidrs.take(4).join(', ')} ve '
              '${formatCount(session.targetCidrs.length - 4)} parça daha';
    final isRunning = ref.watch(
      scanControllerProvider.select((state) => state.isRunning),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ThemedHugeIcon(
              session.status.icon,
              color: session.status.color(theme.colorScheme),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${session.status.label} · ${formatDateTime(session.startedAt)}'
                    '${session.finishedAt == null ? '' : ' – ${formatDateTime(session.finishedAt!)}'}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(targets, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${formatCount(session.hostsScanned)}'
                    '${total == 0 ? '' : ' / ${formatCount(total)}'} host tarandı · '
                    '${formatCount(session.devicesFound)} cihaz bulundu',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (session.errorMessage != null)
                    Text(
                      session.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            if (session.isResumable && !isRunning)
              TextButton.icon(
                onPressed: () => ref
                    .read(shellDestinationProvider.notifier)
                    .go(ShellDestination.scanScopes),
                icon: const ThemedHugeIcon(
                  HugeIcons.strokeRoundedPlay,
                  size: 16,
                ),
                label: const Text('Devam ettir'),
              ),
          ],
        ),
      ),
    );
  }
}
