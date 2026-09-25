import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/devices/presentation/screens/devices_screen.dart';
import '../features/discovery/presentation/screens/recent_scans_screen.dart';
import '../features/discovery/presentation/screens/scan_screen.dart';
import '../features/network_scope/presentation/screens/network_scope_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/traffic/presentation/providers/traffic_providers.dart';
import 'shell_navigation.dart';
import 'widgets/app_sidebar.dart';

/// Sidebar + content shell. The sidebar sections mirror the spec's
/// left-panel layout (Ağlar / Tarama kapsamları / Son taramalar / Ayarlar),
/// with the device tree/list as the main view.
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(shellDestinationProvider);
    // Keeps router-integration polling running app-wide, not only while the
    // traffic settings screen is open.
    ref.watch(trafficCollectionProvider);
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selected: destination,
            onSelected: ref.read(shellDestinationProvider.notifier).go,
          ),
          Expanded(child: _buildContent(destination)),
        ],
      ),
    );
  }

  Widget _buildContent(ShellDestination destination) {
    return switch (destination) {
      ShellDestination.devices => const DevicesScreen(),
      ShellDestination.networks => const NetworkScopeScreen(),
      ShellDestination.scanScopes => const ScanScreen(),
      ShellDestination.recentScans => const RecentScansScreen(),
      ShellDestination.settings => const SettingsScreen(),
    };
  }
}
