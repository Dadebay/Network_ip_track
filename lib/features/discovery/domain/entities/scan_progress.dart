import '../../../../core/errors/app_failure.dart';
import 'scan_chunk.dart';
import 'scan_session_status.dart';
import 'scan_stage.dart';

/// Live progress snapshot the UI renders while a scan is running.
class ScanProgress {
  const ScanProgress({
    required this.sessionId,
    required this.status,
    required this.stage,
    required this.chunks,
    required this.runStartedAt,
    required this.now,
    this.hostsScannedAtRunStart = 0,
    this.devicesFoundTotal = 0,
    this.failure,
  });

  final int sessionId;
  final ScanSessionStatus status;
  final ScanStage stage;
  final List<ScanChunk> chunks;

  /// When this run (not the whole session — it may have been resumed)
  /// started, and how many hosts were already done at that point. Rates are
  /// computed from this run only so a resume doesn't skew the estimate.
  final DateTime runStartedAt;
  final int hostsScannedAtRunStart;
  final DateTime now;

  final int devicesFoundTotal;
  final AppFailure? failure;

  int get hostsScannedTotal =>
      chunks.fold(0, (sum, chunk) => sum + chunk.hostsScanned);
  int get hostsTotal => chunks.fold(0, (sum, chunk) => sum + chunk.hostsTotal);

  double get fractionComplete =>
      hostsTotal == 0 ? 0 : hostsScannedTotal / hostsTotal;

  Duration get elapsed => now.difference(runStartedAt);

  Duration? get estimatedRemaining {
    final doneThisRun = hostsScannedTotal - hostsScannedAtRunStart;
    if (doneThisRun <= 0 || elapsed.inMilliseconds <= 0) return null;
    final msPerHost = elapsed.inMilliseconds / doneThisRun;
    final remainingHosts = hostsTotal - hostsScannedTotal;
    return Duration(milliseconds: (msPerHost * remainingHosts).round());
  }

  bool get isActive => status == ScanSessionStatus.running;

  ScanProgress copyWith({
    ScanSessionStatus? status,
    ScanStage? stage,
    List<ScanChunk>? chunks,
    DateTime? now,
    int? devicesFoundTotal,
    AppFailure? failure,
  }) {
    return ScanProgress(
      sessionId: sessionId,
      status: status ?? this.status,
      stage: stage ?? this.stage,
      chunks: chunks ?? this.chunks,
      runStartedAt: runStartedAt,
      hostsScannedAtRunStart: hostsScannedAtRunStart,
      now: now ?? this.now,
      devicesFoundTotal: devicesFoundTotal ?? this.devicesFoundTotal,
      failure: failure ?? this.failure,
    );
  }
}
