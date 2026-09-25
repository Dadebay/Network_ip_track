import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/classification/domain/entities/device_classification.dart';
import 'package:network_monitor/features/devices/infrastructure/drift_device_repository.dart';
import 'package:network_monitor/features/discovery/domain/entities/discovered_device.dart';

import '../fixtures/fakes/test_app.dart';

void main() {
  testWidgets(
    'the user\'s name/type/"known" override the inference in tree and detail',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final database = inMemoryDatabase();
      addTearDown(database.close);

      // A device from an earlier scan on the fake active network.
      await tester.runAsync(() async {
        final networkId = await database.upsertActiveNetwork(
          interfaceName: 'en0',
          displayName: 'Wi-Fi',
          cidr: '172.16.14.0/24',
          gatewayIp: '172.16.14.254',
          observedAt: DateTime(2026, 9, 24),
        );
        await DriftDeviceRepository(database).upsertDiscoveredDevice(
          networkId: networkId,
          discovered: DiscoveredDevice(
            ipAddress: Ipv4Address.parse('172.16.14.77'),
            respondedAt: DateTime(2026, 9, 24),
          ),
          classification: DeviceClassification.unknown,
        );
      });

      await tester.pumpWidget(buildTestApp(database: database));
      await tester.pumpAndSettle();
      // Groups start collapsed; the device row only appears once the
      // "Bilinmeyen" group is expanded.
      expect(find.text('Bilinmeyen'), findsOneWidget);
      await tester.tap(find.text('Bilinmeyen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('172.16.14.77'));
      await tester.pumpAndSettle();
      expect(find.text('Kullanıcı bilgileri'), findsOneWidget);
      await tester.tap(find.text('Düzenle'));
      await tester.pumpAndSettle();

      final dialog = find.byType(AlertDialog);
      await tester.enterText(
        find.descendant(of: dialog, matching: find.byType(TextField)).first,
        'Salon yazıcısı',
      );
      await tester.tap(find.text('Otomatik (Bilinmiyor)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Yazıcı').last);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: dialog, matching: find.text('Bu cihazı tanıyorum')),
      );
      await tester.tap(find.text('Kaydet'));
      await tester.pumpAndSettle();

      // Tree regroups by the user's type; the name and tag follow.
      expect(find.text('Yazıcılar'), findsOneWidget);
      expect(find.text('Bilinmeyen'), findsNothing);
      expect(find.text('Salon yazıcısı'), findsWidgets);
      expect(find.text('Tanıdık'), findsWidgets);
      // Detail: the user's type, while the inference is still shown.
      expect(find.text('Yazıcı'), findsWidgets);
      expect(find.textContaining('bu tahminin önüne geçer'), findsOneWidget);

      await unmountApp(tester);
    },
  );
}
