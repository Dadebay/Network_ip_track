import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/discovery/infrastructure/macos/macos_arp_table_parser.dart';

void main() {
  const parser = MacosArpTableParser();

  test('parses IP/MAC/interface for every complete entry', () {
    final raw = File('test/fixtures/arp/arp_a_sample.txt').readAsStringSync();
    final entries = parser.parse(raw);

    expect(entries, hasLength(4));
    final gateway = entries.firstWhere(
      (e) => e.ipAddress.toString() == '172.16.14.254',
    );
    expect(gateway.macAddress, 'ac:de:48:aa:bb:cc');
    expect(gateway.interfaceName, 'en0');
  });

  test('normalizes single-digit hex octets with leading zeros', () {
    final raw = File('test/fixtures/arp/arp_a_sample.txt').readAsStringSync();
    final entries = parser.parse(raw);

    final router = entries.firstWhere(
      (e) => e.ipAddress.toString() == '172.16.14.1',
    );
    expect(router.macAddress, '00:1a:2b:3c:4d:5e');

    final iphone = entries.firstWhere(
      (e) => e.ipAddress.toString() == '172.16.14.12',
    );
    expect(iphone.macAddress, 'a4:83:e7:01:02:03');
  });

  test('skips incomplete entries', () {
    final raw = File('test/fixtures/arp/arp_a_sample.txt').readAsStringSync();
    final entries = parser.parse(raw);

    expect(
      entries.any((e) => e.ipAddress.toString() == '172.16.14.99'),
      isFalse,
    );
  });

  test('parses single-address `arp -n <ip>` output', () {
    final hit = parser.parse(
      File('test/fixtures/arp/arp_n_single.txt').readAsStringSync(),
    );
    expect(hit.single.macAddress, 'a4:83:e7:01:02:03');

    final miss = parser.parse(
      File('test/fixtures/arp/arp_n_no_entry.txt').readAsStringSync(),
    );
    expect(miss, isEmpty);
  });
}
