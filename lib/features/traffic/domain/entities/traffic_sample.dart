import 'traffic_device_identity.dart';
import 'traffic_reliability.dart';

/// Bytes a device used during [periodStart]..[periodEnd], before it has been
/// matched to a `devices` row.
class TrafficUsage {
  const TrafficUsage({
    required this.identity,
    required this.periodStart,
    required this.periodEnd,
    required this.downloadBytes,
    required this.uploadBytes,
    required this.source,
    required this.reliability,
  });

  final TrafficDeviceIdentity identity;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int downloadBytes;
  final int uploadBytes;

  /// Provider id (e.g. `demo`).
  final String source;
  final TrafficReliability reliability;

  TrafficSample toSample(int deviceId) => TrafficSample(
    deviceId: deviceId,
    identity: identity,
    periodStart: periodStart,
    periodEnd: periodEnd,
    downloadBytes: downloadBytes,
    uploadBytes: uploadBytes,
    source: source,
    reliability: reliability,
  );
}

/// A persisted traffic sample (`traffic_samples` row).
class TrafficSample {
  const TrafficSample({
    required this.deviceId,
    required this.identity,
    required this.periodStart,
    required this.periodEnd,
    required this.downloadBytes,
    required this.uploadBytes,
    required this.source,
    required this.reliability,
  });

  final int deviceId;

  /// MAC/IP binding at the time of the sample.
  final TrafficDeviceIdentity identity;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int downloadBytes;
  final int uploadBytes;
  final String source;
  final TrafficReliability reliability;

  int get totalBytes => downloadBytes + uploadBytes;
}
