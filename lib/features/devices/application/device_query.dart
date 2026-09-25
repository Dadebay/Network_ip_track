import '../../../core/utils/cidr.dart';
import '../domain/entities/device.dart';
import '../domain/entities/device_status.dart';
import '../domain/entities/device_type.dart';

/// Sort keys for the tree/list.
enum DeviceSortField {
  ip('IP'),
  name('Ad'),
  lastSeen('Son görülme'),
  dailyTraffic('Günlük trafik');

  const DeviceSortField(this.label);
  final String label;
}

/// Search, filter and sort state shared by the tree and list views.
class DeviceQuery {
  const DeviceQuery({
    this.search = '',
    this.statuses = const {},
    this.types = const {},
    this.osNames = const {},
    this.vendors = const {},
    this.subnet,
    this.onlyPingConfirmed = false,
    this.sortField = DeviceSortField.ip,
    this.ascending = true,
  });

  final String search;

  /// Empty means "all".
  final Set<DeviceStatus> statuses;

  /// Matches the effective (user's, else inferred) type.
  final Set<DeviceType> types;

  /// Inferred OS names; [unknownValue] matches devices without one.
  final Set<String> osNames;

  /// Vendor names; [unknownValue] matches devices without one.
  final Set<String> vendors;
  final Cidr? subnet;

  /// Hide every device that has never answered an ICMP ping — a much
  /// harder signal to fake than a TCP port "open", which some networks'
  /// middleboxes will report for literally any address (see
  /// `Devices.pingConfirmed`). Off by default: a device that only answers
  /// ARP/mDNS/SSDP/a port is still real evidence on most networks and the
  /// app never hides it silently — this is an explicit, visible opt-in for
  /// networks where port-probe liveness turns out to be unreliable.
  final bool onlyPingConfirmed;

  /// Filter value standing for "no OS/vendor known".
  static const unknownValue = 'Bilinmiyor';
  final DeviceSortField sortField;
  final bool ascending;

  bool get hasFilters =>
      search.trim().isNotEmpty ||
      statuses.isNotEmpty ||
      types.isNotEmpty ||
      osNames.isNotEmpty ||
      vendors.isNotEmpty ||
      subnet != null ||
      onlyPingConfirmed;

  DeviceQuery copyWith({
    String? search,
    Set<DeviceStatus>? statuses,
    Set<DeviceType>? types,
    Set<String>? osNames,
    Set<String>? vendors,
    Cidr? Function()? subnet,
    bool? onlyPingConfirmed,
    DeviceSortField? sortField,
    bool? ascending,
  }) {
    return DeviceQuery(
      search: search ?? this.search,
      statuses: statuses ?? this.statuses,
      types: types ?? this.types,
      osNames: osNames ?? this.osNames,
      vendors: vendors ?? this.vendors,
      subnet: subnet != null ? subnet() : this.subnet,
      onlyPingConfirmed: onlyPingConfirmed ?? this.onlyPingConfirmed,
      sortField: sortField ?? this.sortField,
      ascending: ascending ?? this.ascending,
    );
  }
}

/// Applies [query] to [devices]. Search matches IP, MAC (with or without
/// separators), hostname, announced name, model, vendor and the user's
/// custom name.
///
/// [dailyTrafficBytes] (today's total per device id) drives the daily
/// traffic sort. Devices without traffic data always sort last, in either
/// direction — unknown usage is not the same as zero.
List<Device> applyDeviceQuery(
  List<Device> devices,
  DeviceQuery query, {
  Map<int, int> dailyTrafficBytes = const {},
}) {
  final needle = query.search.trim().toLowerCase();
  final compactNeedle = needle.replaceAll(RegExp('[:-]'), '');

  bool matchesSearch(Device device) {
    if (needle.isEmpty) return true;
    final mac = device.macAddress;
    final fields = [
      device.currentIp.toString(),
      ?mac,
      ?device.hostname,
      ?device.discoveredName,
      ?device.model,
      ?device.vendor,
      ?device.customName,
    ];
    if (fields.any((field) => field.toLowerCase().contains(needle))) {
      return true;
    }
    return mac != null &&
        compactNeedle.length >= 4 &&
        mac.replaceAll(':', '').contains(compactNeedle);
  }

  final filtered = devices.where((device) {
    if (query.statuses.isNotEmpty && !query.statuses.contains(device.status)) {
      return false;
    }
    if (query.types.isNotEmpty && !query.types.contains(device.effectiveType)) {
      return false;
    }
    if (query.osNames.isNotEmpty &&
        !query.osNames.contains(
          device.inferredOs ?? DeviceQuery.unknownValue,
        )) {
      return false;
    }
    if (query.vendors.isNotEmpty &&
        !query.vendors.contains(device.vendor ?? DeviceQuery.unknownValue)) {
      return false;
    }
    final subnet = query.subnet;
    if (subnet != null && !subnet.contains(device.currentIp)) return false;
    if (query.onlyPingConfirmed && !device.pingConfirmed) return false;
    return matchesSearch(device);
  }).toList();

  int compare(Device a, Device b) => switch (query.sortField) {
    DeviceSortField.ip => a.currentIp.compareTo(b.currentIp),
    DeviceSortField.name => a.displayName.toLowerCase().compareTo(
      b.displayName.toLowerCase(),
    ),
    DeviceSortField.lastSeen => a.lastSeenAt.compareTo(b.lastSeenAt),
    DeviceSortField.dailyTraffic => dailyTrafficBytes[a.id]!.compareTo(
      dailyTrafficBytes[b.id]!,
    ),
  };

  filtered.sort((a, b) {
    if (query.sortField == DeviceSortField.dailyTraffic) {
      final aKnown = dailyTrafficBytes.containsKey(a.id);
      final bKnown = dailyTrafficBytes.containsKey(b.id);
      if (aKnown != bKnown) return aKnown ? -1 : 1;
      if (!aKnown) return a.currentIp.compareTo(b.currentIp);
    }
    final result = compare(a, b);
    // IP as a stable tiebreak.
    final tieBroken = result != 0 ? result : a.currentIp.compareTo(b.currentIp);
    return query.ascending ? tieBroken : -tieBroken;
  });
  return filtered;
}
