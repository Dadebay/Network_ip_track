import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/failure_view.dart';
import '../../../../app/widgets/page_layout.dart';
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
      body: scopeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => FailureView(
          failure: asAppFailure(error, stackTrace),
          onRetry: () => ref.invalidate(networkScopeProvider),
        ),
        data: (snapshot) => _NetworkScopeContent(snapshot: snapshot),
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

    return PageListView(
      maxContentWidth: 980,
      children: [
        const InfoBanner(
          icon: HugeIcons.strokeRoundedShield01,
          message:
              'Yalnızca yönetme izniniz olan ağlarda kullanın. Otomatik kapsam '
              'yalnızca özel 172.16.0.0/12 bloğuyla sınırlıdır.',
        ),
        const SizedBox(height: 24),
        PageSection(
          title: 'Aktif ağ',
          subtitle: 'Bu Mac\'in varsayılan route için kullandığı arayüz.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (snapshot.defaultRouteViaVpn)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: InfoBanner(
                    icon: HugeIcons.strokeRoundedLockKey,
                    message:
                        'Varsayılan route bir VPN tüneli üzerinden gidiyor; '
                        'aşağıda fiziksel ağ arayüzünüz gösteriliyor.',
                  ),
                ),
              if (activeInterface == null)
                const SurfaceCard(
                  child: Text('Aktif bir ağ arayüzü tespit edilemedi.'),
                )
              else
                NetworkInterfaceCard(interface: activeInterface),
            ],
          ),
        ),
        const SizedBox(height: 28),
        PageSection(
          title: 'Erişilebilir özel 172 ağları',
          subtitle: 'Route tablosuna göre bu Mac\'in ulaşabildiği alt ağlar.',
          child: AccessibleSubnetList(subnets: snapshot.accessibleSubnets),
        ),
      ],
    );
  }
}
