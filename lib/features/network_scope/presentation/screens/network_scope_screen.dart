import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/failure_view.dart';
import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/network_scope_snapshot.dart';
import '../providers/network_scope_providers.dart';
import '../widgets/accessible_subnet_list.dart';
import '../widgets/network_interface_card.dart';

class NetworkScopeScreen extends ConsumerWidget {
  const NetworkScopeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scopeAsync = ref.watch(networkScopeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ağlar'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const ThemedHugeIcon(HugeIcons.strokeRoundedRefresh),
            onPressed: () => ref.invalidate(networkScopeProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          const _ScopeWarningBanner(),
          Expanded(
            child: scopeAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => FailureView(
                failure: asAppFailure(error, stackTrace),
                onRetry: () => ref.invalidate(networkScopeProvider),
              ),
              data: (snapshot) => _NetworkScopeContent(snapshot: snapshot),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopeWarningBanner extends StatelessWidget {
  const _ScopeWarningBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          ThemedHugeIcon(
            HugeIcons.strokeRoundedShield01,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Yalnızca yönetme izniniz olan ağlarda kullanın. Otomatik kapsam yalnızca özel 172.16.0.0/12 bloğuyla sınırlıdır.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkScopeContent extends StatelessWidget {
  const _NetworkScopeContent({required this.snapshot});

  final NetworkScopeSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final activeInterface = snapshot.activeInterface;
    final accessibleSubnets = snapshot.accessibleSubnets;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Aktif ağ', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (snapshot.defaultRouteViaVpn)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedHugeIcon(
                  HugeIcons.strokeRoundedLockKey,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Varsayılan route bir VPN tüneli üzerinden gidiyor; aşağıda fiziksel ağ arayüzünüz gösteriliyor.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        if (activeInterface == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Aktif bir ağ arayüzü tespit edilemedi.'),
          )
        else
          NetworkInterfaceCard(interface: activeInterface),
        const SizedBox(height: 24),
        Text(
          'Erişilebilir özel 172 ağları',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        AccessibleSubnetList(subnets: accessibleSubnets),
      ],
    );
  }
}
