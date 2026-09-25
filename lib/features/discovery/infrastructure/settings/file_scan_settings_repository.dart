import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/scan_settings.dart';
import '../../domain/repositories/scan_settings_repository.dart';

/// Stores [ScanSettings] as JSON in the app support directory.
class FileScanSettingsRepository implements ScanSettingsRepository {
  FileScanSettingsRepository({
    Future<Directory> Function()? directory,
    AppLogger logger = const AppLogger('scan.settings'),
  }) : _directory = directory ?? getApplicationSupportDirectory,
       _logger = logger;

  final Future<Directory> Function() _directory;
  final AppLogger _logger;

  Future<File> _file() async =>
      File(p.join((await _directory()).path, 'scan_settings.json'));

  @override
  Future<ScanSettings> load() async {
    final file = await _file();
    if (!await file.exists()) return const ScanSettings();
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, dynamic>) {
        return ScanSettings.fromJson(decoded).sanitized();
      }
    } on Object catch (error) {
      // Malformed JSON or unexpected types (e.g. an unknown method name).
      _logger.warning('Okunamayan tarama ayarları yok sayıldı: $error');
    }
    return const ScanSettings();
  }

  /// Saves run one at a time, in call order, so the last call's settings
  /// are always what ends up on disk.
  Future<void> _lastSave = Future.value();
  var _tempCounter = 0;

  @override
  Future<void> save(ScanSettings settings) {
    final encoded = jsonEncode(settings.sanitized().toJson());
    final next = _lastSave.catchError((Object _) {}).then((_) async {
      final file = await _file();
      await file.parent.create(recursive: true);
      // Write-then-rename so a crash never leaves a truncated file; a unique
      // temp name so no two writes ever share one.
      final temp = File(
        '${file.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.'
        '${_tempCounter++}.tmp',
      );
      try {
        await temp.writeAsString(encoded, flush: true);
        await temp.rename(file.path);
      } finally {
        if (await temp.exists()) await temp.delete();
      }
    });
    _lastSave = next;
    return next;
  }
}
