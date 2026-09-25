import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/cidr.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/core/utils/private_network_blocks.dart';
import 'package:network_monitor/core/utils/subnet_mask.dart';

void main() {
  group('subnet mask <-> prefix length', () {
    test('converts common masks', () {
      expect(subnetMaskToPrefixLength(Ipv4Address.parse('255.255.255.0')), 24);
      expect(subnetMaskToPrefixLength(Ipv4Address.parse('255.255.0.0')), 16);
      expect(
        subnetMaskToPrefixLength(Ipv4Address.parse('255.255.255.252')),
        30,
      );
      expect(subnetMaskToPrefixLength(Ipv4Address.parse('255.240.0.0')), 12);
    });

    test('round-trips prefix -> mask -> prefix', () {
      for (final prefix in [0, 8, 12, 16, 24, 30, 31, 32]) {
        final mask = prefixLengthToSubnetMask(prefix);
        expect(subnetMaskToPrefixLength(mask), prefix);
      }
    });

    test('rejects a non-contiguous mask', () {
      expect(
        () => subnetMaskToPrefixLength(Ipv4Address.parse('255.0.255.0')),
        throwsFormatException,
      );
    });

    test('rejects an out-of-range prefix length', () {
      expect(() => prefixLengthToSubnetMask(33), throwsArgumentError);
      expect(() => prefixLengthToSubnetMask(-1), throwsArgumentError);
    });
  });

  group(
    'Cidr from address + mask (acceptance: 172.16.14.26 + 255.255.255.0)',
    () {
      test(
        'computes the /24 network, broadcast and gateway-compatible range',
        () {
          final cidr = Cidr.fromAddressAndMask(
            Ipv4Address.parse('172.16.14.26'),
            Ipv4Address.parse('255.255.255.0'),
          );
          expect(cidr.toString(), '172.16.14.0/24');
          expect(cidr.broadcastAddress.toString(), '172.16.14.255');
          expect(cidr.firstHost.toString(), '172.16.14.1');
          expect(cidr.lastHost.toString(), '172.16.14.254');
          expect(cidr.contains(Ipv4Address.parse('172.16.14.254')), isTrue);
        },
      );
    },
  );

  group('Cidr for /16, /30, /12', () {
    test('/16 network and broadcast', () {
      final cidr = Cidr.parse('172.20.5.9/16');
      expect(cidr.networkAddress.toString(), '172.20.0.0');
      expect(cidr.broadcastAddress.toString(), '172.20.255.255');
      expect(cidr.totalAddressCount, BigInt.from(65536));
    });

    test('/30 has exactly two usable hosts', () {
      final cidr = Cidr.parse('172.16.14.4/30');
      expect(cidr.networkAddress.toString(), '172.16.14.4');
      expect(cidr.broadcastAddress.toString(), '172.16.14.7');
      expect(cidr.firstHost.toString(), '172.16.14.5');
      expect(cidr.lastHost.toString(), '172.16.14.6');
    });

    test('/12 network and broadcast match the private 172 block', () {
      final cidr = Cidr.parse('172.16.0.0/12');
      expect(cidr.networkAddress.toString(), '172.16.0.0');
      expect(cidr.broadcastAddress.toString(), '172.31.255.255');
      expect(cidr.totalAddressCount, BigInt.from(1048576));
    });

    test('/31 and /32 have no usable host range', () {
      expect(Cidr.parse('172.16.14.0/31').firstHost, isNull);
      expect(Cidr.parse('172.16.14.0/32').lastHost, isNull);
    });
  });

  group('invalid CIDR input', () {
    test('rejects missing prefix', () {
      expect(() => Cidr.parse('172.16.14.0'), throwsFormatException);
    });

    test('rejects out-of-range prefix', () {
      expect(() => Cidr.parse('172.16.14.0/33'), throwsArgumentError);
    });
  });

  group('172.16.0.0/12 boundaries (acceptance criteria)', () {
    test('172.16.0.0 and 172.31.255.255 are included', () {
      expect(
        isWithinPrivate172Block(
          Cidr.fromAddressAndPrefix(Ipv4Address.parse('172.16.0.0'), 32),
        ),
        isTrue,
      );
      expect(
        isWithinPrivate172Block(
          Cidr.fromAddressAndPrefix(Ipv4Address.parse('172.31.255.255'), 32),
        ),
        isTrue,
      );
    });

    test('172.15.255.255 and 172.32.0.0 are excluded', () {
      expect(
        isWithinPrivate172Block(
          Cidr.fromAddressAndPrefix(Ipv4Address.parse('172.15.255.255'), 32),
        ),
        isFalse,
      );
      expect(
        isWithinPrivate172Block(
          Cidr.fromAddressAndPrefix(Ipv4Address.parse('172.32.0.0'), 32),
        ),
        isFalse,
      );
    });

    test('the full 172.0.0.0/8 block is not treated as private', () {
      expect(isWithinPrivate172Block(Cidr.parse('172.0.0.0/8')), isFalse);
    });

    test('a /24 fully inside 172.16.0.0/12 is contained', () {
      expect(isWithinPrivate172Block(Cidr.parse('172.16.14.0/24')), isTrue);
    });
  });
}
