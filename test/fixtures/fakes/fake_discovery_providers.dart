import 'dart:async';

import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/classification/domain/repositories/oui_lookup.dart';
import 'package:network_monitor/features/discovery/domain/entities/arp_entry.dart';
import 'package:network_monitor/features/discovery/domain/entities/mdns_service_record.dart';
import 'package:network_monitor/features/discovery/domain/entities/ping_reply.dart';
import 'package:network_monitor/features/discovery/domain/entities/ssdp_response.dart';
import 'package:network_monitor/features/discovery/domain/entities/upnp_device_info.dart';
import 'package:network_monitor/features/discovery/domain/repositories/arp_table_provider.dart';
import 'package:network_monitor/features/discovery/domain/repositories/mdns_provider.dart';
import 'package:network_monitor/features/discovery/domain/repositories/netbios_provider.dart';
import 'package:network_monitor/features/discovery/domain/repositories/ping_provider.dart';
import 'package:network_monitor/features/discovery/domain/repositories/port_probe_provider.dart';
import 'package:network_monitor/features/discovery/domain/repositories/reverse_dns_provider.dart';
import 'package:network_monitor/features/discovery/domain/repositories/ssdp_provider.dart';
import 'package:network_monitor/features/discovery/domain/repositories/upnp_description_provider.dart';

/// In-memory stand-ins for every discovery adapter, so engine/coordinator
/// tests never touch the real network.
class FakeArpTableProvider implements ArpTableProvider {
  FakeArpTableProvider({this.table = const [], this.lookupResults = const {}});

  final List<ArpEntry> table;
  final Map<Ipv4Address, String> lookupResults;

  @override
  Future<List<ArpEntry>> getArpTable() async => table;

  @override
  Future<ArpEntry?> lookup(Ipv4Address address) async {
    final mac = lookupResults[address];
    return mac == null ? null : ArpEntry(ipAddress: address, macAddress: mac);
  }
}

class FakePingProvider implements PingProvider {
  FakePingProvider({this.alive = const {}, this.delay = Duration.zero});

  final Set<Ipv4Address> alive;
  final Duration delay;
  final List<Ipv4Address> pinged = [];
  int inFlight = 0;
  int maxInFlight = 0;

  /// Called after each ping is recorded — lets a test pause/cancel mid-scan.
  void Function(Ipv4Address address)? onPing;

  @override
  Future<PingReply?> ping(
    Ipv4Address address, {
    required Duration timeout,
  }) async {
    pinged.add(address);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    onPing?.call(address);
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    } else {
      await Future<void>.value();
    }
    inFlight--;
    return alive.contains(address) ? const PingReply(ttl: 64) : null;
  }
}

class FakeReverseDnsProvider implements ReverseDnsProvider {
  FakeReverseDnsProvider([this.names = const {}]);
  final Map<Ipv4Address, String> names;

  @override
  Future<String?> lookup(
    Ipv4Address address, {
    required Duration timeout,
  }) async => names[address];
}

class FakeMdnsProvider implements MdnsProvider {
  FakeMdnsProvider([this.services = const {}]);
  final Map<Ipv4Address, List<MdnsServiceRecord>> services;

  @override
  Future<Map<Ipv4Address, List<MdnsServiceRecord>>> browse({
    required Duration timeout,
  }) async => services;
}

class FakeNetbiosProvider implements NetbiosProvider {
  FakeNetbiosProvider([this.names = const {}]);
  final Map<Ipv4Address, String> names;
  final List<Ipv4Address> queried = [];

  @override
  Future<String?> lookupName(
    Ipv4Address address, {
    required Duration timeout,
  }) async {
    queried.add(address);
    return names[address];
  }
}

class FakeOuiLookup implements OuiLookup {
  const FakeOuiLookup([this.vendors = const {}]);

  /// Keyed by normalized MAC prefix, e.g. `a4:83:e7`.
  final Map<String, String> vendors;

  @override
  bool get isAvailable => vendors.isNotEmpty;

  @override
  String? vendorFor(String normalizedMac) =>
      vendors[normalizedMac.substring(0, 8)];
}

class FakeSsdpProvider implements SsdpProvider {
  FakeSsdpProvider([this.services = const {}]);
  final Map<Ipv4Address, List<SsdpResponse>> services;

  @override
  Future<Map<Ipv4Address, List<SsdpResponse>>> search({
    required Duration timeout,
  }) async => services;
}

class FakePortProbeProvider implements PortProbeProvider {
  FakePortProbeProvider([this.open = const {}]);
  final Map<Ipv4Address, List<int>> open;

  @override
  Future<List<int>> probeOpenPorts(
    Ipv4Address address,
    List<int> ports, {
    required Duration timeout,
  }) async => [
    for (final port in open[address] ?? const <int>[])
      if (ports.contains(port)) port,
  ];
}

class FakeUpnpDescriptionProvider implements UpnpDescriptionProvider {
  FakeUpnpDescriptionProvider([this.byLocation = const {}]);
  final Map<String, UpnpDeviceInfo> byLocation;

  @override
  Future<UpnpDeviceInfo?> fetch(
    Ipv4Address address,
    String location, {
    required Duration timeout,
  }) async => byLocation[location];
}
