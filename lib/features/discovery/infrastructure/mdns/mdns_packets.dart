import 'dart:typed_data';

import '../../../../core/utils/ipv4_address.dart';

const _typePtr = 12;
const _classIn = 1;

/// `d.c.b.a.in-addr.arpa` for [address].
String reverseName(Ipv4Address address) =>
    '${address.toString().split('.').reversed.join('.')}.in-addr.arpa';

/// A one-question DNS query for the PTR record of [address], as sent to the
/// host's own mDNS port. Sent from an ephemeral port, it's a "legacy
/// unicast" query (RFC 6762 §6.7): the responder answers directly to us,
/// echoing [id].
Uint8List buildReversePtrQuery(Ipv4Address address, int id) {
  final bytes = BytesBuilder()
    ..add([id >> 8, id & 0xff, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0]);
  for (final label in reverseName(address).split('.')) {
    bytes
      ..addByte(label.length)
      ..add(label.codeUnits);
  }
  bytes.add([0, 0, _typePtr, 0, _classIn]);
  return bytes.toBytes();
}

/// The hostname in the first PTR answer of a response to [id], without the
/// trailing dot; null for anything else.
String? parseReversePtrResponse(Uint8List data, int id) {
  try {
    if (data.length < 12) return null;
    final responseId = data[0] << 8 | data[1];
    final isResponse = data[2] & 0x80 != 0;
    if (!isResponse || responseId != id) return null;
    final questions = data[4] << 8 | data[5];
    final answers = data[6] << 8 | data[7];

    var offset = 12;
    for (var i = 0; i < questions; i++) {
      offset = _readName(data, offset).next + 4;
    }
    for (var i = 0; i < answers; i++) {
      offset = _readName(data, offset).next;
      final type = data[offset] << 8 | data[offset + 1];
      final length = data[offset + 8] << 8 | data[offset + 9];
      final rdata = offset + 10;
      if (type == _typePtr) {
        final name = _readName(data, rdata).name;
        return name.isEmpty ? null : name;
      }
      offset = rdata + length;
    }
  } on RangeError {
    return null;
  }
  return null;
}

/// Reads a (possibly compressed) domain name at [start]. `next` is the
/// offset right after the name as written at [start].
({String name, int next}) _readName(Uint8List data, int start) {
  final labels = <String>[];
  var offset = start;
  int? next;
  for (var jumps = 0; jumps < 32; jumps++) {
    final length = data[offset];
    if (length == 0) {
      next ??= offset + 1;
      return (name: labels.join('.'), next: next);
    }
    if (length & 0xc0 == 0xc0) {
      next ??= offset + 2;
      offset = (length & 0x3f) << 8 | data[offset + 1];
      continue;
    }
    labels.add(String.fromCharCodes(data, offset + 1, offset + 1 + length));
    offset += 1 + length;
  }
  throw RangeError('DNS name compression loop');
}
