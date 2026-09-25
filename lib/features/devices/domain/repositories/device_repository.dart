import '../../../../core/utils/cidr.dart';
import '../../../classification/domain/entities/device_classification.dart';
import '../../../discovery/domain/entities/discovered_device.dart';
import '../entities/device.dart';
import '../entities/device_observation.dart';
import '../entities/device_type.dart';

/// Persistence + dedup for `devices`/`device_observations`.
///
/// Merge rule (per spec): match by MAC when known; otherwise match by
/// (network, current IP) as a temporary identity. If a device later reveals
/// its MAC, its temp-IP row is merged into the MAC-identified row rather
/// than creating a duplicate, and IP history is preserved across DHCP
/// reassignment via `device_observations`.
abstract interface class DeviceRepository {
  /// The inferred type (and, separately, OS) is only replaced by a verdict
  /// of at least the stored confidence, so a later scan that happens to see
  /// fewer signals never downgrades an earlier, better-supported
  /// classification. [vendor] is stored when known. User-entered fields are
  /// never touched.
  Future<int> upsertDiscoveredDevice({
    required int networkId,
    required DiscoveredDevice discovered,
    required DeviceClassification classification,
    String? vendor,
    bool isGateway = false,
    bool isLocalDevice = false,
  });

  /// Live-updating device list for a network — the source the tree/list
  /// views watch while a scan streams results in.
  Stream<List<Device>> watchDevicesForNetwork(int networkId);

  Future<List<Device>> getDevicesForNetwork(int networkId);

  Stream<Device?> watchDevice(int deviceId);

  /// Newest first.
  Stream<List<DeviceObservation>> watchObservations(int deviceId);

  /// Ages devices inside [scannedCidrs] that a completed scan did not see
  /// (last seen before [seenSince]): `online` becomes `unknown`, and only an
  /// already-`unknown` device becomes `offline` — so one missed probe is
  /// never an offline verdict (spec limitation #6).
  Future<void> markUnseenDevices({
    required int networkId,
    required List<Cidr> scannedCidrs,
    required DateTime seenSince,
  });

  /// Saves the user's own name/type/note and "Bu cihazı tanıyorum". These
  /// always win over automatic classification and survive later scans.
  /// Every field is written as given: null clears it.
  Future<void> updateUserInfo({
    required int deviceId,
    required String? customName,
    required DeviceType? customType,
    required String? note,
    required bool isKnown,
  });
}
