import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitor/app/app.dart';
import 'package:network_monitor/app/theme/theme_mode_controller.dart';
import 'package:network_monitor/features/network_scope/infrastructure/macos/macos_wifi_scanner.dart';
import 'package:network_monitor/core/database/app_database.dart';
import 'package:network_monitor/features/discovery/presentation/providers/scan_providers.dart';
import 'package:network_monitor/features/network_scope/domain/repositories/route_provider.dart';
import 'package:network_monitor/features/network_scope/presentation/providers/network_scope_providers.dart';
import 'package:network_monitor/features/traffic/presentation/providers/traffic_providers.dart';

import 'fake_discovery_providers.dart';
import 'fake_network_interface_provider.dart';
import 'fake_route_provider.dart';
import 'memory_settings_repositories.dart';

/// The whole app with every platform adapter replaced by a fake and an
/// in-memory database, so widget tests never touch the real network.
Widget buildTestApp({
  required AppDatabase database,
  FakePingProvider? ping,
  FakeArpTableProvider? arp,
  FakeReverseDnsProvider? reverseDns,
  FakeMdnsProvider? mdns,
  FakePortProbeProvider? ports,
  RouteProvider routes = const FakeRouteProvider(),
  FakeOuiLookup oui = const FakeOuiLookup(),
  MacosWifiScanner? wifi,
}) {
  return ProviderScope(
    overrides: [
      networkInterfaceAdapterProvider.overrideWithValue(
        const FakeNetworkInterfaceProvider(),
      ),
      routeAdapterProvider.overrideWithValue(routes),
      appDatabaseProvider.overrideWithValue(database),
      if (wifi != null) wifiScannerProvider.overrideWithValue(wifi),
      pingAdapterProvider.overrideWithValue(ping ?? FakePingProvider()),
      arpTableAdapterProvider.overrideWithValue(arp ?? FakeArpTableProvider()),
      reverseDnsAdapterProvider.overrideWithValue(
        reverseDns ?? FakeReverseDnsProvider(),
      ),
      mdnsAdapterProvider.overrideWithValue(mdns ?? FakeMdnsProvider()),
      ssdpAdapterProvider.overrideWithValue(FakeSsdpProvider()),
      themeModeStoreProvider.overrideWithValue(
        ThemeModeStore(
          directory: () async => Directory.systemTemp.createTemp('appearance'),
        ),
      ),
      mdnsNameAdapterProvider.overrideWithValue(FakeMdnsNameProvider()),
      wsDiscoveryAdapterProvider.overrideWithValue(FakeWsDiscoveryProvider()),
      upnpDescriptionAdapterProvider.overrideWithValue(
        FakeUpnpDescriptionProvider(),
      ),
      portProbeAdapterProvider.overrideWithValue(
        ports ?? FakePortProbeProvider(),
      ),
      netbiosAdapterProvider.overrideWithValue(FakeNetbiosProvider()),
      scanSettingsRepositoryProvider.overrideWithValue(
        MemoryScanSettingsRepository(),
      ),
      ouiLookupProvider.overrideWith((ref) async => oui),
      trafficSettingsRepositoryProvider.overrideWithValue(
        MemoryTrafficSettingsRepository(),
      ),
    ],
    child: const NetworkMonitorApp(),
  );
}

AppDatabase inMemoryDatabase() => AppDatabase(NativeDatabase.memory());

/// Unmounts the app so Drift stream subscriptions close, then flushes the
/// zero-delay timers that closing schedules — otherwise the test binding
/// reports a pending timer. Call as the last step of each widget test.
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 10));
}
