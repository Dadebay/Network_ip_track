import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/discovery/infrastructure/netbios/netbios_packets.dart';

/// A node-status response carrying [names] as (name, suffix, isGroup).
Uint8List response(int id, List<(String, int, bool)> names) {
  final b = BytesBuilder()
    ..add([id >> 8, id & 0xFF, 0x84, 0x00, 0, 0, 0, 1, 0, 0, 0, 0])
    ..addByte(0x20)
    ..add(List.filled(32, 0x41))
    ..addByte(0)
    ..add([0x00, 0x21, 0x00, 0x01, 0, 0, 0, 0])
    ..add([0, 1 + names.length * 18])
    ..addByte(names.length);
  for (final (name, suffix, isGroup) in names) {
    b
      ..add(name.padRight(15).codeUnits)
      ..addByte(suffix)
      ..add([isGroup ? 0x84 : 0x04, 0x00]);
  }
  b.add(List.filled(46, 0)); // statistics block
  return b.toBytes();
}

void main() {
  test('request encodes the wildcard name for an NBSTAT query', () {
    final request = buildNodeStatusRequest(0x1234);
    expect(request.length, 50);
    expect(request.sublist(0, 2), [0x12, 0x34]);
    expect(request[12], 0x20);
    // '*' = 0x2A -> 'C' 'K'; NUL padding -> 'A' 'A'.
    expect(String.fromCharCodes(request.sublist(13, 17)), 'CKAA');
    expect(request.sublist(46), [0x00, 0x21, 0x00, 0x01]);
  });

  test('response yields the unique workstation (0x00) name', () {
    final entries = parseNodeStatusResponse(
      response(0x1234, [
        ('WORKGROUP', 0x00, true),
        ('OFFICE-PC', 0x00, false),
        ('OFFICE-PC', 0x20, false),
      ]),
      0x1234,
    );
    expect(entries, hasLength(3));
    expect(computerNameFrom(entries!), 'OFFICE-PC');
  });

  test('ignores answers to another transaction and truncated packets', () {
    expect(
      parseNodeStatusResponse(response(0x9999, [('X', 0, false)]), 0x1234),
      isNull,
    );
    expect(parseNodeStatusResponse(Uint8List(20), 0x1234), isNull);
  });
}
