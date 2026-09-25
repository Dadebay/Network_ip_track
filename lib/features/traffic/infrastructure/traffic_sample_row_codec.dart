import 'dart:convert';

import '../domain/entities/traffic_device_identity.dart';
import '../domain/entities/traffic_reliability.dart';

/// Maps a sample's reliability and MAC/IP binding to and from the
/// `traffic_samples` columns (`reliability`, `mac_address`, `ip_address`).
///
/// Schema v1 had no MAC/IP columns and stored the binding as JSON inside
/// `reliability`; the v2 migration moves existing rows to the columns, and
/// [decode] still tolerates that legacy form.
class TrafficSampleRowCodec {
  const TrafficSampleRowCodec._();

  static String encodeReliability(TrafficReliability reliability) =>
      reliability.name;

  static (TrafficReliability, TrafficDeviceIdentity?) decode(
    String reliability, {
    String? macAddress,
    String? ipAddress,
  }) {
    final columnIdentity = TrafficDeviceIdentity.tryCreate(
      macAddress: macAddress,
      ipAddress: ipAddress,
    );

    Object? legacy;
    if (reliability.startsWith('{')) {
      try {
        legacy = jsonDecode(reliability);
      } on FormatException {
        legacy = null;
      }
    }
    if (legacy is! Map<String, Object?>) {
      return (TrafficReliability.parse(reliability), columnIdentity);
    }
    final level = legacy['level'];
    return (
      level is String
          ? TrafficReliability.parse(level)
          : TrafficReliability.estimated,
      columnIdentity ??
          TrafficDeviceIdentity.tryCreate(
            macAddress: legacy['mac'] as String?,
            ipAddress: legacy['ip'] as String?,
          ),
    );
  }
}
