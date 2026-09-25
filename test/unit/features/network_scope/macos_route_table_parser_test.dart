import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/network_scope/infrastructure/macos/macos_route_table_parser.dart';

void main() {
  late String rawOutput;
  const parser = MacosRouteTableParser();

  setUpAll(() {
    rawOutput = File(
      'test/fixtures/route_table/netstat_rn_inet.txt',
    ).readAsStringSync();
  });

  test('parses one entry per Internet-section row', () {
    final entries = parser.parse(rawOutput);
    expect(entries, hasLength(12));
  });

  test('parses the default route', () {
    final entries = parser.parse(rawOutput);
    final defaultRoute = entries.firstWhere((e) => e.isDefault);
    expect(defaultRoute.destination.toString(), '0.0.0.0/0');
    expect(defaultRoute.gateway.toString(), '172.16.14.254');
    expect(defaultRoute.interfaceName, 'en0');
    expect(defaultRoute.isDirectlyConnected, isFalse);
  });

  test('infers classful prefix when the table omits an explicit /prefix', () {
    final entries = parser.parse(rawOutput);
    final loopback = entries.firstWhere(
      (e) => e.destination.toString() == '127.0.0.0/8',
    );
    expect(loopback.isDirectlyConnected, isTrue);

    final linkLocal = entries.firstWhere(
      (e) => e.destination.toString() == '169.254.0.0/16',
    );
    expect(linkLocal.gateway, isNull); // link#4 has no routable gateway
  });

  test('keeps an explicit /prefix instead of guessing from octet count', () {
    final entries = parser.parse(rawOutput);
    final multicast = entries.firstWhere((e) => e.rawFlags == 'UmCS');
    expect(multicast.destination.toString(), '224.0.0.0/4');
  });

  test('classifies directly-connected vs routed subnets via the G flag', () {
    final entries = parser.parse(rawOutput);

    final direct = entries.firstWhere(
      (e) => e.destination.toString() == '172.16.14.0/24',
    );
    expect(direct.isDirectlyConnected, isTrue);
    expect(direct.gateway, isNull);

    final routed = entries.firstWhere(
      (e) => e.destination.toString() == '172.16.20.0/24',
    );
    expect(routed.isDirectlyConnected, isFalse);
    expect(routed.gateway.toString(), '172.16.14.254');
  });

  test('parses a /32 host route', () {
    final entries = parser.parse(rawOutput);
    final host = entries.firstWhere(
      (e) => e.destination.toString() == '172.16.14.254/32',
    );
    expect(host.interfaceName, 'en0');
  });
}
