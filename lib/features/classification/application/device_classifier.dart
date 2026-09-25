import '../../../core/utils/mac_address.dart';
import '../../devices/domain/entities/device_confidence.dart';
import '../../devices/domain/entities/device_type.dart';
import '../../discovery/domain/entities/discovered_device.dart';
import '../../discovery/domain/repositories/http_banner_provider.dart';
import '../domain/entities/device_classification.dart';

/// Rule-based device type/OS classifier with confidence levels.
///
/// Every rule contributes weighted evidence (0–1) for a type and/or an OS,
/// with a human-readable reason. Evidence for the same answer combines as a
/// noisy-OR (`1 − Π(1 − w)`), so independent weak signals add up but never
/// reach certainty. The leading answer must clear a score threshold *and*
/// beat the runner-up by a margin; otherwise the result stays `Bilinmiyor`
/// — an Apple MAC alone can't tell a phone from a Mac.
///
/// `Kesin` is reserved for facts: the route table's gateway and this Mac.
class DeviceClassifier {
  const DeviceClassifier();

  static const _highScore = 0.85;
  static const _highMargin = 0.25;
  static const _estimatedScore = 0.45;
  static const _estimatedMargin = 0.15;

  /// `1 − (1 − w)` isn't exactly `w` in floating point; compare with slack
  /// so a single rule of weight 0.45 meets the 0.45 threshold.
  static const _epsilon = 1e-9;

  DeviceClassification classify({
    required DiscoveredDevice device,
    String? vendor,
    bool isGateway = false,
    bool isLocalDevice = false,
  }) {
    final evidence = <_Evidence>[
      ..._macEvidence(device.macAddress, vendor),
      ..._hostnameEvidence(device.hostname),
      ..._mdnsEvidence(device),
      ..._ssdpEvidence(device.ssdpServices),
      ..._webEvidence(device.httpBanner),
      ..._netbiosEvidence(device.netbiosName),
      ..._portEvidence(device.openPorts),
      ..._ttlEvidence(device.ttl),
    ];

    final (os, osConfidence, osReasons) = _decide<String>(
      evidence.where((e) => e.os != null),
      (e) => e.os!,
    );
    final (
      decidedType,
      decidedTypeConfidence,
      typeReasons,
    ) = _decide<DeviceType>(
      evidence.where((e) => e.type != null),
      (e) => e.type!,
    );
    var type = decidedType ?? DeviceType.unknown;
    var typeConfidence = decidedTypeConfidence;

    String? finalOs = os;
    DeviceConfidence? finalOsConfidence = os == null ? null : osConfidence;
    final reasons = <String>[];

    if (isLocalDevice) {
      type = DeviceType.mac;
      typeConfidence = DeviceConfidence.certain;
      finalOs = 'macOS';
      finalOsConfidence = DeviceConfidence.certain;
      reasons.add('Bu Mac: uygulamanın çalıştığı cihazın kendi adresi');
    } else if (isGateway) {
      type = DeviceType.routerGateway;
      typeConfidence = DeviceConfidence.certain;
      reasons.add('Route tablosundaki varsayılan gateway');
    }

    reasons.addAll([
      ...typeReasons,
      for (final reason in osReasons)
        if (!typeReasons.contains(reason)) reason,
    ]);
    if (type == DeviceType.unknown && reasons.isEmpty) {
      reasons.addAll(
        evidence.isEmpty
            ? const ['Sınıflandırma için yeterli sinyal yok']
            : [
                'Sinyaller tek bir türü desteklemiyor:',
                ...{for (final e in evidence) e.reason},
              ],
      );
    }
    final mac = device.macAddress;
    if (mac != null && isLocallyAdministeredMac(mac)) {
      reasons.add(
        'Özel/rastgele MAC: üretici tespit edilemez ve cihaz kimliği '
        'değişebilir',
      );
    }

    return DeviceClassification(
      type: type,
      typeConfidence: typeConfidence,
      os: finalOs,
      osConfidence: finalOsConfidence,
      reasons: reasons,
    );
  }

