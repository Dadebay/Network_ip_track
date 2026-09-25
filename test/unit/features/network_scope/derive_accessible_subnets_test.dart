import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/cidr.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/network_scope/application/derive_accessible_subnets.dart';
import 'package:network_monitor/features/network_scope/domain/entities/route_entry.dart';
import 'package:network_monitor/features/network_scope/domain/entities/subnet_reachability.dart';
import 'package:network_monitor/features/network_scope/infrastructure/macos/macos_route_table_parser.dart';

void main() {
  group('deriveAccessibleSubnets on a real route table', () {
    test(
      'keeps only private-172 subnets, drops host routes and other blocks',
      () {
        final raw = File(
          'test/fixtures/route_table/netstat_rn_inet.txt',
        ).readAsStringSync();
        final routes = const MacosRouteTableParser().parse(raw);

        final subnets = deriveAccessibleSubnets(routes);

        expect(subnets.map((s) => s.cidr.toString()).toList(), [
          '172.16.14.0/24',
          '172.16.20.0/24',
          '172.20.0.0/16',
        ]);
        expect(subnets[0].reachability, SubnetReachability.directlyConnected);
        expect(subnets[1].reachability, SubnetReachability.routed);
        expect(subnets[2].reachability, SubnetReachability.routed);
      },
    );
  });

  group('deriveAccessibleSubnets normalization', () {
    RouteEntry route(
      String cidr, {
      required bool direct,
      String iface = 'en0',
    }) {
      return RouteEntry(
        destination: Cidr.parse(cidr),
        gateway: direct ? null : Ipv4Address.parse('172.16.14.254'),
        interfaceName: iface,
        isDefault: false,
        isDirectlyConnected: direct,
        rawFlags: direct ? 'UCS' : 'UGSc',
      );
    }

    test('retains broader reachability beside a more specific route', () {
      final subnets = deriveAccessibleSubnets([
        route('172.16.0.0/12', direct: false),
        route('172.16.14.0/24', direct: true),
      ]);

      expect(subnets.map((s) => s.cidr.toString()).toList(), [
        '172.16.0.0/12',
        '172.16.14.0/24',
      ]);
      expect(subnets.first.reachability, SubnetReachability.routed);
      expect(subnets.last.reachability, SubnetReachability.directlyConnected);
    });

    test(
      'deduplicates identical destinations, preferring the more reachable entry',
      () {
        final subnets = deriveAccessibleSubnets([
          route('172.16.14.0/24', direct: false),
          route('172.16.14.0/24', direct: true),
        ]);

        expect(subnets, hasLength(1));
        expect(
          subnets.single.reachability,
          SubnetReachability.directlyConnected,
        );
      },
    );

    test('drops host routes (/32)', () {
      final subnets = deriveAccessibleSubnets([
        route('172.16.14.254/32', direct: true),
      ]);
      expect(subnets, isEmpty);
    });

    test('drops routes outside 172.16.0.0/12 entirely', () {
      final subnets = deriveAccessibleSubnets([
        route('10.0.0.0/24', direct: true),
        route('172.0.0.0/8', direct: false),
      ]);
      expect(subnets, isEmpty);
    });
  });
}
