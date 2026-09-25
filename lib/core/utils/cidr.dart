import 'ipv4_address.dart';
import 'subnet_mask.dart';

/// An IPv4 CIDR block, normalized so [networkAddress] always has its host
/// bits cleared (e.g. `172.16.14.5/24` normalizes to `172.16.14.0/24`).
class Cidr {
  Cidr._(this.networkAddress, this.prefixLength);

  factory Cidr.fromAddressAndPrefix(Ipv4Address address, int prefixLength) {
    if (prefixLength < 0 || prefixLength > 32) {
      throw ArgumentError.value(
        prefixLength,
        'prefixLength',
        'must be between 0 and 32',
      );
    }
    final mask = prefixLengthToSubnetMask(prefixLength);
    return Cidr._(address & mask, prefixLength);
  }

  factory Cidr.fromAddressAndMask(Ipv4Address address, Ipv4Address mask) {
    final prefixLength = subnetMaskToPrefixLength(mask);
    return Cidr._(address & mask, prefixLength);
  }

  factory Cidr.parse(String input) {
    final parts = input.trim().split('/');
    if (parts.length != 2) {
      throw FormatException('Geçersiz CIDR biçimi: $input');
    }
    final address = Ipv4Address.parse(parts[0]);
    final prefixLength = int.tryParse(parts[1]);
    if (prefixLength == null) {
      throw FormatException('Geçersiz CIDR prefix uzunluğu: $input');
    }
    return Cidr.fromAddressAndPrefix(address, prefixLength);
  }

  final Ipv4Address networkAddress;
  final int prefixLength;

  Ipv4Address get subnetMask => prefixLengthToSubnetMask(prefixLength);

  Ipv4Address get broadcastAddress {
    final hostMask = 0xFFFFFFFF & ~subnetMask.value;
    return Ipv4Address(networkAddress.value | hostMask);
  }

  /// Total number of addresses in the block, including network/broadcast.
  BigInt get totalAddressCount => BigInt.two.pow(32 - prefixLength);

  /// First usable host, or null for /31 and /32 blocks that have no
  /// meaningful host range.
  Ipv4Address? get firstHost {
    if (prefixLength >= 31) return null;
    return Ipv4Address(networkAddress.value + 1);
  }

  /// Last usable host, or null for /31 and /32 blocks.
  Ipv4Address? get lastHost {
    if (prefixLength >= 31) return null;
    return Ipv4Address(broadcastAddress.value - 1);
  }

  bool contains(Ipv4Address address) {
    return (address.value & subnetMask.value) == networkAddress.value;
  }

  /// True if [other] is fully contained within this block (equal or more
  /// specific prefix).
  bool containsCidr(Cidr other) {
    return other.prefixLength >= prefixLength && contains(other.networkAddress);
  }

  bool overlaps(Cidr other) {
    return contains(other.networkAddress) || other.contains(networkAddress);
  }

  @override
  bool operator ==(Object other) =>
      other is Cidr &&
      other.networkAddress == networkAddress &&
      other.prefixLength == prefixLength;

  @override
  int get hashCode => Object.hash(networkAddress, prefixLength);

  @override
  String toString() => '$networkAddress/$prefixLength';
}
