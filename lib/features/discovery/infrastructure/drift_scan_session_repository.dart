import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart' as db;
import '../../../core/utils/cidr.dart';
import '../domain/entities/scan_checkpoint.dart';
import '../domain/entities/scan_session_record.dart';
import '../domain/entities/scan_session_status.dart';
import '../domain/repositories/scan_session_repository.dart';

/// [ScanSessionRepository] backed by Drift/SQLite.
class DriftScanSessionRepository implements ScanSessionRepository {
  DriftScanSessionRepository(this._database, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final db.AppDatabase _database;
  final DateTime Function() _clock;

  static const _terminalStatuses = {
    ScanSessionStatus.completed,
    ScanSessionStatus.cancelled,
    ScanSessionStatus.failed,
  };

  @override
  Future<int> createSession({
    required int networkId,
    required List<Cidr> targetCidrs,
    required ScanCheckpoint checkpoint,
    required DateTime startedAt,
  }) {
    return _database
        .into(_database.scanSessions)
        .insert(
          db.ScanSessionsCompanion.insert(
            networkId: networkId,
            startedAt: startedAt,
            targetCidrsJson: jsonEncode([
              for (final cidr in targetCidrs) cidr.toString(),
            ]),
            status: ScanSessionStatus.running.name,
            checkpointJson: Value(checkpoint.encode()),
          ),
        );
  }

  @override
  Future<void> updateProgress({
    required int sessionId,
    required int hostsScanned,
    required int devicesFound,
    ScanCheckpoint? checkpoint,
  }) async {
    await (_database.update(
      _database.scanSessions,
    )..where((row) => row.id.equals(sessionId))).write(
      db.ScanSessionsCompanion(
        hostsScanned: Value(hostsScanned),
        devicesFound: Value(devicesFound),
        checkpointJson: checkpoint != null
            ? Value(checkpoint.encode())
            : const Value.absent(),
      ),
    );
  }

  @override
  Future<void> markStatus({
    required int sessionId,
    required ScanSessionStatus status,
    String? errorMessage,
  }) async {
    final isTerminal = _terminalStatuses.contains(status);
    await (_database.update(
      _database.scanSessions,
    )..where((row) => row.id.equals(sessionId))).write(
      db.ScanSessionsCompanion(
        status: Value(status.name),
        finishedAt: Value(isTerminal ? _clock() : null),
        errorMessage: Value(errorMessage),
      ),
    );
  }

  @override
  Future<List<ScanSessionRecord>> recentSessions({int limit = 20}) async {
    final rows = await _recentQuery(limit).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Stream<List<ScanSessionRecord>> watchRecentSessions({int limit = 20}) {
    return _recentQuery(
      limit,
    ).watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<ScanSessionRecord?> getSession(int sessionId) async {
    final row = await (_database.select(
      _database.scanSessions,
    )..where((row) => row.id.equals(sessionId))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<ScanSessionRecord?> findResumableSession() async {
    final row =
        await (_database.select(_database.scanSessions)
              ..where(
                (row) =>
                    row.status.isIn([
                      ScanSessionStatus.paused.name,
                      ScanSessionStatus.running.name,
                    ]) &
                    row.checkpointJson.isNotNull(),
              )
              ..orderBy([(row) => OrderingTerm.desc(row.startedAt)])
              ..limit(1))
            .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> markInterruptedSessionsPaused() async {
    await (_database.update(
      _database.scanSessions,
    )..where((row) => row.status.equals(ScanSessionStatus.running.name))).write(
      db.ScanSessionsCompanion(status: Value(ScanSessionStatus.paused.name)),
    );
  }

  SimpleSelectStatement<db.$ScanSessionsTable, db.ScanSession> _recentQuery(
    int limit,
  ) {
    return _database.select(_database.scanSessions)
      ..orderBy([(row) => OrderingTerm.desc(row.startedAt)])
      ..limit(limit);
  }

  ScanSessionRecord _toDomain(db.ScanSession row) {
    return ScanSessionRecord(
      id: row.id,
      networkId: row.networkId,
      startedAt: row.startedAt,
      finishedAt: row.finishedAt,
      targetCidrs: [
        for (final cidr in (jsonDecode(row.targetCidrsJson) as List))
          Cidr.parse(cidr as String),
      ],
      status: ScanSessionStatus.values.byName(row.status),
      hostsScanned: row.hostsScanned,
      devicesFound: row.devicesFound,
      checkpoint: row.checkpointJson == null
          ? null
          : ScanCheckpoint.decode(row.checkpointJson!),
      errorMessage: row.errorMessage,
    );
  }
}
