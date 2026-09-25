import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/discovery/infrastructure/macos/macos_dns_sd_parser.dart';

void main() {
  group('parseDnsSdBrowseOutput', () {
    test('extracts service type and instance name from Add rows', () {
      const raw = '''
Browsing for _http._tcp.local
DATE: ---Tue 24 Sep 2026---
20:15:32.123  ...STARTING...
Timestamp     A/R    Flags  if Domain               Service Type         Instance Name
20:15:32.456  Add        3   4 local.               _http._tcp.          Living Room Apple TV
20:15:33.001  Add        2   4 local.               _http._tcp.          Printer HP OfficeJet
''';
      final results = parseDnsSdBrowseOutput(raw);
      expect(results, hasLength(2));
      expect(results[0].instanceName, 'Living Room Apple TV');
      expect(results[0].serviceType, '_http._tcp.');
      expect(results[1].instanceName, 'Printer HP OfficeJet');
    });

    test('ignores header/status lines', () {
      const raw =
          'Browsing for _http._tcp.local\nDATE: ---Tue 24 Sep 2026---\n';
      expect(parseDnsSdBrowseOutput(raw), isEmpty);
    });
  });

  group('parseDnsSdLookupHostname', () {
    test('extracts the hostname before the port', () {
      const raw = '''
Lookup Living\\032Room\\032Apple\\032TV._http._tcp.local
20:16:01.234  Living Room Apple TV._http._tcp.local. can be reached at LivingRoomAppleTV.local.:80 (interface 4)
''';
      expect(parseDnsSdLookupHostname(raw), 'LivingRoomAppleTV.local.');
    });

    test('returns null when nothing resolved', () {
      expect(parseDnsSdLookupHostname('Lookup ...\n'), isNull);
    });
  });

  group('parseDnsSdResolveAddress', () {
    test('extracts the resolved IPv4 address', () {
      const raw = '''
DATE: ---Tue 24 Sep 2026---
20:16:05.001  ...STARTING...
Timestamp     A/R    Flags if Hostname                               Address                                      TTL
20:16:05.234  Add     2    4 LivingRoomAppleTV.local.                172.16.14.50                                 120
''';
      expect(parseDnsSdResolveAddress(raw)?.toString(), '172.16.14.50');
    });

    test('returns null when nothing resolved yet', () {
      expect(parseDnsSdResolveAddress('DATE: ---Tue 24 Sep 2026---\n'), isNull);
    });
  });

  group('parseDnsSdLookupTxt', () {
    test('parses TXT key/values with escaped spaces', () {
      const raw = '''
Lookup Office._device-info._tcp.local
20:16:01.234  Office._device-info._tcp.local. can be reached at Office.local.:0 (interface 4)
 model=MacBookPro18,3 osxvers=24 ty=HP\\ LaserJet\\ Pro
''';
      expect(parseDnsSdLookupTxt(raw), {
        'model': 'MacBookPro18,3',
        'osxvers': '24',
        'ty': 'HP LaserJet Pro',
      });
    });

    test('empty when nothing resolved', () {
      expect(parseDnsSdLookupTxt('Lookup x\n'), isEmpty);
    });
  });
}
