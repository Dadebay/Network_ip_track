import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/fortigate_config.dart';

/// [FortiGateConfig] as JSON in the app support directory. Holds no
/// secrets — the API key is in the Keychain. Writes are serialized and go
/// through a unique temp file + rename.
class FileFortiGateConfigRepository {
  FileFortiGateConfigRepository({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;
  Future<void> _lastSave = Future.value();
  var _tempCounter = 0;

  Future<File> _file() async =>
      File(p.join((await _directory()).path, 'fortigate.json'));

  Future<FortiGateConfig> load() async {
    final file = await _file();
    if (!await file.exists()) return const FortiGateConfig();
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, Object?>) {
        return FortiGateConfig.fromJson(decoded);
      }
    } on Object {
      // Unreadable: fall back to an empty configuration.
    }
    return const FortiGateConfig();
  }

  Future<void> save(FortiGateConfig config) {
    final encoded = jsonEncode(config.toJson());
    final next = _lastSave.catchError((Object _) {}).then((_) async {
      final file = await _file();
      await file.parent.create(recursive: true);
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
