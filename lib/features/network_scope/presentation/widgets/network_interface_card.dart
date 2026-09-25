import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/themed_huge_icon.dart';
import '../../domain/entities/network_interface_info.dart';
import 'interface_kind_label.dart';

class NetworkInterfaceCard extends StatelessWidget {
  const NetworkInterfaceCard({super.key, required this.interface});

  final NetworkInterfaceInfo interface;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ThemedHugeIcon(interface.kind.icon),
                const SizedBox(width: 8),
                Text(interface.displayName, style: textTheme.titleMedium),
                const SizedBox(width: 8),
                Chip(label: Text(interface.kind.label)),
                if (interface.isDefaultRoute) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('Aktif ağ'),
                    avatar: ThemedHugeIcon(
                      HugeIcons.strokeRoundedCheckmarkCircle02,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                _InfoField(label: 'Arayüz', value: interface.name),
                _InfoField(label: 'IPv4', value: interface.address.toString()),
                _InfoField(
                  label: 'Alt ağ maskesi',
                  value: interface.subnetMask.toString(),
                ),
                _InfoField(label: 'CIDR', value: interface.cidr.toString()),
                _InfoField(
                  label: 'Broadcast',
                  value: interface.broadcastAddress.toString(),
                ),
                if (interface.gatewayAddress != null)
                  _InfoField(
                    label: 'Gateway',
                    value: interface.gatewayAddress.toString(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      label: '$label: $value',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: textTheme.labelSmall),
            Text(value, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
