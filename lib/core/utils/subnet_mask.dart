import 'ipv4_address.dart';

/// Converts a contiguous IPv4 subnet mask (e.g. 255.255.255.0) into its
/// CIDR prefix length (e.g. 24). Throws [FormatException] for non-contiguous
/// masks such as 255.0.255.0.
int subnetMaskToPrefixLength(Ipv4Address mask) {
  final bits = mask.value.toRadixString(2).padLeft(32, '0');
  if (!RegExp(r'^1*0*$').hasMatch(bits)) {
    throw FormatException('Geçersiz subnet mask (ardışık olmayan bit): $mask');
  }
  final firstZero = bits.indexOf('0');
  return firstZero == -1 ? 32 : firstZero;
}

/// Converts a CIDR prefix length (0-32) into its IPv4 subnet mask form.
Ipv4Address prefixLengthToSubnetMask(int prefixLength) {
  if (prefixLength < 0 || prefixLength > 32) {
    throw ArgumentError.value(
      prefixLength,
      'prefixLength',
      'must be between 0 and 32',
    );
  }
  if (prefixLength == 0) return const Ipv4Address(0);
  final value = (0xFFFFFFFF << (32 - prefixLength)) & 0xFFFFFFFF;
  return Ipv4Address(value);
}

/// Parses a hex netmask as emitted by macOS `ifconfig` (e.g. `0xffffff00`).
Ipv4Address parseHexNetmask(String hex) {
  var normalized = hex.trim();
  if (normalized.startsWith('0x') || normalized.startsWith('0X')) {
    normalized = normalized.substring(2);
  }
  final value = int.parse(normalized, radix: 16);
  return Ipv4Address(value);
}
