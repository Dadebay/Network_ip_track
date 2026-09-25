import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/devices/application/device_tree.dart';
import 'package:network_monitor/features/devices/domain/entities/device.dart';
import 'package:network_monitor/features/devices/domain/entities/device_type.dart';
import 'package:network_monitor/features/devices/presentation/widgets/device_tree_view.dart';

import '../fixtures/fakes/device_factory.dart';

Widget _harness({
  required List<DeviceTreeNode> roots,
  ValueChanged<Device>? onSelected,
  bool forceExpandAll = false,
  double width = 900,
  double height = 500,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: DeviceTreeView(
            roots: roots,
            forceExpandAll: forceExpandAll,
            onDeviceSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'with 585 devices in one open group, only a small fraction of device rows are built',
    (tester) async {
      final devices = [
        for (var i = 1; i <= 585; i++)
          makeDevice(
            i,
            '172.16.14.${(i % 250) + 1}',
            hostname: 'dev$i',
            type: DeviceType.unknown,
          ),
      ];
      final roots = buildDeviceTree(devices: devices, subnets: const []);

      // Force the single "Bilinmeyen" group open — the interesting case per
      // the design doc is a huge *expanded* group, not a collapsed one.
      await tester.pumpWidget(_harness(roots: roots, forceExpandAll: true));
      await tester.pumpAndSettle();

      final builtDeviceNames = tester
          .widgetList<Text>(find.textContaining('dev'))
          .length;
      expect(builtDeviceNames, greaterThan(0));
      // A 500px-tall viewport at ~44px/row plus cache extent builds a few
      // dozen rows at most — nowhere near all 585.
      expect(builtDeviceNames, lessThan(100));
    },
  );

  testWidgets(
    'forceExpandAll opens every group so a filtered device is never hidden',
    (tester) async {
      final device = makeDevice(
        1,
        '172.16.14.12',
        hostname: 'iphone-x',
        type: DeviceType.phone,
      );
      final roots = buildDeviceTree(devices: [device], subnets: const []);

      await tester.pumpWidget(_harness(roots: roots));
      await tester.pumpAndSettle();
      expect(
        find.text('iphone-x'),
        findsNothing,
        reason: 'groups start collapsed',
      );

      await tester.pumpWidget(_harness(roots: roots, forceExpandAll: true));
      await tester.pumpAndSettle();
      expect(find.text('iphone-x'), findsOneWidget);
    },
  );

  testWidgets('tapping a device row opens its detail (via onDeviceSelected)', (
    tester,
  ) async {
    final device = makeDevice(
      1,
      '172.16.14.12',
      hostname: 'iphone-x',
      type: DeviceType.phone,
    );
    final roots = buildDeviceTree(devices: [device], subnets: const []);
    Device? selected;

    await tester.pumpWidget(
      _harness(
        roots: roots,
        forceExpandAll: true,
        onSelected: (d) => selected = d,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('iphone-x'));
    await tester.pumpAndSettle();
    expect(selected?.id, 1);
  });

  testWidgets('a narrow viewport does not overflow', (tester) async {
    final device = makeDevice(
      1,
      '172.16.14.12',
      hostname: 'a-very-long-device-hostname-example',
      vendor: 'Some Long Vendor Name Inc.',
      type: DeviceType.phone,
    );
    final roots = buildDeviceTree(devices: [device], subnets: const []);

    await tester.pumpWidget(
      _harness(roots: roots, forceExpandAll: true, width: 260),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
