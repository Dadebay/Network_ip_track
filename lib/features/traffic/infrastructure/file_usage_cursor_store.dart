import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/entities/traffic_usage_batch.dart';
import '../domain/repositories/usage_cursor_store.dart';

/// Usage cursors as JSON in the app support directory. Writes are
/// serialized and go through a unique temp file + rename.
class FileUsageCursorStore implements UsageCursorStore {
  FileUsageCursorStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;
  Future<void> _lastWrite = Future.value();
  var _tempCounter = 0;

  Future<File> _file() async =>
      File(p.join((await _directory()).path, 'traffic_usage_cursors.json'));

  Future<Map<String, Object?>> _readAll() async {
    final file = await _file();
    if (!await file.exists()) return {};
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is Map<String, Object?>) return decoded;
    } on FormatException {
      // Unreadable: start over (the collector's initial lookback applies).
    }
    return {};
  }

  @override
  Future<UsageCursor?> load(String providerId) async {
    await _lastWrite.catchError((Object _) {});
    return UsageCursor.tryFromJson((await _readAll())[providerId]);
  }

  @override
  Future<void> save(String providerId, UsageCursor cursor) =>
      _update((all) => all[providerId] = cursor.toJson());

  @override
  Future<void> clear(String providerId) =>
      _update((all) => all.remove(providerId));

  Future<void> _update(void Function(Map<String, Object?> all) change) {
    final next = _lastWrite.catchError((Object _) {}).then((_) async {
      final all = await _readAll();
      change(all);
      final file = await _file();
      await file.parent.create(recursive: true);
      final temp = File(
        '${file.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.'
        '${_tempCounter++}.tmp',
      );
      try {
        await temp.writeAsString(jsonEncode(all), flush: true);
        await temp.rename(file.path);
      } finally {
        if (await temp.exists()) await temp.delete();
      }
    });
    _lastWrite = next;
    return next;
  }
}
