import 'package:flutter/services.dart';

import '../../domain/entities/wifi_scan.dart';

/// Wi-Fi scan via the app's native `network_monitor/wifi` channel
/// (CoreWLAN). The first call may show the Location Services prompt.
class MacosWifiScanner {
  const MacosWifiScanner();

  static const _channel = MethodChannel('network_monitor/wifi');

  Future<WifiScan> scan() async {
    final Map<Object?, Object?>? reply;
    try {
      reply = await _channel.invokeMapMethod<Object?, Object?>('scan');
    } on MissingPluginException {
      return const WifiScan(status: WifiScanStatus.unsupported);
    } on PlatformException {
      return const WifiScan(status: WifiScanStatus.error);
    }
    return parseWifiScanReply(reply ?? const {});
  }
}

/// Pure and fixture-testable.
WifiScan parseWifiScanReply(Map<Object?, Object?> reply) {
  var status = switch (reply['status']) {
    'ok' => WifiScanStatus.ok,
    'wifiOff' => WifiScanStatus.wifiOff,
    'noWifi' => WifiScanStatus.noWifi,
    _ => WifiScanStatus.error,
  };
  final networks = [
    for (final raw in (reply['networks'] as List<Object?>?) ?? const [])
      if (raw is Map)
        WifiNetwork(
          ssid: raw['ssid'] as String?,
          bssid: _normalizeMac(raw['bssid'] as String?),
          rssi: (raw['rssi'] as int?) ?? -100,
          channel: raw['channel'] as int?,
        ),
  ];
  // Without Location permission CoreWLAN still scans but blanks every
  // SSID/BSSID — say so instead of showing nameless networks.
  if (status == WifiScanStatus.ok &&
      reply['authorized'] == false &&
      networks.every((n) => n.ssid == null)) {
    status = WifiScanStatus.denied;
  }
  return WifiScan(
    status: status,
    networks: networks,
    currentSsid: reply['currentSsid'] as String?,
    currentBssid: _normalizeMac(reply['currentBssid'] as String?),
  );
}

/// CoreWLAN prints BSSIDs without leading zeros (`0:1a:2b:…`).
String? _normalizeMac(String? mac) {
  if (mac == null) return null;
  final parts = mac.split(':');
  if (parts.length != 6) return null;
  return parts.map((p) => p.padLeft(2, '0').toLowerCase()).join(':');
}
