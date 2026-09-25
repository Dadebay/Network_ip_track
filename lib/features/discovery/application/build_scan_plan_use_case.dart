import '../../../core/errors/app_failure.dart';
import '../../../core/utils/cidr.dart';
import '../../../core/utils/private_network_blocks.dart';
import '../../network_scope/domain/entities/network_scope_snapshot.dart';
import 'chunk_cidr.dart';
import '../domain/entities/scan_chunk.dart';
import '../domain/entities/scan_plan.dart';
import '../domain/entities/scan_scope_type.dart';
import '../domain/entities/scan_settings.dart';

/// Resolves a [ScanScopeType] (plus network scope + optional custom CIDR)
/// into a concrete, chunked [ScanPlan] the UI can preview before starting.
class BuildScanPlanUseCase {
  const BuildScanPlanUseCase();

  ScanPlan call({
    required ScanScopeType scopeType,
    required NetworkScopeSnapshot networkScope,
    ScanSettings settings = const ScanSettings(),
    Cidr? customCidr,
  }) {
    final targetCidrs = _resolveTargetCidrs(
      scopeType,
      networkScope,
      customCidr,
    );
    final chunks =
        targetCidrs
            .expand(chunkCidrInto24s)
            .toSet()
            .map((cidr) => ScanChunk(cidr: cidr))
            .toList()
          ..sort(
            (a, b) => a.cidr.networkAddress.compareTo(b.cidr.networkAddress),
          );

    return ScanPlan(scopeType: scopeType, chunks: chunks, settings: settings);
  }

  List<Cidr> _resolveTargetCidrs(
    ScanScopeType scopeType,
    NetworkScopeSnapshot networkScope,
    Cidr? customCidr,
  ) {
    switch (scopeType) {
      case ScanScopeType.currentSubnet:
        final activeInterface = networkScope.activeInterface;
        if (activeInterface == null) {
          throw InvalidScanScopeFailure(
            userMessage:
                'Taranacak aktif bir ağ arayüzü yok. Önce Ağlar sekmesinden bir ağ tespit edin.',
          );
        }
        return [activeInterface.cidr];

      case ScanScopeType.allAccessiblePrivate172:
        if (networkScope.accessibleSubnets.isEmpty) {
          throw InvalidScanScopeFailure(
            userMessage:
                'Route tablosunda erişilebilir özel 172 alt ağı bulunamadı.',
          );
        }
        return networkScope.accessibleSubnets
            .map((subnet) => subnet.cidr)
            .toList();

      case ScanScopeType.customCidr:
        if (customCidr == null) {
          throw InvalidScanScopeFailure(
            userMessage: 'Önce taranacak bir CIDR girin.',
          );
        }
        if (!isWithinPrivate172Block(customCidr)) {
          throw InvalidScanScopeFailure(
            userMessage:
                'Girilen CIDR özel 172.16.0.0/12 bloğunun dışında. Yalnızca bu blok içindeki '
                'adresler taranabilir.',
          );
        }
        return [customCidr];

      case ScanScopeType.fullPrivate172Block:
        return [private172Block];
    }
  }
}
