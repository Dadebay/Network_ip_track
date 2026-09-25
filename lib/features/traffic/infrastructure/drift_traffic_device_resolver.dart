import '../../../core/database/app_database.dart' as db;
import '../../../core/utils/mac_address.dart';
import '../domain/entities/traffic_device_identity.dart';
import '../domain/repositories/traffic_device_resolver.dart';

/// Resolves provider MAC/IP bindings against the `devices` table (read-only),
/// **within the active network only**: the router's counters describe the
/// network the Mac is on now, and the same MAC can be recorded on another
/// network (home vs office) — that device must never receive this usage.
///
/// MAC wins. IP is only used when the provider reported no MAC *and* exactly
/// one device of the active network currently has that IP. With no active
/// network, nothing is resolved (usage is dropped, not guessed).
class DriftTrafficDeviceResolver implements TrafficDeviceResolver {
  DriftTrafficDeviceResolver(
    this._database, {
    required Future<int?> Function() activeNetworkId,
  }) : _activeNetworkId = activeNetworkId;

  final db.AppDatabase _database;
  final Future<int?> Function() _activeNetworkId;

  Future<List<db.Device>> _activeNetworkDevices() async {
    final networkId = await _activeNetworkId();
    if (networkId == null) return const [];
    return (_database.select(
      _database.devices,
    )..where((row) => row.networkId.equals(networkId))).get();
  }

  @override
  Future<Map<String, int>> resolveDeviceIds(
    Iterable<TrafficDeviceIdentity> identities,
  ) async {
    final wanted = identities.toList();
    if (wanted.isEmpty) return const {};

    final rows = await _activeNetworkDevices();
    final byMac = <String, db.Device>{};
    final byIp = <String, List<db.Device>>{};
    for (final row in rows) {
      final mac = row.macAddress == null
          ? null
          : normalizeMacAddress(row.macAddress!);
      if (mac != null) {
        final existing = byMac[mac];
        if (existing == null || row.lastSeenAt.isAfter(existing.lastSeenAt)) {
          byMac[mac] = row;
        }
      }
      (byIp[row.currentIp] ??= []).add(row);
    }

    final resolved = <String, int>{};
    for (final identity in wanted) {
      final mac = identity.macAddress;
      final ip = identity.ipAddress;
      if (mac != null) {
        final device = byMac[mac];
        if (device != null) resolved[identity.counterKey] = device.id;
      } else if (ip != null) {
        final candidates = byIp[ip];
        if (candidates != null && candidates.length == 1) {
          resolved[identity.counterKey] = candidates.single.id;
        }
      }
    }
    return resolved;
  }

  /// MAC/IP bindings of the active network's devices, for the demo
  /// provider.
  Future<List<TrafficDeviceIdentity>> knownIdentities() async {
    final rows = await _activeNetworkDevices();
    return [
      for (final row in rows)
        ?TrafficDeviceIdentity.tryCreate(
          macAddress: row.macAddress,
          ipAddress: row.currentIp,
        ),
    ];
  }
}
