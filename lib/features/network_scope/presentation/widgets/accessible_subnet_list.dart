import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/themed_huge_icon.dart';
import '../../domain/entities/accessible_subnet.dart';
import '../../domain/entities/subnet_reachability.dart';

class AccessibleSubnetList extends StatelessWidget {
  const AccessibleSubnetList({super.key, required this.subnets});

  final List<AccessibleSubnet> subnets;

  @override
  Widget build(BuildContext context) {
    if (subnets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Route tablosunda erişilebilir özel 172 alt ağı bulunamadı.',
        ),
      );
    }

    return Column(
      children: [
        for (final subnet in subnets)
          Card(
            child: ListTile(
              leading: ThemedHugeIcon(_iconFor(subnet.reachability)),
              title: Text(subnet.cidr.toString()),
              subtitle: Text(
                [
                  _labelFor(subnet.reachability),
                  if (subnet.viaInterface != null)
                    'arayüz: ${subnet.viaInterface}',
                  if (subnet.gateway != null) 'gateway: ${subnet.gateway}',
                ].join(' · '),
              ),
            ),
          ),
      ],
    );
  }

  List<List<dynamic>> _iconFor(SubnetReachability reachability) =>
      switch (reachability) {
        SubnetReachability.directlyConnected => HugeIcons.strokeRoundedLink01,
        SubnetReachability.routed => HugeIcons.strokeRoundedRoute01,
        SubnetReachability.unreachable => HugeIcons.strokeRoundedUnlink01,
      };

  String _labelFor(SubnetReachability reachability) => switch (reachability) {
    SubnetReachability.directlyConnected => 'Doğrudan bağlı',
    SubnetReachability.routed => 'Router üzerinden erişilebilir',
    SubnetReachability.unreachable => 'Erişilemiyor',
  };
}
