/// One network seen by the Mac's Wi-Fi radio.
class WifiNetwork {
  const WifiNetwork({this.ssid, this.bssid, required this.rssi, this.channel});

  final String? ssid;

  /// Radio MAC of the access point, normalized `aa:bb:cc:dd:ee:ff`.
  final String? bssid;
  final int rssi;
  final int? channel;

  /// 5/6 GHz channels start at 32.
  String get band => channel == null
      ? ''
      : channel! >= 32
      ? '5 GHz'
      : '2,4 GHz';
}

enum WifiScanStatus {
  ok,

  /// Location Services permission missing: macOS hides SSIDs/BSSIDs.
  denied,
  wifiOff,
  noWifi,
  error,

  /// Not running on macOS (e.g. tests).
  unsupported,
}

class WifiScan {
  const WifiScan({
    required this.status,
    this.networks = const [],
    this.currentSsid,
    this.currentBssid,
  });

  final WifiScanStatus status;
  final List<WifiNetwork> networks;
  final String? currentSsid;
  final String? currentBssid;
}
