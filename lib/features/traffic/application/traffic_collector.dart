import '../../../core/logging/app_logger.dart';
import '../domain/entities/traffic_counter_snapshot.dart';
import '../domain/entities/traffic_reliability.dart';
import '../domain/entities/traffic_sample.dart';
import '../domain/repositories/traffic_device_resolver.dart';
import '../domain/repositories/traffic_provider.dart';
import '../domain/repositories/traffic_sample_repository.dart';
import 'counter_delta.dart';

/// One polling step of a traffic provider, whichever shape it has.
abstract interface class TrafficPoller {
  Future<TrafficCollectionReport> pollOnce();
}

class TrafficCollectionReport {
  const TrafficCollectionReport({
    required this.readings,
    required this.samplesWritten,
    required this.baselines,
    required this.counterResets,
    required this.clockAnomalies,
    required this.unresolvedDevices,
    this.truncated = false,
  });

  /// The source had more records than one poll reads; some may be missing.
  final bool truncated;

  final int readings;
  final int samplesWritten;

  /// Devices seen for the first time since the collector started.
  final int baselines;

  /// "Sayaç resetlendi": readings whose counters went backwards.
  final int counterResets;
  final int clockAnomalies;

  /// Readings whose MAC/IP matched no known device (usage dropped).
  final int unresolvedDevices;
}

/// Reads counters from a [TrafficProvider], converts them to per-device
/// samples and stores them.
///
/// Pipeline: normalize direction -> monotonic delta (resets not counted) ->
/// split at local hour (and so day) boundaries -> resolve device -> persist.
class TrafficCollector implements TrafficPoller {
  TrafficCollector({
    required CounterTrafficProvider provider,
    required TrafficDeviceResolver resolver,
    required TrafficSampleRepository repository,
    AppLogger logger = const AppLogger('traffic.collector'),
  }) : _provider = provider,
       _resolver = resolver,
       _repository = repository,
       _logger = logger;

  final CounterTrafficProvider _provider;
  final TrafficDeviceResolver _resolver;
  final TrafficSampleRepository _repository;
  final AppLogger _logger;
  final _tracker = CounterDeltaTracker();

  @override
  Future<TrafficCollectionReport> pollOnce() async =>
      ingest(await _provider.readCounters());

  /// Processes one batch of readings taken at (roughly) the same time.
  Future<TrafficCollectionReport> ingest(
    List<TrafficCounterSnapshot> snapshots,
  ) async {
    final descriptor = _provider.descriptor;
    final reliability = descriptor.isDemo
        ? TrafficReliability.simulated
        : TrafficReliability.measured;
    final results = _tracker.ingest(
      snapshots.map(
        (snapshot) => NormalizedCounterReading.fromSnapshot(
          snapshot,
          descriptor.perspective,
        ),
      ),
      source: descriptor.id,
      reliability: reliability,
    );

    var baselines = 0;
    var resets = 0;
    var anomalies = 0;
    final usages = <TrafficUsage>[];
    for (final result in results) {
      switch (result) {
        case CounterBaseline():
          baselines++;
        case CounterReset():
          resets++;
        case CounterClockAnomaly():
          anomalies++;
        case CounterUsage(:final usage):
          usages.addAll(splitAtLocalHourBoundaries(usage));
      }
    }
    if (resets > 0) {
      _logger.info(
        '${descriptor.id}: $resets counter reset(s) detected; '
        'negative deltas were not counted.',
      );
    }

    var unresolved = 0;
    final samples = <TrafficSample>[];
    if (usages.isNotEmpty) {
      final deviceIds = await _resolver.resolveDeviceIds(
        usages.map((usage) => usage.identity),
      );
      final unresolvedKeys = <String>{};
      for (final usage in usages) {
        final deviceId = deviceIds[usage.identity.counterKey];
        if (deviceId == null) {
          unresolvedKeys.add(usage.identity.counterKey);
        } else {
          samples.add(usage.toSample(deviceId));
        }
      }
      unresolved = unresolvedKeys.length;
      if (samples.isNotEmpty) await _repository.insertSamples(samples);
    }

    return TrafficCollectionReport(
      readings: snapshots.length,
      samplesWritten: samples.length,
      baselines: baselines,
      counterResets: resets,
      clockAnomalies: anomalies,
      unresolvedDevices: unresolved,
    );
  }
}
