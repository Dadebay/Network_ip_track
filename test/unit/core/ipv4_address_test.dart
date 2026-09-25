import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';

void main() {
  group('Ipv4Address.parse', () {
    test('parses a valid address', () {
      final address = Ipv4Address.parse('172.16.14.26');
      expect(address.octets, [172, 16, 14, 26]);
      expect(address.toString(), '172.16.14.26');
    });

    test('rejects an octet above 255', () {
      expect(Ipv4Address.tryParse('172.16.14.256'), isNull);
    });

    test('rejects the wrong number of octets', () {
      expect(Ipv4Address.tryParse('172.16.14'), isNull);
      expect(Ipv4Address.tryParse('172.16.14.1.5'), isNull);
    });

    test('rejects non-numeric octets', () {
      expect(Ipv4Address.tryParse('172.16.a.1'), isNull);
    });
  });

  group('Ipv4Address comparisons', () {
    test('equal addresses are ==', () {
      expect(
        Ipv4Address.parse('172.16.14.26'),
        Ipv4Address.parse('172.16.14.26'),
      );
    });

    test('compareTo orders numerically', () {
      expect(
        Ipv4Address.parse(
          '172.16.14.1',
        ).compareTo(Ipv4Address.parse('172.16.14.2')),
        lessThan(0),
      );
    });
  });
}