  /// Picks the best-supported answer. Returns it with its confidence and the
  /// reasons behind it (strongest first), or `(null, unknown, [])` when
  /// nothing clears the thresholds.
  (T?, DeviceConfidence, List<String>) _decide<T>(
    Iterable<_Evidence> evidence,
    T Function(_Evidence) keyOf,
  ) {
    final byAnswer = <T, List<_Evidence>>{};
    for (final e in evidence) {
      (byAnswer[keyOf(e)] ??= []).add(e);
    }
    if (byAnswer.isEmpty) {
      return (null, DeviceConfidence.unknown, const []);
    }

    double score(List<_Evidence> items) =>
        1 - items.fold<double>(1, (product, e) => product * (1 - e.weight));

    final ranked = byAnswer.entries.toList()
      ..sort((a, b) => score(b.value).compareTo(score(a.value)));
    final best = score(ranked.first.value);
    final runnerUp = ranked.length > 1 ? score(ranked[1].value) : 0.0;
    final margin = best - runnerUp;

    final DeviceConfidence confidence;
    bool atLeast(double value, double threshold) =>
        value + _epsilon >= threshold;
    if (atLeast(best, _highScore) && atLeast(margin, _highMargin)) {
      confidence = DeviceConfidence.highProbability;
    } else if (atLeast(best, _estimatedScore) &&
        atLeast(margin, _estimatedMargin)) {
      confidence = DeviceConfidence.estimated;
    } else {
      return (null, DeviceConfidence.unknown, const []);
    }

    final reasons = [
      for (final e
          in (ranked.first.value.toList()
            ..sort((a, b) => b.weight.compareTo(a.weight))))
        e.reason,
    ];
    return (ranked.first.key, confidence, {...reasons}.toList());
  }

  // --- Rules -------------------------------------------------------------

  Iterable<_Evidence> _macEvidence(String? mac, String? vendor) sync* {
    // A locally-administered (randomized) MAC is noted separately as a
    // caveat in classify() — it does not by itself indicate a phone: modern
    // tablets, laptops and IoT devices randomize MACs too, so alone it must
    // not push the result past `Bilinmiyor`.
    if (vendor == null) return;
    final v = vendor.toLowerCase();
    final reason = 'Üretici (OUI): $vendor';
    for (final rule in _vendorRules) {
      if (rule.keywords.any(v.contains)) {
        for (final (type, weight) in rule.types) {
          yield _Evidence(type: type, weight: weight, reason: reason);
        }
        if (rule.os case (final os, final weight)) {
          yield _Evidence(os: os, weight: weight, reason: reason);
        }
        return;
      }
    }
  }

  Iterable<_Evidence> _hostnameEvidence(String? hostname) sync* {
    if (hostname == null) return;
    final name = hostname.toLowerCase().split('.').first;
    for (final rule in _hostnameRules) {
      if (rule.pattern.hasMatch(name)) {
        final reason = 'Hostname "$hostname"';
        if (rule.type != null) {
          yield _Evidence(type: rule.type, weight: rule.weight, reason: reason);
        }
        if (rule.os != null) {
          yield _Evidence(os: rule.os, weight: rule.weight, reason: reason);
        }
        return;
      }
    }
  }

