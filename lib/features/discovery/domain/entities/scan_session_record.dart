import '../../../../core/utils/cidr.dart';
import 'scan_checkpoint.dart';
import 'scan_session_status.dart';

/// Persisted record of one scan run — mirrors the `scan_sessions` table.
class ScanSessionRecord {
  const ScanSessionRecord({
    required this.id,
    required this.networkId,
    required this.startedAt,
    required this.targetCidrs,
    required this.status,
    required this.hostsScanned,
    required this.devicesFound,
    this.finishedAt,
    this.checkpoint,
    this.errorMessage,
  });

  final int id;
  final int networkId;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final List<Cidr> targetCidrs;
  final ScanSessionStatus status;
  final int hostsScanned;
  final int devicesFound;
  final ScanCheckpoint? checkpoint;
  final String? errorMessage;

  /// Paused, or left `running` by an app that quit/crashed mid-scan.
  bool get isResumable =>
      checkpoint != null &&
      (status == ScanSessionStatus.paused ||
          status == ScanSessionStatus.running);
}
