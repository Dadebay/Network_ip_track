import 'dart:convert';
import 'dart:io';

import '../../../../core/utils/ipv4_address.dart';
import '../../domain/repositories/ssdp_provider.dart';
import 'ssdp_response_parser.dart';

const _ssdpMulticastAddress = '239.255.255.250';
const _ssdpPort = 1900;

/// [SsdpProvider] via a raw UDP `M-SEARCH` multicast, per RFC — no shelling
/// out, this is a direct implementation of the (simple, text-based) SSDP
/// discovery request/response protocol.
class UdpSsdpProvider implements SsdpProvider {
  const UdpSsdpProvider();

  @override
  Future<Map<Ipv4Address, List<String>>> search({
    required Duration timeout,
  }) async {
    final result = <Ipv4Address, List<String>>{};
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;

      final request = utf8.encode(
        'M-SEARCH * HTTP/1.1\r\n'
        'HOST: $_ssdpMulticastAddress:$_ssdpPort\r\n'
        'MAN: "ssdp:discover"\r\n'
        'MX: 2\r\n'
        'ST: ssdp:all\r\n\r\n',
      );
      socket.send(request, InternetAddress(_ssdpMulticastAddress), _ssdpPort);

      final subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket!.receive();
        if (datagram == null) return;

        final address = Ipv4Address.tryParse(datagram.address.address);
        if (address == null) return;

        final response = parseSsdpResponse(
          utf8.decode(datagram.data, allowMalformed: true),
        );
        if (response.isEmpty) return;

        (result[address] ??= []).add(response.describe());
      });

      await Future<void>.delayed(timeout);
      await subscription.cancel();
    } finally {
      socket?.close();
    }
    return result;
  }
}
