import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/network_scope/infrastructure/macos/macos_ifconfig_parser.dart';

void main() {
  late String rawOutput;

  setUpAll(() {
    rawOutput = File('test/fixtures/ifconfig/sample.txt').readAsStringSync();
  });

  test('parses every interface block', () {
    final interfaces = parseIfconfigOutput(rawOutput);
    expect(
      interfaces.map((i) => i.name),
      containsAll(['lo0', 'gif0', 'stf0', 'en0', 'en5', 'utun0', 'bridge0']),
    );
  });

  test('extracts the IPv4 address and netmask for en0', () {
    final interfaces = parseIfconfigOutput(rawOutput);
    final en0 = interfaces.firstWhere((i) => i.name == 'en0');
    expect(en0.inetAddress.toString(), '172.16.14.26');
    expect(en0.netmask.toString(), '255.255.255.0');
    expect(en0.isUp, isTrue);
  });

  test('flags loopback correctly', () {
    final interfaces = parseIfconfigOutput(rawOutput);
    final lo0 = interfaces.firstWhere((i) => i.name == 'lo0');
    expect(lo0.isLoopback, isTrue);
  });

  test('leaves inet fields null for interfaces without an IPv4 address', () {
    final interfaces = parseIfconfigOutput(rawOutput);
    final gif0 = interfaces.firstWhere((i) => i.name == 'gif0');
    expect(gif0.inetAddress, isNull);
    expect(gif0.netmask, isNull);
  });

  test('does not confuse inet6 lines with inet lines', () {
    final interfaces = parseIfconfigOutput(rawOutput);
    final utun0 = interfaces.firstWhere((i) => i.name == 'utun0');
    expect(utun0.inetAddress.toString(), '10.10.10.2');
  });

  test(
    'parses the point-to-point `inet A --> B netmask C` form used by VPN tunnels',
    () {
      final interfaces = parseIfconfigOutput(rawOutput);
      final utun74 = interfaces.firstWhere((i) => i.name == 'utun74');
      expect(utun74.inetAddress.toString(), '198.18.0.1');
      expect(utun74.netmask.toString(), '255.255.0.0');
    },
  );
}
