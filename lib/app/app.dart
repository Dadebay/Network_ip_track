import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'root_shell.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_controller.dart';

class NetworkMonitorApp extends ConsumerWidget {
  const NetworkMonitorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Ağ İzleyici',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      home: const RootShell(),
    );
  }
}
