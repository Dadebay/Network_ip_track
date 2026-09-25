import '../../../../core/utils/cidr.dart';
import '../entities/scan_checkpoint.dart';
import '../entities/scan_session_record.dart';
import '../entities/scan_session_status.dart';

/// Persistence for `scan_sessions` — the queue/checkpoint store that lets a
/// large scan be paused, resumed after an app restart, or reviewed later
/// from "Son taramalar".
abstract interface class ScanSessionRepository {
  Future<int> createSession({
    required int networkId,
    required List<Cidr> targetCidrs,
    required ScanCheckpoint checkpoint,
    required DateTime startedAt,
  });

  Future<void> updateProgress({
    required int sessionId,
    required int hostsScanned,
    required int devicesFound,
    ScanCheckpoint? checkpoint,
  });

  /// Sets [status]; terminal statuses (completed/cancelled/failed) also
  /// stamp `finished_at`.
  Future<void> markStatus({
    required int sessionId,
    required ScanSessionStatus status,
    String? errorMessage,
  });

  Future<List<ScanSessionRecord>> recentSessions({int limit = 20});

  Stream<List<ScanSessionRecord>> watchRecentSessions({int limit = 20});

  Future<ScanSessionRecord?> getSession(int sessionId);

  /// The newest paused (or interrupted) session, if any.
  Future<ScanSessionRecord?> findResumableSession();

  /// Called once at startup, before any scan runs: a session still marked
  /// `running` was interrupted by the app quitting, so it becomes `paused`.
  Future<void> markInterruptedSessionsPaused();
}
