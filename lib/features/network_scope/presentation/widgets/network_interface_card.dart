import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/page_layout.dart';
import '../../../../app/widgets/themed_huge_icon.dart';
import '../../domain/entities/network_interface_info.dart';
import 'interface_kind_label.dart';

class NetworkInterfaceCard extends StatelessWidget {
  const NetworkInterfaceCard({super.key, required this.interface});

  final NetworkInterfaceInfo interface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fields = [
      ('IPv4', interface.address.toString()),
      if (interface.gatewayAddress != null)
        ('Gateway', interface.gatewayAddress.toString()),
      ('CIDR', interface.cidr.toString()),
      ('Alt ağ maskesi', interface.subnetMask.toString()),
      ('Broadcast', interface.broadcastAddress.toString()),
      ('Arayüz', interface.name),
    ];

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(icon: interface.kind.icon, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interface.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        StatusPill(
                          text: interface.kind.label,
                          color: scheme.secondary,
                        ),
                        if (interface.isDefaultRoute)
                          StatusPill(
                            text: 'Aktif ağ',
                            color: Colors.green.shade400,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (interface.isDefaultRoute)
                ThemedHugeIcon(
                  HugeIcons.strokeRoundedCheckmarkCircle02,
                  size: 22,
                  color: Colors.green.shade400,
                ),
            ],
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              // Divisors of the field count, so no row is left half empty.
              final w = constraints.maxWidth;
              final columns = w >= 6 * 140
                  ? 6
                  : w >= 3 * 140
                  ? 3
                  : 2;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final (label, value) in fields)
                    SizedBox(
                      width: width,
                      child: _InfoTile(label: label, value: value),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              SelectableText(
                value,
                maxLines: 1,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
