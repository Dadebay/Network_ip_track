import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/discovery/infrastructure/mdns/mdns_packets.dart';
import 'package:network_monitor/features/discovery/infrastructure/wsd/udp_ws_discovery_provider.dart';

/// A response echoing [query]'s question plus one PTR answer whose name is
/// a compression pointer to the question and whose rdata is [hostname].
Uint8List ptrResponse(Uint8List query, String hostname) {
  final answer = BytesBuilder()..add([0xc0, 12, 0, 12, 0x80, 1, 0, 0, 0, 120]);
  final rdata = BytesBuilder();
  for (final label in hostname.split('.')) {
    rdata
      ..addByte(label.length)
      ..add(label.codeUnits);
  }
  rdata.addByte(0);
  final rdataBytes = rdata.toBytes();
  answer
    ..add([rdataBytes.length >> 8, rdataBytes.length & 0xff])
    ..add(rdataBytes);
  final header = Uint8List.fromList(query.sublist(0, 12));
  header[2] = 0x84;
  header[7] = 1;
  return (BytesBuilder()
        ..add(header)
        ..add(query.sublist(12))
        ..add(answer.toBytes()))
      .toBytes();
}

void main() {
  test('reverse PTR query names the in-addr.arpa of the address', () {
    final address = Ipv4Address.parse('172.16.14.55');
    expect(reverseName(address), '55.14.16.172.in-addr.arpa');
    final query = buildReversePtrQuery(address, 0x1234);
    expect(query.sublist(0, 2), [0x12, 0x34]);
    expect(query[5], 1);
  });

  test('parses the hostname from a PTR answer, only for our id', () {
    final query = buildReversePtrQuery(Ipv4Address.parse('172.16.14.55'), 7);
    final response = ptrResponse(query, 'Atakovs-iPad-2.local');
    expect(parseReversePtrResponse(response, 7), 'Atakovs-iPad-2.local');
    expect(parseReversePtrResponse(response, 8), isNull);
    expect(parseReversePtrResponse(query, 7), isNull);
    expect(parseReversePtrResponse(Uint8List(3), 7), isNull);
  });

  test('parses an ONVIF ProbeMatch with vendor namespace prefixes', () {
    const xml = '''
<SOAP-ENV:Envelope><SOAP-ENV:Body><d:ProbeMatches><d:ProbeMatch>
<d:Types>dn:NetworkVideoTransmitter tds:Device</d:Types>
<d:Scopes>onvif://www.onvif.org/type/video_encoder onvif://www.onvif.org/hardware/DS-2CD2143G0-I onvif://www.onvif.org/name/Giris%20Kamerasi</d:Scopes>
</d:ProbeMatch></d:ProbeMatches></SOAP-ENV:Body></SOAP-ENV:Envelope>''';
    final match = parseProbeMatch(xml)!;
    expect(match.types, contains('dn:NetworkVideoTransmitter'));
    expect(match.onvifScope('hardware'), 'DS-2CD2143G0-I');
    expect(match.onvifScope('name'), 'Giris Kamerasi');
    expect(parseProbeMatch('<Probe/>'), isNull);
  });

  test('the probe carries its message id and optional type filter', () {
    final probe = buildProbe('abc', types: 'dn:NetworkVideoTransmitter');
    expect(probe, contains('urn:uuid:abc'));
    expect(
      probe,
      contains('<wsd:Types>dn:NetworkVideoTransmitter</wsd:Types>'),
    );
    expect(buildProbe('abc'), isNot(contains('<wsd:Types>')));
  });
}
