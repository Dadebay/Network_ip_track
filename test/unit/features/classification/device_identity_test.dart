import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/classification/application/device_identity.dart';
import 'package:network_monitor/features/discovery/domain/entities/discovered_device.dart';
import 'package:network_monitor/features/discovery/domain/entities/mdns_service_record.dart';
import 'package:network_monitor/features/discovery/domain/entities/upnp_device_info.dart';
import 'package:network_monitor/features/discovery/domain/repositories/http_banner_provider.dart';
import 'package:network_monitor/features/discovery/infrastructure/http/io_upnp_description_provider.dart';

DiscoveredDevice device({
  UpnpDeviceInfo? upnp,
  HttpBanner? banner,
  List<MdnsServiceRecord> mdns = const [],
  List<int> ports = const [],
}) => DiscoveredDevice(
  ipAddress: Ipv4Address.parse('172.16.14.21'),
  respondedAt: DateTime(2026, 9, 25),
  upnp: upnp,
  httpBanner: banner,
  mdnsRecords: mdns,
  openPorts: ports,
);

void main() {
  test('parses the first device of a UPnP description', () {
    const xml = '''
<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <device>
    <friendlyName>Salon &amp; Mutfak TV</friendlyName>
    <manufacturer>Samsung</manufacturer>
    <modelName>UE55</modelName>
    <modelNumber>TU8000</modelNumber>
    <deviceList><device><friendlyName>Inner</friendlyName></device></deviceList>
  </device>
</root>''';
    final info = parseUpnpDescription(xml)!;
    expect(info.friendlyName, 'Salon & Mutfak TV');
    expect(info.model, 'UE55 TU8000');
    expect(parseUpnpDescription('<root></root>'), isNull);
  });

  test('UPnP friendly name and model win; Windows suffix is trimmed', () {
    final identity = deriveDeviceIdentity(
      device(
        upnp: const UpnpDeviceInfo(
          friendlyName: 'SERVER-MANAGER: admin:',
          modelName: 'Windows Media Player Sharing',
        ),
      ),
    );
    expect(identity.name, 'SERVER-MANAGER');
    expect(identity.model, 'Windows Media Player Sharing');
  });

  test('mDNS names: Cast fn, RAOP after @, opaque ids skipped', () {
    expect(
      deriveDeviceIdentity(
        device(
          mdns: const [
            MdnsServiceRecord(
              instanceName: 'Chromecast-3f2a9c',
              serviceType: '_googlecast._tcp',
              txt: {'fn': 'Oturma Odası', 'md': 'Chromecast'},
            ),
          ],
        ),
      ).name,
      'Oturma Odası',
    );
    expect(
      deriveDeviceIdentity(
        device(
          mdns: const [
            MdnsServiceRecord(
              instanceName: 'A1B2C3D4E5F6@Mutfak',
              serviceType: '_raop._tcp',
            ),
          ],
        ),
      ).name,
      'Mutfak',
    );
    expect(
      deriveDeviceIdentity(
        device(
          mdns: const [
            MdnsServiceRecord(
              instanceName: '4d06090pag10d46',
              serviceType: '_device-info._tcp',
            ),
          ],
        ),
      ).name,
      isNull,
    );
  });

  test('web title is a model only when it is not generic', () {
    expect(
      deriveDeviceIdentity(
        device(banner: const HttpBanner(port: 80, title: 'TL-WR840N')),
      ).model,
      'TL-WR840N',
    );
    expect(
      deriveDeviceIdentity(
        device(banner: const HttpBanner(port: 80, title: 'Login')),
      ).model,
      isNull,
    );
  });

  test('web port: the answering banner, else the first open web port', () {
    expect(
      deriveDeviceIdentity(
        device(banner: const HttpBanner(port: 8080, title: 'x')),
      ).webPort,
      8080,
    );
    expect(deriveDeviceIdentity(device(ports: [22, 443])).webPort, 443);
    expect(deriveDeviceIdentity(device(ports: [22])).webPort, isNull);
  });
}
