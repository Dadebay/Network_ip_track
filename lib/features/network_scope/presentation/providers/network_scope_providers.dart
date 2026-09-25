import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/utils/cidr.dart';
import '../../application/detect_network_scope_use_case.dart';
import '../../domain/entities/network_scope_snapshot.dart';
import '../../domain/repositories/network_interface_provider.dart';
import '../../domain/repositories/route_provider.dart';
import '../../infrastructure/macos/macos_network_interface_provider.dart';
import '../../infrastructure/macos/macos_route_provider.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final networkInterfaceAdapterProvider = Provider<NetworkInterfaceProvider>((
  ref,
) {
  return const MacosNetworkInterfaceProvider();
});

final routeAdapterProvider = Provider<RouteProvider>((ref) {
  return const MacosRouteProvider();
});

final detectNetworkScopeUseCaseProvider = Provider<DetectNetworkScopeUseCase>((
  ref,
) {
  return DetectNetworkScopeUseCase(
    interfaceProvider: ref.watch(networkInterfaceAdapterProvider),
    routeProvider: ref.watch(routeAdapterProvider),
  );
});

/// Detects the current network scope. Re-run by invalidating this provider
/// (refresh / retry button).
final networkScopeProvider = FutureProvider.autoDispose<NetworkScopeSnapshot>((
  ref,
) {
  return ref.watch(detectNetworkScopeUseCaseProvider)();
});

/// The detected network plus its `networks` row id — the key devices and
/// scan sessions hang off. Persists the active interface as a side effect.
class ActiveNetwork {
  const ActiveNetwork({required this.snapshot, required this.networkId});

  final NetworkScopeSnapshot snapshot;

  /// Null when no active interface could be selected.
  final int? networkId;
}

final activeNetworkProvider = FutureProvider.autoDispose<ActiveNetwork>((
  ref,
) async {
  final snapshot = await ref.watch(networkScopeProvider.future);
  final activeInterface = snapshot.activeInterface;
  if (activeInterface == null) {
    return ActiveNetwork(snapshot: snapshot, networkId: null);
  }
  final networkId = await ref
      .watch(appDatabaseProvider)
      .upsertActiveNetwork(
        interfaceName: activeInterface.name,
        displayName: activeInterface.displayName,
        cidr: activeInterface.cidr.toString(),
        gatewayIp: activeInterface.gatewayAddress?.toString(),
        observedAt: snapshot.detectedAt,
      );
  return ActiveNetwork(snapshot: snapshot, networkId: networkId);
});

/// The network the Mac is on right now: its `networks` row plus the
/// interface and subnet that define it.
class CurrentNetwork {
  const CurrentNetwork({
    required this.networkId,
    required this.interfaceName,
    required this.cidr,
  });

  final int networkId;
  final String interfaceName;
  final Cidr cidr;
}

/// Re-detects the active network (read-only: never inserts a `networks`
/// row). Null when there is no active interface or it was never recorded.
/// Results are cached briefly because detection spawns system tools and
/// periodic callers (scan network guard, traffic polling) ask often.
final currentNetworkLookupProvider =
    Provider<Future<CurrentNetwork?> Function()>((ref) {
      const maxAge = Duration(seconds: 30);
      DateTime? cachedAt;
      Future<CurrentNetwork?>? cached;

      Future<CurrentNetwork?> detect() async {
        final snapshot = await ref.read(detectNetworkScopeUseCaseProvider)();
        final active = snapshot.activeInterface;
        if (active == null) return null;
        final networkId = await ref
            .read(appDatabaseProvider)
            .findNetworkId(
              interfaceName: active.name,
              cidr: active.cidr.toString(),
            );
        if (networkId == null) return null;
        return CurrentNetwork(
          networkId: networkId,
          interfaceName: active.name,
          cidr: active.cidr,
        );
      }

      return () {
        final now = DateTime.now();
        if (cached == null ||
            cachedAt == null ||
            now.difference(cachedAt!) > maxAge) {
          cachedAt = now;
          cached = detect().catchError((Object error) {
            // Don't cache a failure.
            cached = null;
            throw error;
          });
        }
        return cached!;
      };
    });
