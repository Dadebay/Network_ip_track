import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/logging/app_logger.dart';
import '../domain/entities/traffic_settings.dart';
import '../domain/repositories/traffic_settings_repository.dart';

/// Stores [TrafficSettings] as JSON in the app support directory. Holds no
/// secrets — credentials go to the Keychain.
class FileTrafficSettingsRepository implements TrafficSettingsRepository {
  FileTrafficSettingsRepository({
    Future<Directory> Function()? directory,
    AppLogger logger = const AppLogger('traffic.settings'),
  }) : _directory = directory ?? getApplicationSupportDirectory,
       _logger = logger;

  final Future<Directory> Function() _directory;
  final AppLogger _logger;

  Future<File> _file() async =>
      File(p.join((await _directory()).path, 'traffic_settings.json'));

  @override
  Future<TrafficSettings> load() async {
    final file = await _file();
    if (!await file.exists()) return const TrafficSettings();
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, Object?>) {
        return TrafficSettings.fromJson(decoded);
      }
    } on FormatException catch (error) {
      _logger.warning('Ignoring unreadable traffic settings: $error');
    }
    return const TrafficSettings();
  }

  /// Saves run one at a time, in call order, so the last call's settings
  /// are always what ends up on disk.
  Future<void> _lastSave = Future.value();
  var _tempCounter = 0;

  @override
  Future<void> save(TrafficSettings settings) {
    final encoded = jsonEncode(settings.toJson());
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
