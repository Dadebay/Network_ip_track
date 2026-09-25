// NetBIOS node-status (NBSTAT) request/response encoding per RFC 1002
// §4.2.17–18. Pure and byte-fixture-testable.

import 'dart:typed_data';

/// A node-status request for the wildcard name `*`, which every NetBIOS
/// host answers with its registered name table.
Uint8List buildNodeStatusRequest(int transactionId) {
  final builder = BytesBuilder()
    // Header: transaction id, flags 0 (query), 1 question, 0 other records.
    ..add([(transactionId >> 8) & 0xFF, transactionId & 0xFF])
    ..add([0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])
    // Question name: first-level encoded "*" padded with NULs (16 bytes ->
    // 32 half-byte characters), length-prefixed, then the root label.
    ..addByte(0x20)
    ..add(_encodeName('*'))
    ..addByte(0x00)
    // QTYPE NBSTAT (0x21), QCLASS IN (0x01).
    ..add([0x00, 0x21, 0x00, 0x01]);
  return builder.toBytes();
}

List<int> _encodeName(String name) {
  final padded = name.padRight(16, '\x00').codeUnits.take(16);
  final encoded = <int>[];
  for (final byte in padded) {
    encoded
      ..add(0x41 + (byte >> 4))
      ..add(0x41 + (byte & 0x0F));
  }
  return encoded;
}

/// One entry of a node-status response's name table.
class NetbiosNameEntry {
  const NetbiosNameEntry({
    required this.name,
    required this.suffix,
    required this.isGroup,
  });

  final String name;

  /// 0x00 = workstation/computer name, 0x20 = file server, etc.
  final int suffix;
  final bool isGroup;
}

/// Parses a node-status response for [transactionId]. Returns null for
/// anything malformed or not an answer to our request.
List<NetbiosNameEntry>? parseNodeStatusResponse(
  Uint8List data,
  int transactionId,
) {
  if (data.length < 57) return null;
  final id = (data[0] << 8) | data[1];
  final isResponse = data[2] & 0x80 != 0;
  final answerCount = (data[6] << 8) | data[7];
  if (id != transactionId || !isResponse || answerCount < 1) return null;

  // Header (12) + RR name (1 + 32 + 1) + type/class (4) + TTL (4) +
  // RDLENGTH (2) = 56; the name count follows.
  var offset = 56;
  final nameCount = data[offset++];
  final entries = <NetbiosNameEntry>[];
  for (var i = 0; i < nameCount; i++) {
    if (offset + 18 > data.length) return null;
    final raw = String.fromCharCodes(data.sublist(offset, offset + 15));
    final suffix = data[offset + 15];
    final flags = (data[offset + 16] << 8) | data[offset + 17];
    offset += 18;
    entries.add(
      NetbiosNameEntry(
        name: raw.trimRight(),
        suffix: suffix,
        isGroup: flags & 0x8000 != 0,
      ),
    );
  }
  return entries;
}

/// The computer name from a name table: the unique name with suffix 0x00.
String? computerNameFrom(List<NetbiosNameEntry> entries) {
  for (final entry in entries) {
    if (!entry.isGroup && entry.suffix == 0x00 && entry.name.isNotEmpty) {
      return entry.name;
    }
  }
  return null;
}
