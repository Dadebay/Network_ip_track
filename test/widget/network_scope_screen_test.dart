import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/fakes/test_app.dart';

void main() {
  testWidgets('shows the detected active network and accessible subnets', (
    tester,
  ) async {
    final database = inMemoryDatabase();
    addTearDown(database.close);
    await tester.pumpWidget(buildTestApp(database: database));

    // Initial frame is the loading state.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ağlar'));
    await tester.pumpAndSettle();

    expect(find.text('172.16.14.26'), findsOneWidget);
    // Appears once on the active-interface card and once as the directly
    // connected accessible subnet.
    expect(find.text('172.16.14.0/24'), findsNWidgets(2));
    expect(find.text('172.16.20.0/24'), findsOneWidget);
    await unmountApp(tester);
  });
}