  Iterable<_Evidence> _mdnsEvidence(DiscoveredDevice device) sync* {
    for (final record in device.mdnsRecords) {
      final type = record.serviceType;
      final model = record.txt['model'] ?? '';
      final service = 'mDNS servisi $type';

      if (model.isNotEmpty) {
        final reason = 'mDNS cihaz modeli "$model"';
        if (RegExp(
          r'^(macbook|imac|macmini|macpro|mac\d|xserve)',
          caseSensitive: false,
        ).hasMatch(model)) {
          yield _Evidence(type: DeviceType.mac, weight: 0.95, reason: reason);
          yield _Evidence(os: 'macOS', weight: 0.95, reason: reason);
        } else if (model.toLowerCase().startsWith('iphone')) {
          yield _Evidence(type: DeviceType.phone, weight: 0.95, reason: reason);
          yield _Evidence(os: 'iOS', weight: 0.95, reason: reason);
        } else if (model.toLowerCase().startsWith('ipad')) {
          yield _Evidence(
            type: DeviceType.tablet,
            weight: 0.95,
            reason: reason,
          );
          yield _Evidence(os: 'iPadOS', weight: 0.95, reason: reason);
        } else if (model.toLowerCase().startsWith('appletv')) {
          yield _Evidence(
            type: DeviceType.smartTvMedia,
            weight: 0.95,
            reason: reason,
          );
          yield _Evidence(os: 'tvOS', weight: 0.9, reason: reason);
        } else if (model.toLowerCase().startsWith('audioaccessory')) {
          yield _Evidence(
            type: DeviceType.smartTvMedia,
            weight: 0.9,
            reason: '$reason (HomePod)',
          );
        }
      }

      switch (type) {
        case '_ipp._tcp' ||
            '_ipps._tcp' ||
            '_printer._tcp' ||
            '_pdl-datastream._tcp':
          yield _Evidence(
            type: DeviceType.printer,
            weight: 0.85,
            reason: '$service (yazdırma)',
          );
        case '_googlecast._tcp':
          final md = record.txt['md'];
          yield _Evidence(
            type: DeviceType.smartTvMedia,
            weight: 0.85,
            reason: md == null
                ? '$service (Chromecast/Google Cast)'
                : '$service ($md)',
          );
        case '_hap._tcp' || '_homekit._tcp':
          yield _Evidence(
            type: DeviceType.iotSmartHome,
            weight: 0.8,
            reason: '$service (HomeKit aksesuarı)',
          );
        case '_airplay._tcp' || '_raop._tcp':
          yield _Evidence(
            type: DeviceType.smartTvMedia,
            weight: 0.3,
            reason: '$service (AirPlay)',
          );
        case '_spotify-connect._tcp':
          yield _Evidence(
            type: DeviceType.smartTvMedia,
            weight: 0.4,
            reason: service,
          );
        case '_afpovertcp._tcp':
          yield _Evidence(
            type: DeviceType.mac,
            weight: 0.4,
            reason: '$service (AFP dosya paylaşımı)',
          );
          yield _Evidence(
            os: 'macOS',
            weight: 0.35,
            reason: '$service (AFP dosya paylaşımı)',
          );
        case '_smb._tcp':
          yield _Evidence(
            type: DeviceType.windowsComputer,
            weight: 0.2,
            reason: '$service (SMB)',
          );
        case '_ssh._tcp':
          yield _Evidence(
            type: DeviceType.linuxComputerServer,
            weight: 0.25,
            reason: '$service (SSH)',
          );
      }
    }
  }

  Iterable<_Evidence> _ssdpEvidence(List<String> ssdp) sync* {
    if (ssdp.isEmpty) return;
    final text = ssdp.join(' ').toLowerCase();
    const reason = 'SSDP/UPnP yanıtı';
    if (text.contains('internetgatewaydevice') ||
        text.contains('wanipconnection')) {
      yield const _Evidence(
        type: DeviceType.routerGateway,
        weight: 0.8,
        reason: '$reason (Internet Gateway Device)',
      );
    }
    if (text.contains('sonos') || text.contains('roku')) {
      yield const _Evidence(
        type: DeviceType.smartTvMedia,
        weight: 0.9,
        reason: '$reason (medya oynatıcı)',
      );
    } else if (text.contains('mediarenderer') ||
        text.contains('dial-multiscreen')) {
      yield const _Evidence(
        type: DeviceType.smartTvMedia,
        weight: 0.7,
        reason: '$reason (MediaRenderer/DIAL)',
      );
    }
    if (text.contains('xbox') || text.contains('playstation')) {
      yield const _Evidence(
        type: DeviceType.gameConsole,
        weight: 0.85,
        reason: '$reason (oyun konsolu)',
      );
    }
    if (text.contains('printer')) {
      yield const _Evidence(
        type: DeviceType.printer,
        weight: 0.7,
        reason: '$reason (yazıcı)',
      );
    }
    if (text.contains('windows')) {
      yield const _Evidence(
        type: DeviceType.windowsComputer,
        weight: 0.5,
        reason: '$reason (Windows sunucu başlığı)',
      );
      yield const _Evidence(
        os: 'Windows',
        weight: 0.6,
        reason: '$reason (Windows sunucu başlığı)',
      );
    }
  }

