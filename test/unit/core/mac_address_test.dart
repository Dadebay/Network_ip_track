import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/mac_address.dart';

void main() {
  group('normalizeMacAddress', () {
    test('pads single-digit octets and lowercases', () {
      expect(normalizeMacAddress('0:1a:2B:3c:4d:5e'), '00:1a:2b:3c:4d:5e');
    });

    test('accepts hyphen-separated input', () {
      expect(normalizeMacAddress('AC-DE-48-00-11-22'), 'ac:de:48:00:11:22');
    });

    test('rejects a value with the wrong number of octets', () {
      expect(normalizeMacAddress('ac:de:48:00:11'), isNull);
    });

    test('rejects a non-hex octet', () {
      expect(normalizeMacAddress('ac:de:48:00:11:zz'), isNull);
    });
  });

  group('ouiOf', () {
    test('returns the first three octets', () {
      expect(ouiOf('ac:de:48:00:11:22'), 'ac:de:48');
    });
  });
}
