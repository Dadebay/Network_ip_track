import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_scope_type.dart';
import 'package:network_monitor/features/discovery/presentation/providers/scan_providers.dart';
import 'package:network_monitor/features/network_scope/presentation/providers/network_scope_providers.dart';
import 'package:network_monitor/features/devices/presentation/widgets/device_detail_panel.dart';
import 'package:network_monitor/features/traffic/presentation/widgets/device_traffic_section.dart';

import '../fixtures/fakes/fake_discovery_providers.dart';
import '../fixtures/fakes/fake_route_provider.dart';
import '../fixtures/fakes/test_app.dart';

Ipv4Address ip(String s) => Ipv4Address.parse(s);

Future<void> useDesktopWindow(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1600, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Runs a scan of the default scope through the UI and returns to the
/// device list.
Future<void> runScan(WidgetTester tester) async {
  await tester.tap(find.text('Tarama kapsamları'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Taramayı başlat'));
  await tester.pumpAndSettle();
  // Two /24s (508 hosts) exceed the unconfirmed limit of one /24.
  expect(find.text('Büyük tarama başlatılsın mı?'), findsOneWidget);
  await tester.tap(find.text('Yetkiliyim, başlat'));
  await tester.pumpAndSettle();
  // Scans are async I/O against the database; give it real time to finish.
  // Wait for the session to leave the running state — the pause/cancel
  // actions disappear — rather than for any "Tamamlandı" text: a single
  // finished chunk's row renders that same word while other chunks are
  // still sweeping in parallel (chunkConcurrency > 1).
  for (var i = 0; i < 50 && find.text('Duraklat').evaluate().isNotEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
  }
  expect(find.text('Duraklat'), findsNothing);
  expect(find.text('Tamamlandı'), findsWidgets);
}

void main() {
  testWidgets('empty device list points to the scan screen', (tester) async {
    await useDesktopWindow(tester);
    final database = inMemoryDatabase();
    addTearDown(database.close);
    await tester.pumpWidget(buildTestApp(database: database));
    await tester.pumpAndSettle();

    expect(find.textContaining('henüz cihaz bulunmadı'), findsOneWidget);
    await tester.tap(find.text('Taramaya git'));
    await tester.pumpAndSettle();
    expect(find.text('Tarama önizlemesi'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('scan preview shows CIDRs, host count, methods and concurrency', (
    tester,
  ) async {
    await useDesktopWindow(tester);
    final database = inMemoryDatabase();
    addTearDown(database.close);
    await tester.pumpWidget(buildTestApp(database: database));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tarama kapsamları'));
    await tester.pumpAndSettle();

    // Default scope: every accessible private 172 subnet.
    // Listed under the scope option and in the preview.
    expect(find.text('172.16.14.0/24, 172.16.20.0/24'), findsNWidgets(2));
    expect(find.textContaining('508 (512 adres'), findsOneWidget);
    expect(find.textContaining('8 eşzamanlı · ping 800 ms'), findsOneWidget);
    expect(find.textContaining('ICMP ping'), findsOneWidget);

    // A CIDR outside 172.16.0.0/12 is rejected before any scan.
    await tester.tap(find.text('Özel CIDR ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '172.32.0.0/24');
    await tester.pump();
    expect(
      find.text('Yalnızca 172.16.0.0/12 içindeki ağlar taranabilir.'),
      findsWidgets,
    );
    final start = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Taramayı başlat'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(start.onPressed, isNull);

    // The full block requires explicit confirmation.
    await tester.tap(find.text('Tüm özel 172 bloğunu tara'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Taramayı başlat'));
    await tester.pumpAndSettle();
    expect(find.text('Büyük tarama başlatılsın mı?'), findsOneWidget);
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(find.text('Büyük tarama başlatılsın mı?'), findsNothing);
    await unmountApp(tester);
  });

  testWidgets(
    'scan results appear in the tree and list; detail never shows 0 MB',
    (tester) async {
      await useDesktopWindow(tester);
      final database = inMemoryDatabase();
      addTearDown(database.close);
      await tester.pumpWidget(
        buildTestApp(
          database: database,
          ping: FakePingProvider(
            alive: {ip('172.16.14.12'), ip('172.16.14.254'), ip('172.16.20.7')},
          ),
          arp: FakeArpTableProvider(
            lookupResults: {ip('172.16.14.12'): 'a4:83:e7:01:02:03'},
          ),
          reverseDns: FakeReverseDnsProvider({
            ip('172.16.14.12'): 'iphone.lan',
          }),
          ports: FakePortProbeProvider({
            ip('172.16.14.254'): [80, 443],
          }),
        ),
      );
      await tester.pumpAndSettle();
      await runScan(tester);
      // Per-subnet progress: 2 devices on the local /24, 1 on the routed one.
      expect(find.text('254/254 · 2 cihaz'), findsOneWidget);
      expect(find.text('254/254 · 1 cihaz'), findsOneWidget);

      await tester.tap(find.text('Cihazlar'));
      await tester.pumpAndSettle();

      // Tree: block > subnet > gateway > group > device, as a vertical
      // outline — no pan/zoom canvas.
      expect(find.text('172.16.0.0/12'), findsOneWidget);
      expect(find.text('Gateway'), findsOneWidget);
      expect(find.text('172.16.14.254'), findsWidgets);
      expect(find.text('Bilinmeyen'), findsWidgets);
      expect(find.textContaining('Router üzerinden'), findsOneWidget);
      expect(find.byType(InteractiveViewer), findsNothing);
      expect(find.byTooltip('Ekrana sığdır'), findsNothing);

      // Groups start collapsed: the phone isn't visible until its group
      // (classified from the "iphone.lan" hostname) is opened.
      expect(find.text('iphone.lan'), findsNothing);
      await tester.tap(find.text('Telefonlar'));
      await tester.pumpAndSettle();
      expect(find.text('iphone.lan'), findsOneWidget);

      // Collapsing the group hides its device again; expanding brings it back.
      await tester.tap(find.text('Telefonlar'));
      await tester.pumpAndSettle();
      expect(find.text('iphone.lan'), findsNothing);
      await tester.tap(find.text('Telefonlar'));
      await tester.pumpAndSettle();
      expect(find.text('iphone.lan'), findsOneWidget);

      // List view with search.
      await tester.tap(find.text('Liste'));
      await tester.pumpAndSettle();
      expect(find.text('Cihaz adı'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'a4:83');
      await tester.pumpAndSettle();
      expect(find.text('1 / 3 cihaz'), findsOneWidget);

      await tester.tap(find.text('iphone.lan'));
      await tester.pumpAndSettle();
      expect(find.text('a4:83:e7:01:02:03'), findsWidgets);
      // The detail pane is a lazy list; scroll to the later sections.
      final detailList = find.descendant(
        of: find.byType(DeviceDetailPanel),
        matching: find.byType(Scrollable),
      );
      await tester.scrollUntilVisible(
        find.text('ICMP yanıtı'),
        200,
        scrollable: detailList.first,
      );
      expect(find.text('ICMP yanıtı'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining(DeviceTrafficSection.unavailableMessage),
        200,
        scrollable: detailList.first,
      );
      expect(
        find.textContaining(DeviceTrafficSection.unavailableMessage),
        findsOneWidget,
      );
      expect(find.textContaining('0 MB'), findsNothing);
      await unmountApp(tester);
    },
  );

  testWidgets('renders in dark theme', (tester) async {
    await useDesktopWindow(tester);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final database = inMemoryDatabase();
    addTearDown(database.close);
    await tester.pumpWidget(buildTestApp(database: database));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(find.byType(NetworkMonitorApp), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets(
    'regression: a 172.16.0.0/12 route makes the recommended scope ~1M '
    'addresses, which never starts without confirmation',
    (tester) async {
      await useDesktopWindow(tester);
      final database = inMemoryDatabase();
      addTearDown(database.close);
      final ping = FakePingProvider();
      await tester.pumpWidget(
        buildTestApp(
          database: database,
          ping: ping,
          routes: const FakeWholeBlockRouteProvider(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tarama kapsamları'));
      await tester.pumpAndSettle();

      // The recommended (default) option, not the "full block" one.
      expect(find.textContaining('4.096 parça'), findsWidgets);
      expect(find.textContaining('1.040.384'), findsWidgets);

      await tester.tap(find.text('Taramayı başlat'));
      await tester.pumpAndSettle();
      expect(find.text('Büyük tarama başlatılsın mı?'), findsOneWidget);
      expect(
        find.textContaining(
          'Erişilebilir tüm özel 172 ağlarını tara: 1.040.384',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();

      // Declining starts nothing.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      expect(container.read(scanControllerProvider).isRunning, isFalse);
      expect(await database.select(database.scanSessions).get(), isEmpty);
      expect(ping.pinged, isEmpty);

      // The controller refuses an unconfirmed large plan even if a caller
      // bypasses the dialog.
      final network = await container.read(activeNetworkProvider.future);
      final plan = container.read(buildScanPlanUseCaseProvider)(
        scopeType: ScanScopeType.allAccessiblePrivate172,
        networkScope: network.snapshot,
      );
      expect(plan.requiresConfirmation, isTrue);
      await container
          .read(scanControllerProvider.notifier)
          .start(plan, network);
      await tester.pumpAndSettle();
      expect(container.read(scanControllerProvider).failure, isNotNull);
      expect(await database.select(database.scanSessions).get(), isEmpty);
      expect(ping.pinged, isEmpty);

      await unmountApp(tester);
    },
  );
}
