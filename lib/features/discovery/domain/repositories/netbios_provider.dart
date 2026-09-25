import '../../../../core/utils/ipv4_address.dart';

/// Platform adapter for a NetBIOS node-status (NBSTAT) name query to one
/// host on UDP 137 — a single request, used only when no other name was
/// found for a live host.
abstract interface class NetbiosProvider {
  /// The host's NetBIOS computer name, or null if it didn't answer.
  Future<String?> lookupName(Ipv4Address address, {required Duration timeout});
}
