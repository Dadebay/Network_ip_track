import '../../../../core/errors/app_failure.dart';

/// Outcome of [TrafficProvider.testConnection].
class TrafficConnectionTestResult {
  const TrafficConnectionTestResult.success({
    required this.checkedAt,
    required this.message,
    this.deviceCount,
  }) : failure = null;

  const TrafficConnectionTestResult.failure({
    required this.checkedAt,
    required AppFailure this.failure,
  }) : message = null,
       deviceCount = null;

  final DateTime checkedAt;

  /// Set on success.
  final String? message;

  /// Devices with counters the provider reported, when known.
  final int? deviceCount;

  /// Set on failure.
  final AppFailure? failure;

  bool get isSuccess => failure == null;
}
