import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../network_scope/presentation/providers/network_scope_providers.dart';
import '../../application/build_device_traffic_summary.dart';
import '../../application/local_time_buckets.dart';
import '../../application/traffic_collector.dart';
import '../../application/traffic_usage_collector.dart';
import '../../domain/entities/fortigate_config.dart';
import '../../domain/repositories/usage_cursor_store.dart';
import '../../infrastructure/file_usage_cursor_store.dart';
import '../../infrastructure/fortigate/file_fortigate_config_repository.dart';
import '../../infrastructure/fortigate/fortigate_traffic_provider.dart';
import '../../infrastructure/fortigate/fortigate_transport.dart';
import '../../domain/entities/device_traffic_summary.dart';
import '../../domain/entities/traffic_provider_descriptor.dart';
import '../../domain/entities/traffic_retention_policy.dart';
import '../../domain/entities/traffic_settings.dart';
import '../../domain/repositories/router_credential_store.dart';
import '../../domain/repositories/traffic_device_resolver.dart';
import '../../domain/repositories/traffic_provider.dart';
import '../../domain/repositories/traffic_sample_repository.dart';
import '../../domain/repositories/traffic_settings_repository.dart';
import '../../infrastructure/demo/demo_traffic_provider.dart';
import '../../infrastructure/drift_traffic_device_resolver.dart';
import '../../infrastructure/drift_traffic_sample_repository.dart';
import '../../infrastructure/file_traffic_settings_repository.dart';
import '../../infrastructure/keychain_router_credential_store.dart';

const _logger = AppLogger('traffic');

final trafficClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final trafficSettingsRepositoryProvider = Provider<TrafficSettingsRepository>(
  (ref) => FileTrafficSettingsRepository(),
);

/// Router credentials live only in the macOS Keychain.
final routerCredentialStoreProvider = Provider<RouterCredentialStore>(
  (ref) => const KeychainRouterCredentialStore(),
);

final trafficSampleRepositoryProvider = Provider<TrafficSampleRepository>(
  (ref) => DriftTrafficSampleRepository(ref.watch(appDatabaseProvider)),
);

final _driftTrafficDeviceResolverProvider =
    Provider<DriftTrafficDeviceResolver>(
      (ref) => DriftTrafficDeviceResolver(
        ref.watch(appDatabaseProvider),
        activeNetworkId: () async =>
            (await ref.read(currentNetworkLookupProvider)())?.networkId,
      ),
    );

final trafficDeviceResolverProvider = Provider<TrafficDeviceResolver>(
  (ref) => ref.watch(_driftTrafficDeviceResolverProvider),
);

final demoTrafficProviderProvider = Provider<DemoTrafficProvider>((ref) {
  return DemoTrafficProvider(
    loadDevices: ref.watch(_driftTrafficDeviceResolverProvider).knownIdentities,
    clock: ref.watch(trafficClockProvider),
  );
});

final usageCursorStoreProvider = Provider<UsageCursorStore>(
  (ref) => FileUsageCursorStore(),
);

final fortiGateConfigRepositoryProvider =
    Provider<FileFortiGateConfigRepository>(
      (ref) => FileFortiGateConfigRepository(),
    );

final fortiGateTransportProvider = Provider<FortiGateTransport>(
  (ref) => const IoFortiGateTransport(),
);

/// Non-secret FortiGate connection settings.
final fortiGateConfigProvider =
    AsyncNotifierProvider<FortiGateConfigController, FortiGateConfig>(
      FortiGateConfigController.new,
    );

class FortiGateConfigController extends AsyncNotifier<FortiGateConfig> {
  @override
  Future<FortiGateConfig> build() =>
      ref.watch(fortiGateConfigRepositoryProvider).load();

  Future<void> save(FortiGateConfig config) async {
    final current = await future;
    // A different device (host/port) must be trusted anew.
    final samePeer = current.host == config.host && current.port == config.port;
    final updated = samePeer
        ? config
        : config.copyWith(pinnedCertificateSha256: () => null);
    await ref.read(fortiGateConfigRepositoryProvider).save(updated);
    if (ref.mounted) state = AsyncData(updated);
  }

  /// The user compared [sha256] with the FortiGate GUI and trusts it.
  Future<void> trustCertificate(String sha256) async {
    final updated = (await future).copyWith(
      pinnedCertificateSha256: () => sha256,
    );
    await ref.read(fortiGateConfigRepositoryProvider).save(updated);
    if (ref.mounted) state = AsyncData(updated);
  }
}

final fortiGateTrafficProviderProvider = Provider<FortiGateTrafficProvider>((
  ref,
) {
  return FortiGateTrafficProvider(
    config: ref.watch(fortiGateConfigProvider).value ?? const FortiGateConfig(),
    credentials: ref.watch(routerCredentialStoreProvider),
    transport: ref.watch(fortiGateTransportProvider),
  );
});

