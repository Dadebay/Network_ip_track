import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/utils/formatters.dart';
import '../providers/scan_providers.dart';

/// Compact running-scan indicator for the device view, so results can be
/// watched streaming in while the scan runs.
class ScanStatusStrip extends ConsumerWidget {
  const ScanStatusStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(scanControllerProvider);
    final progress = state.progress;
    if (!state.isRunning) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final percent = progress == null
        ? null
        : (progress.fractionComplete * 100).toStringAsFixed(1);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          children: [
            Row(
              children: [
                const ThemedHugeIcon(HugeIcons.strokeRoundedRadar01, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    progress == null
                        ? 'Tarama başlatılıyor…'
                        : 'Tarama sürüyor · %$percent · '
                              '${formatCount(progress.devicesFoundTotal)} cihaz · '
                              '${progress.stage.label}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: progress == null
                      ? null
                      : ref.read(scanControllerProvider.notifier).pause,
                  icon: const ThemedHugeIcon(
                    HugeIcons.strokeRoundedPause,
                    size: 16,
                  ),
                  label: const Text('Duraklat'),
                ),
                TextButton.icon(
                  onPressed: progress == null
                      ? null
                      : ref.read(scanControllerProvider.notifier).cancel,
                  icon: const ThemedHugeIcon(
                    HugeIcons.strokeRoundedStop,
                    size: 16,
                  ),
                  label: const Text('İptal'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(value: progress?.fractionComplete),
          ],
        ),
      ),
    );
  }
}
