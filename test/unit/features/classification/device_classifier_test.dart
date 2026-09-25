import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/classification/application/device_classifier.dart';
import 'package:network_monitor/features/classification/domain/entities/device_classification.dart';
import 'package:network_monitor/features/devices/domain/entities/device_confidence.dart';
import 'package:network_monitor/features/devices/domain/entities/device_type.dart';
import 'package:network_monitor/features/discovery/domain/entities/discovered_device.dart';
import 'package:network_monitor/features/discovery/domain/entities/mdns_service_record.dart';

DiscoveredDevice device({
  String? mac,
  String? hostname,
  String? netbiosName,
  int? ttl,
  List<MdnsServiceRecord> mdns = const [],
  List<String> ssdp = const [],
  List<int> ports = const [],
}) => DiscoveredDevice(
  ipAddress: Ipv4Address.parse('172.16.14.50'),
  respondedAt: DateTime(2026, 9, 25),
  macAddress: mac,
  hostname: hostname,
  netbiosName: netbiosName,
  ttl: ttl,
  mdnsRecords: mdns,
  ssdpServices: ssdp,
  openPorts: ports,
);

void main() {
  const classifier = DeviceClassifier();

  DeviceClassification classify(
    DiscoveredDevice d, {
    String? vendor,
    bool isGateway = false,
    bool isLocalDevice = false,
  }) => classifier.classify(
    device: d,
    vendor: vendor,
    isGateway: isGateway,
    isLocalDevice: isLocalDevice,
  );

  test('no signals: unknown, and says so', () {
    final result = classify(device());
    expect(result.type, DeviceType.unknown);
    expect(result.typeConfidence, DeviceConfidence.unknown);
    expect(result.os, isNull);
    expect(result.reasons, ['Sınıflandırma için yeterli sinyal yok']);
  });

  test('facts are certain: this Mac and the route-table gateway', () {
    final local = classify(device(), isLocalDevice: true);
    expect(local.type, DeviceType.mac);
    expect(local.typeConfidence, DeviceConfidence.certain);
    expect(local.os, 'macOS');
    expect(local.osConfidence, DeviceConfidence.certain);

    final gateway = classify(device(ports: [53, 80]), isGateway: true);
    expect(gateway.type, DeviceType.routerGateway);
    expect(gateway.typeConfidence, DeviceConfidence.certain);
    expect(gateway.reasons.first, 'Route tablosundaki varsayılan gateway');
  });

  test('an Apple MAC alone is ambiguous (phone vs Mac vs tablet)', () {
    final result = classify(
      device(mac: 'a4:83:e7:01:02:03'),
      vendor: 'Apple, Inc.',
    );
    expect(result.type, DeviceType.unknown);
    expect(result.typeConfidence, DeviceConfidence.unknown);
    expect(result.reasons, contains('Üretici (OUI): Apple, Inc.'));
  });

  test('Apple vendor + iPhone hostname: phone/iOS, high probability', () {
    final result = classify(
      device(mac: 'a4:83:e7:01:02:03', hostname: 'Johns-iPhone.local'),
      vendor: 'Apple, Inc.',
    );
    expect(result.type, DeviceType.phone);
    expect(result.typeConfidence, DeviceConfidence.highProbability);
    expect(result.os, 'iOS');
    expect(
      result.reasons,
      containsAll([
        'Hostname "Johns-iPhone.local"',
        'Üretici (OUI): Apple, Inc.',
      ]),
    );
  });

  test('mDNS device-info model decides Mac vs iPad', () {
    final mac = classify(
      device(
        mdns: [
          const MdnsServiceRecord(
            instanceName: 'Office',
            serviceType: '_device-info._tcp',
            txt: {'model': 'MacBookPro18,3'},
          ),
        ],
      ),
    );
    expect(mac.type, DeviceType.mac);
    expect(mac.typeConfidence, DeviceConfidence.highProbability);
    expect(mac.os, 'macOS');

    final ipad = classify(
      device(
        mdns: [
          const MdnsServiceRecord(
            instanceName: 'Tablet',
            serviceType: '_device-info._tcp',
            txt: {'model': 'iPad13,4'},
          ),
        ],
      ),
    );
    expect(ipad.type, DeviceType.tablet);
    expect(ipad.os, 'iPadOS');
  });

  test('IPP service + port 9100: printer, high probability', () {
    final result = classify(
      device(
        mdns: [
          const MdnsServiceRecord(
            instanceName: 'HP OfficeJet',
            serviceType: '_ipp._tcp',
            txt: {'ty': 'HP OfficeJet Pro 9010'},
          ),
        ],
        ports: [80, 631, 9100],
      ),
    );
    expect(result.type, DeviceType.printer);
    expect(result.typeConfidence, DeviceConfidence.highProbability);
  });

  test('Windows: default hostname + NetBIOS + TTL 128', () {
    final result = classify(
      device(
        hostname: 'DESKTOP-AB12CD3',
        netbiosName: 'DESKTOP-AB12CD3',
        ttl: 128,
        ports: [139, 445],
      ),
    );
    expect(result.type, DeviceType.windowsComputer);
    expect(result.typeConfidence, DeviceConfidence.highProbability);
    expect(result.os, 'Windows');
    expect(result.osConfidence, DeviceConfidence.highProbability);
  });

  test('weak single signals stay estimated or unknown, never high', () {
    // NetBIOS alone: Windows or Samba.
    final netbios = classify(device(netbiosName: 'NAS'));
    expect(netbios.type, DeviceType.windowsComputer);
    expect(netbios.typeConfidence, DeviceConfidence.estimated);

    // TTL 128 alone is too weak for an OS verdict.
    final ttl = classify(device(ttl: 128));
    expect(ttl.os, isNull);
    expect(ttl.type, DeviceType.unknown);
  });

  test('Google Cast service + 8008/8009: smart TV/media', () {
    final result = classify(
      device(
        mdns: [
          const MdnsServiceRecord(
            instanceName: 'Salon',
            serviceType: '_googlecast._tcp',
            txt: {'md': 'Chromecast'},
          ),
        ],
        ports: [8008, 8009],
      ),
    );
    expect(result.type, DeviceType.smartTvMedia);
    expect(result.typeConfidence, DeviceConfidence.highProbability);
    expect(result.reasons.first, contains('Chromecast'));
  });

  test('SSDP Internet Gateway Device: router', () {
    final result = classify(
      device(
        ssdp: [
          'Linux UPnP/1.0 · ST: urn:schemas-upnp-org:device:InternetGatewayDevice:1',
        ],
      ),
    );
    expect(result.type, DeviceType.routerGateway);
    expect(result.typeConfidence, DeviceConfidence.estimated);
  });

  test('randomized MAC: noted, no vendor, not enough alone', () {
    final alone = classify(device(mac: '5a:11:22:33:44:55'));
    expect(alone.type, DeviceType.unknown);
    expect(alone.reasons.last, contains('Özel/rastgele MAC'));

    final withHostname = classify(
      device(mac: '5a:11:22:33:44:55', hostname: 'galaxy-s23'),
    );
    expect(withHostname.type, DeviceType.phone);
    expect(withHostname.os, 'Android');
  });
}