  Iterable<_Evidence> _webEvidence(HttpBanner? banner) sync* {
    if (banner == null) return;
    final text = banner.searchText;
    final reason = 'Web arayüzü: ${banner.describe()}';
    for (final rule in _webRules) {
      if (rule.pattern.hasMatch(text)) {
        if (rule.type != null) {
          yield _Evidence(type: rule.type, weight: rule.weight, reason: reason);
        }
        if (rule.os != null) {
          yield _Evidence(os: rule.os, weight: rule.weight, reason: reason);
        }
        return;
      }
    }
  }

  Iterable<_Evidence> _netbiosEvidence(String? name) sync* {
    if (name == null) return;
    final reason = 'NetBIOS adı "$name" (Windows veya Samba)';
    yield _Evidence(
      type: DeviceType.windowsComputer,
      weight: 0.45,
      reason: reason,
    );
    yield _Evidence(os: 'Windows', weight: 0.45, reason: reason);
  }

  Iterable<_Evidence> _portEvidence(List<int> ports) sync* {
    if (ports.isEmpty) return;
    final open = ports.toSet();
    if (open.contains(9100)) {
      yield const _Evidence(
        type: DeviceType.printer,
        weight: 0.7,
        reason: 'Port 9100 açık (ham yazdırma)',
      );
    }
    if (open.contains(631)) {
      yield const _Evidence(
        type: DeviceType.printer,
        weight: 0.5,
        reason: 'Port 631 açık (IPP)',
      );
    }
    if (open.contains(548)) {
      yield const _Evidence(
        type: DeviceType.mac,
        weight: 0.45,
        reason: 'Port 548 açık (AFP)',
      );
      yield const _Evidence(
        os: 'macOS',
        weight: 0.35,
        reason: 'Port 548 açık (AFP)',
      );
    }
    if (open.containsAll(const {139, 445})) {
      yield const _Evidence(
        type: DeviceType.windowsComputer,
        weight: 0.35,
        reason: 'Port 139 ve 445 açık (SMB/NetBIOS)',
      );
      yield const _Evidence(
        os: 'Windows',
        weight: 0.3,
        reason: 'Port 139 ve 445 açık (SMB/NetBIOS)',
      );
    }
    if (open.contains(53)) {
      yield _Evidence(
        type: DeviceType.routerGateway,
        weight: open.contains(80) || open.contains(443) ? 0.6 : 0.5,
        reason: 'Port 53 açık (DNS sunucusu)',
      );
    }
    if (open.contains(8008) || open.contains(8009)) {
      yield const _Evidence(
        type: DeviceType.smartTvMedia,
        weight: 0.6,
        reason: 'Port 8008/8009 açık (Google Cast)',
      );
    }
    if (open.length == 1 && open.contains(22)) {
      yield const _Evidence(
        type: DeviceType.linuxComputerServer,
        weight: 0.25,
        reason: 'Yalnızca port 22 açık (SSH)',
      );
    }
  }

  Iterable<_Evidence> _ttlEvidence(int? ttl) sync* {
    if (ttl == null) return;
    if (ttl > 64 && ttl <= 128) {
      yield _Evidence(
        os: 'Windows',
        weight: 0.35,
        reason: 'TTL $ttl (Windows varsayılanı 128, zayıf sinyal)',
      );
    } else if (ttl > 128) {
      yield _Evidence(
        type: DeviceType.routerGateway,
        weight: 0.3,
        reason: 'TTL $ttl (ağ cihazı varsayılanı 255, zayıf sinyal)',
      );
    }
  }
}

class _Evidence {
  const _Evidence({
    required this.weight,
    required this.reason,
    this.type,
    this.os,
  });

  final DeviceType? type;
  final String? os;
  final double weight;
  final String reason;
}

class _VendorRule {
  const _VendorRule(this.keywords, this.types, [this.os]);

  final List<String> keywords;
  final List<(DeviceType, double)> types;
  final (String, double)? os;
}

