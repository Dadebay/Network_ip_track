import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/discovery/infrastructure/macos/ssdp_response_parser.dart';

void main() {
  test('extracts SERVER, ST and LOCATION headers', () {
    const raw =
        'HTTP/1.1 200 OK\r\n'
        'CACHE-CONTROL: max-age=1800\r\n'
        'LOCATION: http://172.16.14.30:8080/description.xml\r\n'
        'SERVER: Linux/3.10 UPnP/1.0 MyDevice/1.0\r\n'
        'ST: upnp:rootdevice\r\n'
        'USN: uuid:abc\r\n\r\n';

    final response = parseSsdpResponse(raw);

    expect(response.server, 'Linux/3.10 UPnP/1.0 MyDevice/1.0');
    expect(response.st, 'upnp:rootdevice');
    expect(response.location, 'http://172.16.14.30:8080/description.xml');
    expect(
      response.describe(),
      'Linux/3.10 UPnP/1.0 MyDevice/1.0 · ST: upnp:rootdevice',
    );
  });

  test('is empty for a response with no recognized headers', () {
    final response = parseSsdpResponse('HTTP/1.1 200 OK\r\n\r\n');
    expect(response.isEmpty, isTrue);
    expect(response.describe(), 'SSDP yanıtı');
  });
}
