import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/network_scope/infrastructure/macos/macos_hardware_port_parser.dart';

void main() {
  test('maps device names to hardware port labels', () {
    final raw = File(
      'test/fixtures/networksetup/listallhardwareports.txt',
    ).readAsStringSync();
    final ports = parseHardwarePorts(raw);

    expect(ports['en0'], 'Wi-Fi');
    expect(ports['en5'], 'Thunderbolt Ethernet');
    expect(ports['bridge0'], 'Thunderbolt Bridge');
    expect(ports.containsKey('VLAN Configurations'), isFalse);
  });
}
