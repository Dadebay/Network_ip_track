import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/device_traffic_summary.dart';
import '../formatting/byte_format.dart';

/// Stacked download/upload bars, one per bucket. Buckets without samples are
/// left empty (and say "veri yok" on hover) instead of drawing a zero bar.
class TrafficBarChart extends StatelessWidget {
  const TrafficBarChart({
    super.key,
    required this.buckets,
    required this.bottomLabel,
    required this.tooltipLabel,
    this.useBinaryUnits = false,
    this.height = 180,
  });

  final List<TrafficBucket> buckets;

  /// Axis label for bucket [index], or null to leave it blank.
  final String? Function(int index, TrafficBucket bucket) bottomLabel;
  final String Function(TrafficBucket bucket) tooltipLabel;
  final bool useBinaryUnits;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final downloadColor = colors.primary;
    final uploadColor = colors.tertiary;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    final maxTotal = buckets.fold<int>(
      0,
      (max, bucket) => math.max(max, bucket.totals.totalBytes),
    );
    final maxY = maxTotal == 0 ? 1.0 : maxTotal * 1.15;
    final barWidth = buckets.length > 12 ? 7.0 : 18.0;

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: colors.outlineVariant.withValues(alpha: 0.5),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: maxTotal > 0,
                reservedSize: 56,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) {
                  if (value == meta.max) return const SizedBox.shrink();
                  return Text(
                    formatBytes(value.round(), binary: useBinaryUnits),
                    style: labelStyle,
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= buckets.length) {
                    return const SizedBox.shrink();
                  }
                  final label = bottomLabel(index, buckets[index]);
                  if (label == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(label, style: labelStyle),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => colors.inverseSurface,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final bucket = buckets[groupIndex];
                final style = theme.textTheme.bodySmall?.copyWith(
                  color: colors.onInverseSurface,
                );
                final body = bucket.hasData
                    ? '↓ ${formatBytes(bucket.totals.downloadBytes, binary: useBinaryUnits)}\n'
                          '↑ ${formatBytes(bucket.totals.uploadBytes, binary: useBinaryUnits)}'
                    : 'veri yok';
                return BarTooltipItem(
                  '${tooltipLabel(bucket)}\n$body',
                  style ?? const TextStyle(),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < buckets.length; i++)
              _group(i, buckets[i], barWidth, downloadColor, uploadColor),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _group(
    int index,
    TrafficBucket bucket,
    double width,
    Color downloadColor,
    Color uploadColor,
  ) {
    final down = bucket.totals.downloadBytes.toDouble();
    final total = bucket.totals.totalBytes.toDouble();
    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: total,
          width: width,
          color: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          rodStackItems: [
            BarChartRodStackItem(0, down, downloadColor),
            BarChartRodStackItem(down, total, uploadColor),
          ],
        ),
      ],
    );
  }
}

/// Download/upload color key shared by the charts.
class TrafficChartLegend extends StatelessWidget {
  const TrafficChartLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 16,
      children: [
        _LegendItem(color: colors.primary, label: 'İndirme'),
        _LegendItem(color: colors.tertiary, label: 'Yükleme'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
