import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/devices/application/device_tree.dart';
import 'package:network_monitor/features/devices/domain/entities/device_type.dart';
import 'package:network_monitor/features/devices/presentation/widgets/device_map_view.dart';

import '../fixtures/fakes/device_factory.dart';

void main() {
  testWidgets('renders the map with a legend and settles', (tester) async {
    final devices = [
      makeDevice(
        1,
        '172.16.14.254',
        isGateway: true,
        type: DeviceType.routerGateway,
      ),
      for (var i = 2; i < 30; i++)
        makeDevice(i, '172.16.14.$i', type: DeviceType.values[i % 12]),
    ];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DeviceMapView(
              roots: buildDeviceTree(devices: devices, subnets: const []),
              onDeviceSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('Haritayı ortala'), findsOneWidget);
    expect(find.textContaining('Kameralar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
