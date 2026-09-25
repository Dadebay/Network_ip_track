import 'package:flutter/material.dart';

import 'root_shell.dart';
import 'theme/app_theme.dart';

class NetworkMonitorApp extends StatelessWidget {
  const NetworkMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ağ İzleyici',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const RootShell(),
    );
  }
}
