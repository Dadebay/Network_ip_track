import '../entities/scan_settings.dart';

abstract interface class ScanSettingsRepository {
  /// Defaults when nothing is stored or the stored file is unreadable.
  Future<ScanSettings> load();
  Future<void> save(ScanSettings settings);
}