/// Every selectable traffic provider. A real adapter is added only for a
/// system whose API is known — here FortiGate (identified on this network)
/// — never a generic or guessed endpoint.
final availableTrafficProvidersProvider = Provider<List<TrafficProvider>>(
  (ref) => [
    ref.watch(fortiGateTrafficProviderProvider),
    ref.watch(demoTrafficProviderProvider),
  ],
);

/// Bumped whenever samples are written or deleted, so views re-query.
final trafficDataRevisionProvider = NotifierProvider<TrafficDataRevision, int>(
  TrafficDataRevision.new,
);

class TrafficDataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final trafficSettingsProvider =
    AsyncNotifierProvider<TrafficSettingsController, TrafficSettings>(
      TrafficSettingsController.new,
    );

class TrafficSettingsController extends AsyncNotifier<TrafficSettings> {
  @override
  Future<TrafficSettings> build() =>
      ref.watch(trafficSettingsRepositoryProvider).load();

  /// Switches the active provider. Leaving a demo provider deletes its
  /// samples so simulated data can never be mistaken for real usage later;
  /// entering one backfills a week of demo history.
  Future<void> selectProvider(String providerId) async {
    final current = await future;
    if (current.providerId == providerId) return;

    final providers = ref.read(availableTrafficProvidersProvider);
    final samples = ref.read(trafficSampleRepositoryProvider);
    final previous = _find(providers, current.providerId);
    final next = _find(providers, providerId);

    final updated = current.copyWith(providerId: providerId);
    await ref.read(trafficSettingsRepositoryProvider).save(updated);
    if (previous != null && previous.descriptor.isDemo) {
      await samples.deleteBySource(previous.descriptor.id);
    }
    if (next is DemoTrafficProvider) {
      await _backfillDemo(next, samples, updated);
    }
    if (!ref.mounted) return;
    state = AsyncData(updated);
    ref.read(trafficDataRevisionProvider.notifier).bump();
  }

  Future<void> setDailyRetentionDays(int days) =>
      _update((settings) => settings.copyWith(dailyRetentionDays: days));

  Future<void> setUseBinaryUnits(bool value) =>
      _update((settings) => settings.copyWith(useBinaryUnits: value));

  Future<void> _update(TrafficSettings Function(TrafficSettings) change) async {
    final updated = change(await future);
    await ref.read(trafficSettingsRepositoryProvider).save(updated);
    if (ref.mounted) state = AsyncData(updated);
  }

  Future<void> _backfillDemo(
    DemoTrafficProvider provider,
    TrafficSampleRepository samples,
    TrafficSettings settings,
  ) async {
    final resolver = ref.read(_driftTrafficDeviceResolverProvider);
    final now = ref.read(trafficClockProvider)();
    await backfillDemoHistory(
      provider: provider,
      collector: TrafficCollector(
        provider: provider,
        resolver: resolver,
        repository: samples,
      ),
      devices: await resolver.knownIdentities(),
      now: now,
    );
    await samples.applyRetention(
      now: now,
      policy: TrafficRetentionPolicy.withDailyRetentionDays(
        settings.dailyRetentionDays,
      ),
    );
  }
}

TrafficProvider? _find(List<TrafficProvider> providers, String id) =>
    providers.firstWhereOrNull((provider) => provider.descriptor.id == id);

/// What [DeviceTrafficSection] shows for one device.
sealed class DeviceTrafficState {
  const DeviceTrafficState();
}

/// Keşif modu, or the configured provider no longer exists. The UI must say
/// traffic is unavailable — never show `0 MB`.
class DeviceTrafficUnavailable extends DeviceTrafficState {
  const DeviceTrafficUnavailable();
}

class DeviceTrafficAvailable extends DeviceTrafficState {
  const DeviceTrafficAvailable({
    required this.summary,
    required this.provider,
    required this.useBinaryUnits,
  });

  final DeviceTrafficSummary summary;
  final TrafficProviderDescriptor provider;
  final bool useBinaryUnits;
}

final deviceTrafficProvider = FutureProvider.autoDispose
    .family<DeviceTrafficState, int>((ref, deviceId) async {
      ref.watch(trafficDataRevisionProvider);
      final settings = await ref.watch(trafficSettingsProvider.future);
      final provider = _find(
        ref.watch(availableTrafficProvidersProvider),
        settings.providerId,
      );
      if (!settings.hasProvider || provider == null) {
        return const DeviceTrafficUnavailable();
      }

      final now = ref.watch(trafficClockProvider)();
      final samples = await ref
          .watch(trafficSampleRepositoryProvider)
          .samplesForDevice(
            deviceId,
            from: trafficSummaryRangeStart(now),
            to: startOfNextLocalDay(now),
          );
      return DeviceTrafficAvailable(
        summary: buildDeviceTrafficSummary(samples: samples, now: now),
        provider: provider.descriptor,
        useBinaryUnits: settings.useBinaryUnits,
      );
    });

/// Today's totals for every device, for the device list's traffic columns
/// and sort. Null in Keşif modu: the list must then say traffic is
/// unavailable rather than show `0 MB`.
class TodayTrafficTotals {
  const TodayTrafficTotals({
    required this.byDevice,
    required this.useBinaryUnits,
    required this.isDemo,
  });

