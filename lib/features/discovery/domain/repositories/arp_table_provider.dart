import '../../../../core/utils/ipv4_address.dart';
import '../entities/arp_entry.dart';

/// Platform adapter for reading the OS ARP/neighbor table.
abstract interface class ArpTableProvider {
  Future<List<ArpEntry>> getArpTable();

  /// Looks up a single address. Called right after probing a host on the
  /// local segment: the probe itself makes the kernel resolve the address,
  /// so a hit here proves the host answered ARP even if it drops ICMP.
  Future<ArpEntry?> lookup(Ipv4Address address);
}