/// Matched against the lowercased IEEE organization name; first match wins.
const _vendorRules = [
  _VendorRule(
    ['apple'],
    [
      (DeviceType.phone, 0.35),
      (DeviceType.mac, 0.35),
      (DeviceType.tablet, 0.2),
    ],
  ),
  _VendorRule(['raspberry pi'], [(DeviceType.linuxComputerServer, 0.6)], (
    'Linux',
    0.6,
  )),
  _VendorRule(
    ['sony interactive', 'nintendo'],
    [(DeviceType.gameConsole, 0.7)],
  ),
  _VendorRule(['sonos', 'roku'], [(DeviceType.smartTvMedia, 0.75)]),
  _VendorRule(
    [
      'canon',
      'seiko epson',
      'brother industries',
      'xerox',
      'lexmark',
      'kyocera',
      'ricoh',
      'konica',
    ],
    [(DeviceType.printer, 0.55)],
  ),
  _VendorRule(
    ['hewlett packard', 'hp inc'],
    [(DeviceType.printer, 0.4), (DeviceType.windowsComputer, 0.2)],
  ),
  _VendorRule(
    [
      'espressif',
      'tuya',
      'allterco',
      'shelly',
      'signify',
      'philips lighting',
      'nest labs',
      'ecobee',
      'itead',
    ],
    [(DeviceType.iotSmartHome, 0.55)],
  ),
  _VendorRule(
    [
      'cisco',
      'ubiquiti',
      'routerboard',
      'mikrotik',
      'juniper',
      'aruba',
      'netgear',
      'tp-link',
      'zyxel',
      'd-link',
      'avm gmbh',
      'fortinet',
    ],
    [(DeviceType.routerGateway, 0.4)],
  ),
  _VendorRule(
    [
      'samsung',
      'xiaomi',
      'huawei',
      'oneplus',
      'oppo',
      'vivo mobile',
      'motorola mobility',
    ],
    [(DeviceType.phone, 0.4), (DeviceType.smartTvMedia, 0.15)],
  ),
  _VendorRule(
    ['lg electronics'],
    [(DeviceType.smartTvMedia, 0.35), (DeviceType.phone, 0.15)],
  ),
  _VendorRule(
    ['google'],
    [(DeviceType.smartTvMedia, 0.35), (DeviceType.phone, 0.25)],
  ),
  _VendorRule(
    ['amazon'],
    [(DeviceType.iotSmartHome, 0.35), (DeviceType.smartTvMedia, 0.3)],
  ),
  _VendorRule(
    ['microsoft'],
    [(DeviceType.gameConsole, 0.25), (DeviceType.windowsComputer, 0.25)],
  ),
  _VendorRule(
    ['dell', 'lenovo', 'lcfc'],
    [(DeviceType.windowsComputer, 0.35)],
    ('Windows', 0.3),
  ),
  // Motherboard / PC NIC makers. ASUS also sells routers, hence the small
  // router weight — a router web banner still wins over this.
  _VendorRule(
    ['asustek'],
    [(DeviceType.windowsComputer, 0.45), (DeviceType.routerGateway, 0.1)],
  ),
  _VendorRule(
    ['giga-byte', 'gigabyte', 'micro-star', 'asrock', 'intel corporate'],
    [(DeviceType.windowsComputer, 0.45)],
  ),
  _VendorRule(['super micro'], [(DeviceType.linuxComputerServer, 0.5)]),
  // Unlike TP-Link/Netgear (smart plugs, cameras too), these sell almost
  // only routers/APs/switches, so the vendor alone clears `Tahmini`.
  _VendorRule(
    ['tenda', 'mercusys', 'totolink', 'keenetic', 'ruijie', 'h3c'],
    [(DeviceType.routerGateway, 0.45)],
  ),
  _VendorRule(
    ['vmware', 'parallels', 'qemu'],
    [(DeviceType.linuxComputerServer, 0.3)],
  ),
  _VendorRule(
    [
      'dahua',
      'hikvision',
      'uniview',
      'axis communications',
      'vivotek',
      'reolink',
      'amcrest',
      'foscam',
      'annke',
      'swann communications',
      'lorex',
      'eufy',
    ],
    [(DeviceType.camera, 0.65)],
  ),
];

class _HostnameRule {
  _HostnameRule(String pattern, {this.type, this.os, required this.weight})
    : pattern = RegExp(pattern);

  final RegExp pattern;
  final DeviceType? type;
  final String? os;
  final double weight;
}

