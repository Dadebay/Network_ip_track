import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../../../../core/utils/ipv4_address.dart';
import '../../domain/repositories/mdns_name_provider.dart';
import 'mdns_packets.dart';

const _mdnsPort = 5353;

/// [MdnsNameProvider] via one unicast reverse-PTR query to the host's UDP
/// 5353. No multicast, no retries.
class UdpMdnsNameProvider implements MdnsNameProvider {
  UdpMdnsNameProvider({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  Future<String?> lookupName(
    Ipv4Address address, {
    required Duration timeout,
  }) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final id = _random.nextInt(0x10000);
      final target = InternetAddress(address.toString());
      final completer = Completer<String?>();

      final subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket!.receive();
        if (datagram == null || datagram.address != target) return;
        final name = parseReversePtrResponse(datagram.data, id);
        if (name != null && !completer.isCompleted) completer.complete(name);
      });

      socket.send(buildReversePtrQuery(address, id), target, _mdnsPort);
      final name = await completer.future.timeout(
        timeout,
        onTimeout: () => null,
      );
      await subscription.cancel();
      return name;
    } on SocketException {
      return null;
    } finally {
      socket?.close();
    }
  }
}
