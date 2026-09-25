import '../../../core/logging/app_logger.dart';
import '../domain/entities/traffic_reliability.dart';
import '../domain/entities/traffic_sample.dart';
import '../domain/entities/traffic_usage_batch.dart';
import '../domain/repositories/traffic_device_resolver.dart';
import '../domain/repositories/traffic_provider.dart';
import '../domain/repositories/traffic_sample_repository.dart';
import '../domain/repositories/usage_cursor_store.dart';
import 'counter_delta.dart';
import 'traffic_collector.dart';

/// Reads usage records from a [UsageTrafficProvider] and stores them.
///
/// Pipeline: read after the persisted cursor -> split at local hour (and
/// day) boundaries -> resolve device on the active network -> persist ->
/// advance the cursor. The cursor only moves after the samples are stored,
/// so a failed write is retried next poll instead of being lost.
class TrafficUsageCollector implements TrafficPoller {
  TrafficUsageCollector({
    required UsageTrafficProvider provider,
    required TrafficDeviceResolver resolver,
    required TrafficSampleRepository repository,
    required UsageCursorStore cursors,
    DateTime Function()? clock,
    this.initialLookback = const Duration(hours: 24),
    AppLogger logger = const AppLogger('traffic.usage'),
  }) : _provider = provider,
       _resolver = resolver,
       _repository = repository,
       _cursors = cursors,
       _clock = clock ?? DateTime.now,
       _logger = logger;

  final UsageTrafficProvider _provider;
  final TrafficDeviceResolver _resolver;
  final TrafficSampleRepository _repository;
  final UsageCursorStore _cursors;
  final DateTime Function() _clock;
  final AppLogger _logger;

  /// How far back the very first poll reads.
  final Duration initialLookback;

  @override
  Future<TrafficCollectionReport> pollOnce() async {
    final descriptor = _provider.descriptor;
    final cursor =
        await _cursors.load(descriptor.id) ??
        UsageCursor(endedAfter: _clock().subtract(initialLookback));
    final batch = await _provider.readUsage(after: cursor);

    final usages = <TrafficUsage>[
      for (final record in batch.records)
        if (record.periodEnd.isAfter(record.periodStart) &&
            (record.downloadBytes > 0 || record.uploadBytes > 0))
          ...splitAtLocalHourBoundaries(
            TrafficUsage(
              identity: record.identity,
              periodStart: record.periodStart,
              periodEnd: record.periodEnd,
              downloadBytes: record.downloadBytes,
              uploadBytes: record.uploadBytes,
              source: descriptor.id,
              reliability: descriptor.isDemo
                  ? TrafficReliability.simulated
                  : TrafficReliability.measured,
            ),
          ),
    ];

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
    await _cursors.save(descriptor.id, batch.next);

    if (batch.truncated) {
      _logger.warning(
        '${descriptor.id}: tek okumada alınabilecekten fazla kayıt vardı; '
        'bazı eski kayıtlar atlanmış olabilir.',
      );
    }
    return TrafficCollectionReport(
      readings: batch.records.length,
      samplesWritten: samples.length,
      baselines: 0,
      counterResets: 0,
      clockAnomalies: 0,
      unresolvedDevices: unresolved,
      truncated: batch.truncated,
    );
  }
}
