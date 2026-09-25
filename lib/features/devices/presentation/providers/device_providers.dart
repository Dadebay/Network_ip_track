import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../network_scope/presentation/providers/network_scope_providers.dart';
import '../../application/device_query.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/device_observation.dart';
import '../../domain/repositories/device_repository.dart';
import '../../infrastructure/drift_device_repository.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DriftDeviceRepository(ref.watch(appDatabaseProvider));
});

final networkDevicesProvider = StreamProvider.autoDispose
    .family<List<Device>, int>((ref, networkId) {
      return ref
          .watch(deviceRepositoryProvider)
          .watchDevicesForNetwork(networkId);
    });

final deviceProvider = StreamProvider.autoDispose.family<Device?, int>((
  ref,
  deviceId,
) {
  return ref.watch(deviceRepositoryProvider).watchDevice(deviceId);
});

final deviceObservationsProvider = StreamProvider.autoDispose
    .family<List<DeviceObservation>, int>((ref, deviceId) {
      return ref.watch(deviceRepositoryProvider).watchObservations(deviceId);
    });

enum DeviceViewMode { tree, list, map }

class DeviceQueryController extends Notifier<DeviceQuery> {
  @override
  DeviceQuery build() => const DeviceQuery();

  void update(DeviceQuery Function(DeviceQuery current) change) {
    state = change(state);
  }

  void reset() => state = DeviceQuery(
    sortField: state.sortField,
    ascending: state.ascending,
  );
}

final deviceQueryProvider =
    NotifierProvider<DeviceQueryController, DeviceQuery>(
      DeviceQueryController.new,
    );

class DeviceViewModeController extends Notifier<DeviceViewMode> {
  @override
  DeviceViewMode build() => DeviceViewMode.tree;

  void set(DeviceViewMode mode) => state = mode;
}

final deviceViewModeProvider =
    NotifierProvider<DeviceViewModeController, DeviceViewMode>(
      DeviceViewModeController.new,
    );

class SelectedDeviceController extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? deviceId) => state = deviceId;
}

final selectedDeviceIdProvider =
    NotifierProvider<SelectedDeviceController, int?>(
      SelectedDeviceController.new,
    );

/// Tree node ids the user has toggled away from [isExpandedByDefault] (see
/// `device_tree.dart`) — not "the collapsed set" itself, since a group's
/// default is closed while everything else's is open. Starting empty means
/// starting at the type defaults: blocks/subnets/gateways open, groups
/// closed.
class TreeNodeTogglesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String nodeId) {
    state = state.contains(nodeId)
        ? ({...state}..remove(nodeId))
        : {...state, nodeId};
  }
}

final treeNodeTogglesProvider =
    NotifierProvider<TreeNodeTogglesController, Set<String>>(
      TreeNodeTogglesController.new,
    );
