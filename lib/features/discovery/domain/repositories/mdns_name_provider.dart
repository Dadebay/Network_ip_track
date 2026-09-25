import '../../../../core/utils/ipv4_address.dart';

/// Asks a host itself, over mDNS, for its `.local` name — Apple devices and
/// most Linux hosts answer, even when the network's DNS knows nothing.
abstract interface class MdnsNameProvider {
  Future<String?> lookupName(Ipv4Address address, {required Duration timeout});
}
