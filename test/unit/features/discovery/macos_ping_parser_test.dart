import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/discovery/infrastructure/macos/macos_ping_parser.dart';

void main() {
  test('parses TTL and round-trip time from an echo reply', () {
    final raw = File('test/fixtures/ping/ping_reply.txt').readAsStringSync();
    final reply = parsePingReply(raw);

    expect(reply, isNotNull);
    expect(reply!.ttl, 255);
    expect(reply.roundTrip, const Duration(microseconds: 2418));
    expect(reply.ttlSignal, contains('ağ cihazı-benzeri'));
  });

  test('returns null when no reply was received', () {
    final raw = File('test/fixtures/ping/ping_timeout.txt').readAsStringSync();
    expect(parsePingReply(raw), isNull);
  });
}
