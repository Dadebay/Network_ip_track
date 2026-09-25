import 'dart:io';

import '../../../../core/utils/ipv4_address.dart';
import '../../domain/repositories/port_probe_provider.dart';

/// [PortProbeProvider] via a raw TCP connect attempt per port — the
/// lightest possible "is something listening here" check. Never sends
/// application data, never tries banners/credentials, and is only ever
/// called with the small configured limited-port list from [ScanSettings].
class SocketPortProbeProvider implements PortProbeProvider {
  const SocketPortProbeProvider();

  @override
  Future<List<int>> probeOpenPorts(
    Ipv4Address address,
    List<int> ports, {
    required Duration timeout,
  }) async {
    final host = address.toString();
    final results = await Future.wait(
      ports.map((port) => _probe(host, port, timeout)),
    );
    return [
      for (var i = 0; i < ports.length; i++)
        if (results[i]) ports[i],
    ];
  }

  Future<bool> _probe(String host, int port, Duration timeout) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      await socket.close();
      return true;
    } on Object {
      return false;
    }
  }
}
