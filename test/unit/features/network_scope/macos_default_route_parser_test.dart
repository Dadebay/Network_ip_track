import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/network_scope/infrastructure/macos/macos_default_route_parser.dart';

void main() {
  test('extracts interface and gateway from `route -n get default` output', () {
    final raw = File(
      'test/fixtures/route_table/route_get_default.txt',
    ).readAsStringSync();
    final parsed = parseDefaultRouteOutput(raw);

    expect(parsed.interfaceName, 'en0');
    expect(parsed.gateway.toString(), '172.16.14.254');
    expect(parsed.isKnown, isTrue);
  });

  test('reports unknown when the expected lines are missing', () {
    final parsed = parseDefaultRouteOutput(
      'route to: default\ndestination: default\n',
    );
    expect(parsed.isKnown, isFalse);
    expect(parsed.gateway, isNull);
  });
}
