import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/classification/infrastructure/ieee_oui_database.dart';

void main() {
  final vendors = parseIeeeOuiCsv(
    File('test/fixtures/oui/oui_sample.csv').readAsStringSync(),
  );

  test('parses MA-L rows, including quoted names with commas and quotes', () {
    expect(vendors['A483E7'], 'Apple, Inc.');
    expect(vendors['B827EB'], 'Raspberry Pi Foundation');
    expect(vendors['3C5AB4'], 'Google, Inc.');
    expect(vendors['001A2B'], 'Name with "quotes", Ltd.');
    // MA-M (28-bit) rows are not 24-bit OUIs.
    expect(vendors.values, isNot(contains('Too Specific Ltd')));
  });

  test(
    'looks up normalized MACs; locally administered MACs have no vendor',
    () {
      final database = IeeeOuiDatabase(vendors);
      expect(database.isAvailable, isTrue);
      expect(database.vendorFor('a4:83:e7:01:02:03'), 'Apple, Inc.');
      expect(database.vendorFor('00:00:00:01:02:03'), isNull);
      // ACDE48 has the locally-administered bit set? No — 0xAC = 1010_1100,
      // bit 1 is 0; but a randomized 0x5A… address must never resolve.
      expect(database.vendorFor('5a:83:e7:01:02:03'), isNull);
    },
  );

  test('without the registry every lookup is unknown', () {
    final database = IeeeOuiDatabase.unavailable();
    expect(database.isAvailable, isFalse);
    expect(database.vendorFor('a4:83:e7:01:02:03'), isNull);
  });

  test('the bundled IEEE registry parses completely', () {
    final bundled = parseIeeeOuiCsv(
      File('assets/oui/oui.csv').readAsStringSync(),
    );
    final maL = File(
      'assets/oui/oui.csv',
    ).readAsLinesSync().where((line) => line.startsWith('MA-L,')).length;
    // Every MA-L row yields an entry (a few assignments appear twice).
    expect(bundled.length, greaterThan(maL * 0.99));
    final database = IeeeOuiDatabase(bundled);
    expect(database.vendorFor('a4:83:e7:01:02:03'), 'Apple, Inc.');
    expect(database.vendorFor('b8:27:eb:01:02:03'), 'Raspberry Pi Foundation');
    expect(database.vendorFor('00:0c:29:01:02:03'), 'VMware, Inc.');
  });
}
