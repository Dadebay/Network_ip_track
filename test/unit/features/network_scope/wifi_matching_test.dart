import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/network_scope/application/wifi_matching.dart';
import 'package:network_monitor/features/network_scope/domain/entities/wifi_scan.dart';
import 'package:network_monitor/features/network_scope/infrastructure/macos/macos_wifi_scanner.dart';

WifiNetwork net(String ssid, String bssid, {int rssi = -50, int channel = 6}) =>
    WifiNetwork(ssid: ssid, bssid: bssid, rssi: rssi, channel: channel);

void main() {
  final networks = [
    net('HENRY3', '50:c7:bf:11:22:34'),
    net('HENRY3_5G', '50:c7:bf:11:22:35', channel: 36),
    net('AkBulut', '52:c7:bf:11:22:33', rssi: -70),
    net('BENT_5G', 'a0:ab:1b:99:88:77'),
  ];

  test('BSSIDs a small offset from the LAN MAC match, closest first', () {
    final matches = wifiNetworksFor('50:c7:bf:11:22:33', networks);
    expect(matches.map((n) => n.ssid), ['HENRY3', 'AkBulut', 'HENRY3_5G']);
    expect(describeWifiNetworks(matches), 'HENRY3, AkBulut, HENRY3_5G');
  });

  test('unrelated or unknown MACs match nothing', () {
    expect(wifiNetworksFor('50:c7:bf:11:99:33', networks), isEmpty);
    expect(wifiNetworksFor(null, networks), isEmpty);
    expect(wifiNetworksFor('50:c7:bf:11:22:80', networks), isEmpty);
  });

  test('parses the native reply; blank SSIDs without permission = denied', () {
    final ok = parseWifiScanReply({
      'status': 'ok',
      'authorized': true,
      'currentSsid': 'Keenetic_R4C',
      'currentBssid': '0:1a:2b:3c:4d:5e',
      'networks': [
        {
          'ssid': 'HENRY3',
          'bssid': '50:c7:bf:11:22:34',
          'rssi': -48,
          'channel': 11,
        },
      ],
    });
    expect(ok.status, WifiScanStatus.ok);
    expect(ok.currentBssid, '00:1a:2b:3c:4d:5e');
    expect(ok.networks.single.band, '2,4 GHz');

    final denied = parseWifiScanReply({
      'status': 'ok',
      'authorized': false,
      'networks': [
        {'rssi': -48},
      ],
    });
    expect(denied.status, WifiScanStatus.denied);
    expect(
      parseWifiScanReply({'status': 'wifiOff'}).status,
      WifiScanStatus.wifiOff,
    );
  });
}
