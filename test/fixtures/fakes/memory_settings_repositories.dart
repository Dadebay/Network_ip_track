import 'package:network_monitor/features/discovery/domain/entities/scan_settings.dart';
import 'package:network_monitor/features/discovery/domain/repositories/scan_settings_repository.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_settings.dart';
import 'package:network_monitor/features/traffic/domain/repositories/traffic_settings_repository.dart';

/// Keeps traffic settings in memory instead of the app-support JSON file.
class MemoryTrafficSettingsRepository implements TrafficSettingsRepository {
  TrafficSettings settings = const TrafficSettings();

  @override
  Future<TrafficSettings> load() async => settings;

  @override
  Future<void> save(TrafficSettings settings) async => this.settings = settings;
}

/// Keeps scan settings in memory instead of the app-support JSON file.
class MemoryScanSettingsRepository implements ScanSettingsRepository {
  ScanSettings settings = const ScanSettings();

  @override
  Future<ScanSettings> load() async => settings;

  @override
  Future<void> save(ScanSettings settings) async => this.settings = settings;
}
