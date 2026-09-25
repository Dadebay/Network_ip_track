import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../../../core/utils/ipv4_address.dart';
import '../../domain/entities/ws_discovery_match.dart';
import '../../domain/repositories/ws_discovery_provider.dart';

const _multicastAddress = '239.255.255.250';
const _port = 3702;

/// A WS-Discovery Probe. [types] narrows who answers; ONVIF cameras often
/// only answer a probe for `NetworkVideoTransmitter`.
String buildProbe(String messageId, {String? types}) =>
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" '
    'xmlns:wsa="http://schemas.xmlsoap.org/ws/2004/08/addressing" '
    'xmlns:wsd="http://schemas.xmlsoap.org/ws/2005/04/discovery" '
    'xmlns:dn="http://www.onvif.org/ver10/network/wsdl">'
    '<soap:Header>'
    '<wsa:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery</wsa:To>'
    '<wsa:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe'
    '</wsa:Action>'
    '<wsa:MessageID>urn:uuid:$messageId</wsa:MessageID>'
    '</soap:Header>'
    '<soap:Body><wsd:Probe>'
    '${types == null ? '' : '<wsd:Types>$types</wsd:Types>'}'
    '</wsd:Probe></soap:Body></soap:Envelope>';

/// Parses the `ProbeMatch` in a WS-Discovery response. Pure and
/// fixture-testable; namespace prefixes vary by vendor, so they're ignored.
WsDiscoveryMatch? parseProbeMatch(String xml) {
  if (!RegExp(r'ProbeMatch', caseSensitive: false).hasMatch(xml)) return null;
  List<String> list(String element) {
    final text = RegExp(
      '<(?:[\\w-]+:)?$element(?:\\s[^>]*)?>([^<]*)</(?:[\\w-]+:)?$element>',
    ).firstMatch(xml)?.group(1);
    if (text == null) return const [];
    return text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  }

  final match = WsDiscoveryMatch(types: list('Types'), scopes: list('Scopes'));
  return match.types.isEmpty && match.scopes.isEmpty ? null : match;
}

/// [WsDiscoveryProvider] over a raw UDP socket: two probes (everyone, and
/// ONVIF video devices), then collects the unicast ProbeMatches.
class UdpWsDiscoveryProvider implements WsDiscoveryProvider {
  UdpWsDiscoveryProvider({Random? random}) : _random = random ?? Random();

  final Random _random;

  String _uuid() {
    String hex(int length) => [
      for (var i = 0; i < length; i++) _random.nextInt(16).toRadixString(16),
    ].join();
    return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
  }

  @override
  Future<Map<Ipv4Address, List<WsDiscoveryMatch>>> probe({
    required Duration timeout,
  }) async {
    final result = <Ipv4Address, List<WsDiscoveryMatch>>{};
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket!.receive();
        if (datagram == null) return;
        final address = Ipv4Address.tryParse(datagram.address.address);
        if (address == null) return;
        final match = parseProbeMatch(
          utf8.decode(datagram.data, allowMalformed: true),
        );
        if (match != null) (result[address] ??= []).add(match);
      });

      final target = InternetAddress(_multicastAddress);
      for (final types in [null, 'dn:NetworkVideoTransmitter']) {
        socket.send(
          utf8.encode(buildProbe(_uuid(), types: types)),
          target,
          _port,
        );
      }
      await Future<void>.delayed(timeout);
      await subscription.cancel();
    } on SocketException {
      // No multicast route: nothing found, not a scan failure.
    } finally {
      socket?.close();
    }
    return result;
  }
}