/// Matched against the lowercased web-interface title/server/realm.
final _webRules = [
  _HostnameRule(
    r'fortigate|fortinet|fortios',
    type: DeviceType.routerGateway,
    os: 'FortiOS',
    weight: 0.9,
  ),
  _HostnameRule(
    r'mikrotik|routeros',
    type: DeviceType.routerGateway,
    os: 'RouterOS',
    weight: 0.9,
  ),
  _HostnameRule(
    r'openwrt|luci',
    type: DeviceType.routerGateway,
    os: 'OpenWrt',
    weight: 0.85,
  ),
  _HostnameRule(
    r'unifi|ubiquiti|omada|tp-link|tplink|eap\d|zyxel|netgear|aruba|cisco|routerboard',
    type: DeviceType.routerGateway,
    weight: 0.7,
  ),
  _HostnameRule(
    r'dahua|hikvision|uniview|\bnvr\b|\bdvr\b|\bipc\b|ip ?camera|network camera|netsurveillance|web service',
    type: DeviceType.camera,
    os: 'Gömülü Linux',
    weight: 0.8,
  ),
  _HostnameRule(
    r'printer|laserjet|officejet|deskjet|epson|canon|brother|kyocera|xerox|ricoh|lexmark|embedded web server',
    type: DeviceType.printer,
    weight: 0.8,
  ),
  _HostnameRule(
    r'synology|diskstation|qnap|truenas|nas\b',
    type: DeviceType.linuxComputerServer,
    os: 'Linux (NAS)',
    weight: 0.8,
  ),
  _HostnameRule(
    r'microsoft-iis|windows',
    type: DeviceType.windowsComputer,
    os: 'Windows',
    weight: 0.5,
  ),
  _HostnameRule(
    r'shelly|tasmota|esphome|sonoff',
    type: DeviceType.iotSmartHome,
    weight: 0.8,
  ),
];

/// Matched against the lowercased first label of the hostname.
final _hostnameRules = [
  _HostnameRule('iphone', type: DeviceType.phone, os: 'iOS', weight: 0.8),
  _HostnameRule('ipad', type: DeviceType.tablet, os: 'iPadOS', weight: 0.8),
  _HostnameRule(
    r'apple-?tv',
    type: DeviceType.smartTvMedia,
    os: 'tvOS',
    weight: 0.85,
  ),
  _HostnameRule(
    r'macbook|imac|mac-?mini|mac-?pro|mac-?studio',
    type: DeviceType.mac,
    os: 'macOS',
    weight: 0.8,
  ),
  _HostnameRule(
    r'android|galaxy|pixel|redmi|oneplus',
    type: DeviceType.phone,
    os: 'Android',
    weight: 0.6,
  ),
  _HostnameRule(
    r'^(desktop|laptop)-[a-z0-9]{6,8}$',
    type: DeviceType.windowsComputer,
    os: 'Windows',
    weight: 0.75,
  ),
  _HostnameRule(
    'raspberrypi',
    type: DeviceType.linuxComputerServer,
    os: 'Linux',
    weight: 0.75,
  ),
  _HostnameRule(
    r'ubuntu|debian|fedora|centos',
    type: DeviceType.linuxComputerServer,
    os: 'Linux',
    weight: 0.6,
  ),
  _HostnameRule(
    r'printer|laserjet|officejet|deskjet|^brn[0-9a-f]{12}|^epson|^canon',
    type: DeviceType.printer,
    weight: 0.7,
  ),
  _HostnameRule(
    r'chromecast|roku|fire-?tv|bravia|smart-?tv|webos',
    type: DeviceType.smartTvMedia,
    weight: 0.75,
  ),
  _HostnameRule(
    r'xbox|playstation|^ps[45]|nintendo',
    type: DeviceType.gameConsole,
    weight: 0.75,
  ),
  _HostnameRule(
    r'^esp[-_]|esp32|esp8266|shelly|tasmota|sonoff',
    type: DeviceType.iotSmartHome,
    weight: 0.7,
  ),
  _HostnameRule(
    r'^router|^gateway|fritz\.?box|openwrt|mikrotik|unifi',
    type: DeviceType.routerGateway,
    weight: 0.6,
  ),
  _HostnameRule(
    r'ipcam|ip-cam|dahua|hikvision|^nvr|^dvr',
    type: DeviceType.camera,
    weight: 0.65,
  ),
];
