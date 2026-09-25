import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// Sidebar destinations. Mirrors the spec's left panel, with the device
/// tree/list ("Cihazlar") as the main view.
enum ShellDestination {
  devices('Cihazlar', HugeIcons.strokeRoundedHierarchy),
  networks('Ağlar', HugeIcons.strokeRoundedRouter01),
  scanScopes('Tarama kapsamları', HugeIcons.strokeRoundedRadar01),
  recentScans('Son taramalar', HugeIcons.strokeRoundedTime01),
  settings('Ayarlar', HugeIcons.strokeRoundedSettings02);

  const ShellDestination(this.label, this.icon);

  final String label;
  final List<List<dynamic>> icon;
}

class ShellNavigationController extends Notifier<ShellDestination> {
  @override
  ShellDestination build() => ShellDestination.devices;

  void go(ShellDestination destination) => state = destination;
}

/// Lets any screen switch the sidebar section (e.g. the empty device list's
/// "start a scan" button).
final shellDestinationProvider =
    NotifierProvider<ShellNavigationController, ShellDestination>(
      ShellNavigationController.new,
    );
