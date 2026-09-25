/// Normalizes a MAC address to lowercase, colon-separated, zero-padded form
/// (`aa:bb:cc:dd:ee:ff`). macOS tools like `arp -a` print each octet without
/// leading zeros (`0:1a:2b:3c:4d:5e`), so this is needed before using a MAC
/// as a dedup key or an OUI lookup input. Returns null for anything that
/// isn't 6 colon- or hyphen-separated hex octets.
String? normalizeMacAddress(String raw) {
  final separator = raw.contains('-') ? '-' : ':';
  final parts = raw.trim().split(separator);
  if (parts.length != 6) return null;

  final octets = <String>[];
  for (final part in parts) {
    if (part.length > 2) return null;
    final value = int.tryParse(part, radix: 16);
    if (value == null || value < 0 || value > 0xFF) return null;
    octets.add(value.toRadixString(16).padLeft(2, '0'));
  }
  return octets.join(':').toLowerCase();
}

/// The OUI (first 3 octets) of a normalized MAC address, e.g.
/// `ac:de:48:00:11:22` -> `ac:de:48`.
String ouiOf(String normalizedMacAddress) =>
    normalizedMacAddress.split(':').take(3).join(':');

/// True for a locally administered address (bit 1 of the first octet) —
/// e.g. the private/randomized Wi-Fi addresses modern phones use. Such a
/// MAC has no registered vendor (spec limitation #7).
bool isLocallyAdministeredMac(String normalizedMacAddress) {
  final firstOctet = int.tryParse(
    normalizedMacAddress.substring(0, 2),
    radix: 16,
  );
  return firstOctet != null && firstOctet & 0x02 != 0;
}
