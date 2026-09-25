import 'cidr.dart';

/// RFC1918 private block `172.16.0.0/12` (172.16.0.0 - 172.31.255.255).
///
/// This is intentionally narrower than the full `172.0.0.0/8` class-A style
/// block: `172.0.0.0-172.15.255.255` and `172.32.0.0-172.255.255.255` may be
/// public address space and must never be scanned automatically.
final Cidr private172Block = Cidr.parse('172.16.0.0/12');

/// True if [cidr] is fully contained within the private `172.16.0.0/12`
/// block. Used to gate every automatic-scope feature so the app never
/// reaches into the wider (potentially public) `172.0.0.0/8` range.
bool isWithinPrivate172Block(Cidr cidr) => private172Block.containsCidr(cidr);
