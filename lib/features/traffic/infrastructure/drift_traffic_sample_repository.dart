import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/errors/app_failure.dart';
import '../application/local_time_buckets.dart';
import '../application/traffic_aggregation.dart';
import '../domain/entities/device_traffic_summary.dart';
import '../domain/entities/traffic_device_identity.dart';
import '../domain/entities/traffic_retention_policy.dart';
import '../domain/entities/traffic_sample.dart';
import '../domain/repositories/traffic_sample_repository.dart';
import 'traffic_sample_row_codec.dart';

/// [TrafficSampleRepository] backed by the `traffic_samples` table.
class DriftTrafficSampleRepository implements TrafficSampleRepository {
  DriftTrafficSampleRepository(this._database);

  final db.AppDatabase _database;

  // Rows shorter than their target bucket still need rolling up. A local
  // day is at least 23h (DST), so anything shorter is sub-day.
  static const _hourSeconds = 3600;
  static const _shortestDaySeconds = 23 * 3600;

  @override
  Future<void> insertSamples(List<TrafficSample> samples) async {
    if (samples.isEmpty) return;
    await _guard(
      () => _database.batch(
        (batch) => batch.insertAll(_database.trafficSamples, [
          for (final sample in samples) _toCompanion(sample),
        ]),
      ),
    );
  }

  @override
  Future<List<TrafficSample>> samplesForDevice(
    int deviceId, {
    required DateTime from,
    required DateTime to,
  }) {
    return _guard(() async {
      final query = _database.select(_database.trafficSamples)
        ..where(
          (row) =>
              row.deviceId.equals(deviceId) &
              row.periodStart.isBiggerOrEqualValue(from) &
              row.periodStart.isSmallerThanValue(to),
        )
        ..orderBy([(row) => OrderingTerm.asc(row.periodStart)]);
      final rows = await query.get();
      return rows.map(_fromRow).toList();
    });
  }

  @override
  Future<Map<int, TrafficTotals>> totalsByDevice({
    required DateTime from,
    required DateTime to,
  }) {
    return _guard(() async {
      final table = _database.trafficSamples;
      final download = table.downloadBytes.sum();
      final upload = table.uploadBytes.sum();
      final query = _database.selectOnly(table)
        ..addColumns([table.deviceId, download, upload])
        ..where(
          table.periodStart.isBiggerOrEqualValue(from) &
              table.periodStart.isSmallerThanValue(to),
        )
        ..groupBy([table.deviceId]);
      final rows = await query.get();
      return {
        for (final row in rows)
          row.read(table.deviceId)!: TrafficTotals(
            downloadBytes: row.read(download) ?? 0,
            uploadBytes: row.read(upload) ?? 0,
          ),
      };
    });
  }

  @override
  Future<TrafficRetentionReport> applyRetention({
    required DateTime now,
    required TrafficRetentionPolicy policy,
  }) {
    return _guard(() async {
      final deleteBefore = startOfLocalDay(now.subtract(policy.dailyRetention));
      final dailyBefore = startOfLocalDay(now.subtract(policy.hourlyRetention));
      final hourlyBefore = startOfLocalHour(now.subtract(policy.rawRetention));

      final deleted =
          await (_database.delete(_database.trafficSamples)..where(
                (row) => row.periodEnd.isSmallerOrEqualValue(deleteBefore),
              ))
              .go();
      final rolledToDaily = await _rollUp(
        endingBy: dailyBefore,
        shorterThanSeconds: _shortestDaySeconds,
        size: TrafficBucketSize.day,
      );
      final rolledToHourly = await _rollUp(
        endingBy: hourlyBefore,
        shorterThanSeconds: _hourSeconds,
        size: TrafficBucketSize.hour,
      );
      return TrafficRetentionReport(
        rolledUpToHourly: rolledToHourly,
        rolledUpToDaily: rolledToDaily,
        deleted: deleted,
      );
    });
  }

  @override
  Future<int> deleteBySource(String source) {
    return _guard(
      () => (_database.delete(
        _database.trafficSamples,
      )..where((row) => row.source.equals(source))).go(),
    );
  }

  /// Replaces rows finer than [size] that ended by [endingBy] with their
  /// roll-up, in one transaction. Returns the number of input rows replaced.
  Future<int> _rollUp({
    required DateTime endingBy,
    required int shorterThanSeconds,
    required TrafficBucketSize size,
  }) {
    return _database.transaction(() async {
      final table = _database.trafficSamples;
      final query = _database.select(table)
        ..where(
          (row) =>
              row.periodEnd.isSmallerOrEqualValue(endingBy) &
              (row.periodEnd.unixepoch - row.periodStart.unixepoch)
                  .isSmallerThanValue(shorterThanSeconds),
        );
      final rows = await query.get();
      if (rows.isEmpty) return 0;

      final aggregated = rollUpSamples(rows.map(_fromRow), size);
      final ids = [for (final row in rows) row.id];
      const chunk = 500; // Stay well below SQLite's bound-variable limit.
      for (var i = 0; i < ids.length; i += chunk) {
        final slice = ids.sublist(i, (i + chunk).clamp(0, ids.length));
        await (_database.delete(
          table,
        )..where((row) => row.id.isIn(slice))).go();
      }
      await _database.batch(
        (batch) => batch.insertAll(table, [
          for (final sample in aggregated) _toCompanion(sample),
        ]),
      );
      return rows.length;
    });
  }

  db.TrafficSamplesCompanion _toCompanion(TrafficSample sample) =>
      db.TrafficSamplesCompanion.insert(
        deviceId: sample.deviceId,
        source: sample.source,
        periodStart: sample.periodStart,
        periodEnd: sample.periodEnd,
        downloadBytes: sample.downloadBytes,
        uploadBytes: sample.uploadBytes,
        reliability: TrafficSampleRowCodec.encodeReliability(
          sample.reliability,
        ),
        macAddress: Value(sample.identity.macAddress),
        ipAddress: Value(sample.identity.ipAddress),
      );

  TrafficSample _fromRow(db.TrafficSample row) {
    final (reliability, identity) = TrafficSampleRowCodec.decode(
      row.reliability,
      macAddress: row.macAddress,
      ipAddress: row.ipAddress,
    );
    return TrafficSample(
      deviceId: row.deviceId,
      identity: identity ?? TrafficDeviceIdentity.unknown,
      periodStart: row.periodStart,
      periodEnd: row.periodEnd,
      downloadBytes: row.downloadBytes,
      uploadBytes: row.uploadBytes,
      source: row.source,
      reliability: reliability,
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppFailure {
      rethrow;
    } catch (error, stackTrace) {
      throw DatabaseFailure(
        technicalDetail: 'traffic_samples: $error',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}
