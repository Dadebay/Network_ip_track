import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/logging/app_logger.dart';

/// Stores the appearance choice as JSON in the app support directory.
class ThemeModeStore {
  const ThemeModeStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  Future<File> _file() async =>
      File(p.join((await _directory()).path, 'appearance.json'));

  Future<ThemeMode> load() async {
    final file = await _file();
    if (!await file.exists()) return ThemeMode.system;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) return ThemeMode.system;
    return ThemeMode.values.asNameMap()[decoded['themeMode']] ??
        ThemeMode.system;
  }

  Future<void> save(ThemeMode mode) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode({'themeMode': mode.name}));
  }
}

final themeModeStoreProvider = Provider<ThemeModeStore>(
  (ref) => const ThemeModeStore(),
);

/// Sistem / Açık / Koyu. Starts from the system setting and switches to the
/// stored choice once it loads; every change is saved.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _logger = AppLogger('appearance');
  var _changedBeforeLoad = false;

  @override
  ThemeMode build() {
    ref.watch(themeModeStoreProvider).load().then(
      (stored) {
        if (ref.mounted && !_changedBeforeLoad) state = stored;
      },
      onError: (Object error) =>
          _logger.warning('Görünüm tercihi yüklenemedi: $error'),
    );
    return ThemeMode.system;
  }

  void set(ThemeMode mode) {
    _changedBeforeLoad = true;
    state = mode;
    ref
        .read(themeModeStoreProvider)
        .save(mode)
        .catchError(
          (Object error) =>
              _logger.warning('Görünüm tercihi kaydedilemedi: $error'),
        );
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
