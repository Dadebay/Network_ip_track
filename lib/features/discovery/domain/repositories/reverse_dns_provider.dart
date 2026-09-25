import '../../../../core/utils/ipv4_address.dart';

/// Platform adapter for a PTR (reverse DNS) lookup.
abstract interface class ReverseDnsProvider {
  Future<String?> lookup(Ipv4Address address, {required Duration timeout});
}
