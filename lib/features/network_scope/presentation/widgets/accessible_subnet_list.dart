import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/page_layout.dart';
import '../../domain/entities/accessible_subnet.dart';
import '../../domain/entities/subnet_reachability.dart';

class AccessibleSubnetList extends StatelessWidget {
  const AccessibleSubnetList({super.key, required this.subnets});

  final List<AccessibleSubnet> subnets;

  @override
  Widget build(BuildContext context) {
    if (subnets.isEmpty) {
      return const SurfaceCard(
        child: Text(
          'Route tablosunda erişilebilir özel 172 alt ağı bulunamadı.',
        ),
      );
    }

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (final (index, subnet) in subnets.indexed) ...[
            if (index > 0) const Divider(height: 1),
            _SubnetRow(subnet: subnet),
          ],
        ],
      ),
    );
  }
}

class _SubnetRow extends StatelessWidget {
  const _SubnetRow({required this.subnet});

  final AccessibleSubnet subnet;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final (icon, label, color) = switch (subnet.reachability) {
      SubnetReachability.directlyConnected => (
        HugeIcons.strokeRoundedLink01,
        'Doğrudan bağlı',
        Colors.green.shade400,
      ),
      SubnetReachability.routed => (
        HugeIcons.strokeRoundedRoute01,
        'Router üzerinden',
        scheme.primary,
      ),
      SubnetReachability.unreachable => (
        HugeIcons.strokeRoundedUnlink01,
        'Erişilemiyor',
        scheme.error,
      ),
    };
    final details = [
      if (subnet.viaInterface != null) 'arayüz: ${subnet.viaInterface}',
      if (subnet.gateway != null) 'gateway: ${subnet.gateway}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconBadge(icon: icon, color: color, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subnet.cidr.toString(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          StatusPill(text: label, color: color),
        ],
      ),
    );
  }
}
