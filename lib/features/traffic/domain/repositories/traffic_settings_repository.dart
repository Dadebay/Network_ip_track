import '../entities/traffic_settings.dart';

abstract interface class TrafficSettingsRepository {
  Future<TrafficSettings> load();
  Future<void> save(TrafficSettings settings);
}
