import 'package:flutter/services.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/utils/ipv4_address.dart';
import '../../domain/entities/ping_reply.dart';
import '../../domain/repositories/ping_provider.dart';

/// [PingProvider] over the Runner's `network_monitor/icmp` channel: one ICMP
/// echo sent from inside the app process (see `IcmpChannel` in
/// `MainFlutterWindow.swift`). Spawning `/sbin/ping` from the sandboxed app
/// fails with "No route to host" because the child process doesn't get the
/// app's local-network access; this doesn't have that problem.
class NativeIcmpPingProvider implements PingProvider {
  const NativeIcmpPingProvider({
    MethodChannel channel = const MethodChannel('network_monitor/icmp'),
  }) : _channel = channel;

  final MethodChannel _channel;

  /// errno values meaning the OS refused the probe outright.
  static const _permissionErrors = {1 /* EPERM */, 13 /* EACCES */};

  @override
  Future<PingReply?> ping(
    Ipv4Address address, {
    required Duration timeout,
  }) async {
    final Map<Object?, Object?>? reply;
    try {
      reply = await _channel.invokeMapMethod<Object?, Object?>('ping', {
        'ip': address.toString(),
        'timeoutMs': timeout.inMilliseconds,
      });
    } on MissingPluginException {
      throw NetworkProbePermissionFailure(
        technicalDetail: 'ICMP kanalı yok (network_monitor/icmp).',
      );
    }
    if (reply == null || reply.isEmpty) return null;
    final errno = reply['errno'];
    if (errno is int) {
      if (_permissionErrors.contains(errno)) {
        throw NetworkProbePermissionFailure(
          technicalDetail: 'ICMP soketi reddedildi (errno $errno).',
        );
      }
      // EHOSTUNREACH, ENETUNREACH…: no reply from this address.
      return null;
    }
    final rtt = reply['rttMicros'];
    return PingReply(
      ttl: reply['ttl'] as int?,
      roundTrip: rtt is int ? Duration(microseconds: rtt) : null,
    );
  }
}