  final Map<int, TrafficTotals> byDevice;
  final bool useBinaryUnits;
  final bool isDemo;
}

final todayTrafficTotalsProvider =
    FutureProvider.autoDispose<TodayTrafficTotals?>((ref) async {
      ref.watch(trafficDataRevisionProvider);
      final settings = await ref.watch(trafficSettingsProvider.future);
      final provider = _find(
        ref.watch(availableTrafficProvidersProvider),
        settings.providerId,
      );
      if (!settings.hasProvider || provider == null) return null;

      final now = ref.watch(trafficClockProvider)();
      final totals = await ref
          .watch(trafficSampleRepositoryProvider)
          .totalsByDevice(
            from: startOfLocalDay(now),
            to: startOfNextLocalDay(now),
          );
      return TodayTrafficTotals(
        byDevice: totals,
        useBinaryUnits: settings.useBinaryUnits,
        isDemo: provider.descriptor.isDemo,
      );
    });

class TrafficCollectionStatus {
  const TrafficCollectionStatus({
    this.provider,
    this.lastPollAt,
    this.lastReport,
    this.lastFailure,
  });

  static const idle = TrafficCollectionStatus();

  /// Null in Keşif modu (nothing is collected).
  final TrafficProviderDescriptor? provider;
  final DateTime? lastPollAt;
  final TrafficCollectionReport? lastReport;
  final AppFailure? lastFailure;

  bool get isRunning => provider != null;
}

/// "Router entegrasyon modu": polls the active provider periodically while
/// something listens to this provider. Watch it from the app shell to keep
/// collection running app-wide.
final trafficCollectionProvider =
    NotifierProvider<TrafficCollectionController, TrafficCollectionStatus>(
      TrafficCollectionController.new,
    );

class TrafficCollectionController extends Notifier<TrafficCollectionStatus> {
  static const _retentionInterval = Duration(hours: 1);

  DateTime? _lastRetentionAt;
  bool _polling = false;

  @override
  TrafficCollectionStatus build() {
    // Only restart on changes that affect polling itself: restarting drops
    // the in-memory counter baselines.
    final providerId = ref.watch(
      trafficSettingsProvider.select((s) => s.value?.providerId),
    );
    final pollInterval = ref.watch(
      trafficSettingsProvider.select((s) => s.value?.pollInterval),
    );
    final provider = providerId == null
        ? null
        : _find(ref.watch(availableTrafficProvidersProvider), providerId);
    if (provider == null || pollInterval == null) {
      return TrafficCollectionStatus.idle;
    }

    final resolver = ref.watch(trafficDeviceResolverProvider);
    final repository = ref.watch(trafficSampleRepositoryProvider);
    final TrafficPoller collector;
    var interval = pollInterval;
    switch (provider) {
      case CounterTrafficProvider():
        collector = TrafficCollector(
          provider: provider,
          resolver: resolver,
          repository: repository,
        );
      case UsageTrafficProvider():
        collector = TrafficUsageCollector(
          provider: provider,
          resolver: resolver,
          repository: repository,
          cursors: ref.watch(usageCursorStoreProvider),
          clock: ref.watch(trafficClockProvider),
        );
        // Log searches are heavier than counter reads; don't load the
        // firewall more often than this.
        if (interval < _minUsagePollInterval) interval = _minUsagePollInterval;
    }
    final timer = Timer.periodic(interval, (_) => _poll(collector));
    ref.onDispose(timer.cancel);
    // First poll establishes counter baselines / reads recent usage.
    Future.microtask(() => _poll(collector));
    return TrafficCollectionStatus(provider: provider.descriptor);
  }

  static const _minUsagePollInterval = Duration(minutes: 5);

  Future<void> _poll(TrafficPoller collector) async {
    if (_polling || !ref.mounted) return;
    _polling = true;
    final clock = ref.read(trafficClockProvider);
    try {
      final report = await collector.pollOnce();
      final now = clock();
      if (_lastRetentionAt == null ||
          now.difference(_lastRetentionAt!) >= _retentionInterval) {
        final settings = ref.read(trafficSettingsProvider).value;
        await ref
            .read(trafficSampleRepositoryProvider)
            .applyRetention(
              now: now,
              policy: TrafficRetentionPolicy.withDailyRetentionDays(
                settings?.dailyRetentionDays ?? 90,
              ),
            );
        _lastRetentionAt = now;
      }
      if (!ref.mounted) return;
      state = TrafficCollectionStatus(
        provider: state.provider,
        lastPollAt: now,
        lastReport: report,
      );
      if (report.samplesWritten > 0) {
        ref.read(trafficDataRevisionProvider.notifier).bump();
      }
    } catch (error, stackTrace) {
      final failure = asAppFailure(error, stackTrace);
      _logger.failure(failure);
      if (!ref.mounted) return;
      state = TrafficCollectionStatus(
        provider: state.provider,
        lastPollAt: clock(),
        lastReport: state.lastReport,
        lastFailure: failure,
      );
    } finally {
      _polling = false;
    }
  }
}
