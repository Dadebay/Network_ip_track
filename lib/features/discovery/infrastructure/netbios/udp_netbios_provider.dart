import 'dart:async';
import 'dart:io';
import 'dart:math';

import '../../../../core/utils/ipv4_address.dart';
import '../../domain/repositories/netbios_provider.dart';
import 'netbios_packets.dart';

const _netbiosNamePort = 137;

/// [NetbiosProvider] via one NBSTAT datagram to UDP 137 — no retries, no
/// broadcast, nothing but the name-table query.
class UdpNetbiosProvider implements NetbiosProvider {
  UdpNetbiosProvider({Random? random}) : _random = random ?? Random();

  final Random _random;

  @override
  Future<String?> lookupName(
    Ipv4Address address, {
    required Duration timeout,
  }) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      final transactionId = _random.nextInt(0x10000);
      final target = InternetAddress(address.toString());
      final completer = Completer<String?>();

      final subscription = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket!.receive();
        if (datagram == null || datagram.address != target) return;
        final entries = parseNodeStatusResponse(datagram.data, transactionId);
        if (entries != null && !completer.isCompleted) {
          completer.complete(computerNameFrom(entries));
        }
      });

      socket.send(
        buildNodeStatusRequest(transactionId),
        target,
        _netbiosNamePort,
      );
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
