import 'dart:math' as math;

import '../../application/traffic_collector.dart';
import '../../domain/entities/traffic_connection_test_result.dart';
import '../../domain/entities/traffic_counter_snapshot.dart';
import '../../domain/entities/traffic_device_identity.dart';
import '../../domain/entities/traffic_provider_descriptor.dart';
import '../../domain/repositories/traffic_provider.dart';

/// Simulated per-device counters for trying out the UI without a router.
///
/// Everything it produces is stored with source `demo` and reliability
/// `simulated`, and the UI labels it as demo data. Counters are a smooth,
/// strictly monotonic function of time per device, so the same delta
/// pipeline as a real provider can be exercised.
class DemoTrafficProvider implements CounterTrafficProvider {
  DemoTrafficProvider({
    required Future<List<TrafficDeviceIdentity>> Function() loadDevices,
    DateTime Function() clock = DateTime.now,
  }) : _loadDevices = loadDevices,
       _clock = clock;

  static const providerId = 'demo';

  static const descriptorValue = TrafficProviderDescriptor(
    id: providerId,
    displayName: 'Demo (simüle veri)',
    description:
        'Arayüzü denemek için rastgele olmayan, simüle edilmiş sayaçlar '
        'üretir. Gerçek ölçüm değildir; router\'a bağlanmaz.',
    perspective: CounterPerspective.device,
    isDemo: true,
  );

  final Future<List<TrafficDeviceIdentity>> Function() _loadDevices;
  final DateTime Function() _clock;

  @override
  TrafficProviderDescriptor get descriptor => descriptorValue;

  @override
  Future<TrafficConnectionTestResult> testConnection() async {
    final devices = await _loadDevices();
    return TrafficConnectionTestResult.success(
      checkedAt: _clock(),
      deviceCount: devices.length,
      message:
          'Demo sağlayıcı hazır. Simüle veri üretir; gerçek bir router\'a '
          'bağlanılmadı.',
    );
  }

  @override
  Future<List<TrafficCounterSnapshot>> readCounters() async =>
      countersAt(_clock(), await _loadDevices());

  /// Counters for [devices] at [time]. Pure; also used to backfill history.
  List<TrafficCounterSnapshot> countersAt(
    DateTime time,
    List<TrafficDeviceIdentity> devices,
  ) {
    final seconds = time.millisecondsSinceEpoch / 1000;
    return [for (final device in devices) _counterFor(device, time, seconds)];
  }

  TrafficCounterSnapshot _counterFor(
    TrafficDeviceIdentity device,
    DateTime time,
    double seconds,
  ) {
    final seed = _fnv1a(device.counterKey);
    // 2 kB/s .. ~200 kB/s average download, 5–30 % of that upload.
    final averageRate = 2000 + (seed % 198000);
    final uploadShare = 0.05 + (seed >> 8) % 26 / 100;
    final phase = ((seed >> 16) % 86400).toDouble();

    return TrafficCounterSnapshot(
      identity: device,
      readAt: time,
      receivedBytes: _cumulative(seconds, averageRate.toDouble(), phase),
      transmittedBytes: _cumulative(seconds, averageRate * uploadShare, phase),
    );
  }

  /// Integral of rate(t) = a · (1 + 0.9·sin(ωt + φ)): a daily wave that is
  /// never negative, so the counter never decreases.
  static int _cumulative(double seconds, double averageRate, double phase) {
    const omega = 2 * math.pi / 86400;
    final value =
        averageRate * seconds -
        averageRate *
            0.9 /
            omega *
            (math.cos(omega * (seconds + phase)) - math.cos(omega * phase));
    return value.floor();
  }

  static int _fnv1a(String input) {
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}

/// Feeds hourly demo readings for the last [history] through [collector], so
/// the charts have something to show right after demo mode is enabled. The
/// collector ends with a baseline at [now], so live polling continues
/// seamlessly.
Future<void> backfillDemoHistory({
  required DemoTrafficProvider provider,
  required TrafficCollector collector,
  required List<TrafficDeviceIdentity> devices,
  required DateTime now,
  Duration history = const Duration(days: 7),
}) async {
  if (devices.isEmpty) return;
  var time = now.subtract(history);
  while (time.isBefore(now)) {
    await collector.ingest(provider.countersAt(time, devices));
    time = time.add(const Duration(hours: 1));
  }
  await collector.ingest(provider.countersAt(now, devices));
}
