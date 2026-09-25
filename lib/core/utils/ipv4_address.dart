/// Immutable representation of an IPv4 address stored as a 32-bit unsigned
/// value. Dart's `int` is 64-bit, so no overflow handling is needed for the
/// bit operations used here.
class Ipv4Address implements Comparable<Ipv4Address> {
  const Ipv4Address(this.value)
    : assert(value >= 0 && value <= 0xFFFFFFFF, 'value must fit in 32 bits');

  factory Ipv4Address.parse(String input) {
    final address = Ipv4Address.tryParse(input);
    if (address == null) {
      throw FormatException('Geçersiz IPv4 adresi: $input');
    }
    return address;
  }

  static Ipv4Address? tryParse(String input) {
    final octetStrings = input.trim().split('.');
    if (octetStrings.length != 4) return null;
    var value = 0;
    for (final octetString in octetStrings) {
      final octet = int.tryParse(octetString);
      if (octet == null || octet < 0 || octet > 255) return null;
      value = (value << 8) | octet;
    }
    return Ipv4Address(value);
  }

  /// The address as a 32-bit unsigned integer (network byte order semantics).
  final int value;

  List<int> get octets => <int>[
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];

  Ipv4Address operator &(Ipv4Address other) => Ipv4Address(value & other.value);

  Ipv4Address operator |(Ipv4Address other) => Ipv4Address(value | other.value);

  @override
  int compareTo(Ipv4Address other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      other is Ipv4Address && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => octets.join('.');
}
