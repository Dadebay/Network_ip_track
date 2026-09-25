import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/scan_chunk.dart';
import '../../domain/entities/scan_chunk_status.dart';
import '../../domain/entities/scan_progress.dart';
import 'scan_labels.dart';

/// Progress of the current scan: totals, elapsed/remaining time, and
/// per-chunk (per-subnet) progress.
class ScanProgressPanel extends ConsumerWidget {
  const ScanProgressPanel({
    super.key,
    required this.progress,
    required this.onPause,
    required this.onCancel,
    this.onResume,
  });

  final ScanProgress progress;
  final VoidCallback onPause;
  final VoidCallback onCancel;

  /// Shown for a paused scan.
  final VoidCallback? onResume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final remaining = progress.estimatedRemaining;
    final failure = progress.failure;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ThemedHugeIcon(
                  progress.status.icon,
                  color: progress.status.color(theme.colorScheme),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    progress.isActive
                        ? '${progress.status.label} · ${progress.stage.label}'
                        : progress.status.label,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (progress.isActive) ...[
                  OutlinedButton.icon(
                    onPressed: onPause,
                    icon: const ThemedHugeIcon(
                      HugeIcons.strokeRoundedPause,
                      size: 16,
                    ),
                    label: const Text('Duraklat'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const ThemedHugeIcon(
                      HugeIcons.strokeRoundedStop,
                      size: 16,
                    ),
                    label: const Text('İptal et'),
                  ),
                ] else if (onResume != null)
                  FilledButton.icon(
                    onPressed: onResume,
                    icon: const ThemedHugeIcon(
                      HugeIcons.strokeRoundedPlay,
                      size: 16,
                    ),
                    label: const Text('Devam et'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Semantics(
              label:
                  'Tarama ilerlemesi yüzde ${(progress.fractionComplete * 100).round()}',
              child: LinearProgressIndicator(value: progress.fractionComplete),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _Stat(
                  'Taranan host',
                  '${formatCount(progress.hostsScannedTotal)} / '
                      '${formatCount(progress.hostsTotal)}',
                ),
                _Stat('Bulunan cihaz', formatCount(progress.devicesFoundTotal)),
                _Stat('Geçen süre', formatDuration(progress.elapsed)),
                if (progress.isActive)
                  _Stat(
                    'Tahmini kalan',
                    remaining == null
                        ? 'Hesaplanıyor…'
                        : formatDuration(remaining),
                  ),
              ],
            ),
            if (failure != null) ...[
              const SizedBox(height: 12),
              Text(
                failure.userMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              if (failure.technicalDetail != null)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Teknik detay'),
                  children: [
                    SelectableText(
                      '${failure.technicalDetail}\n\nCorrelation ID: '
                      '${failure.correlationId}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
            ],
            const SizedBox(height: 16),
            Text('Alt ağ ilerlemesi', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _ChunkList(chunks: progress.chunks),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }
}

/// Up to thousands of chunks (the full /12 has 4096) — lazily built.
class _ChunkList extends StatelessWidget {
  const _ChunkList({required this.chunks});

  final List<ScanChunk> chunks;

  @override
  Widget build(BuildContext context) {
    // Unfinished work first, so the running chunk(s) are always in view —
    // several can be `running` at once when chunkConcurrency > 1.
    final ordered = [
      ...chunks.where((c) => c.status == ScanChunkStatus.running),
      ...chunks.where((c) => c.status != ScanChunkStatus.running),
    ];
    final height = (ordered.length * 36.0).clamp(36.0, 288.0);
    return SizedBox(
      height: height,
      child: ListView.builder(
        itemCount: ordered.length,
        itemExtent: 36,
        itemBuilder: (context, index) {
          final chunk = ordered[index];
          final fraction = chunk.hostsTotal == 0
              ? 0.0
              : chunk.hostsScanned / chunk.hostsTotal;
          return Row(
            children: [
              SizedBox(width: 150, child: Text(chunk.cidr.toString())),
              SizedBox(width: 100, child: Text(chunk.status.label)),
              Expanded(child: LinearProgressIndicator(value: fraction)),
              SizedBox(
                width: 130,
                child: Text(
                  '${chunk.hostsScanned}/${chunk.hostsTotal} · '
                  '${chunk.devicesFound} cihaz',
                  textAlign: TextAlign.end,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
