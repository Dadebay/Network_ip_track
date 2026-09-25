import 'dart:developer' as developer;

import '../errors/app_failure.dart';

/// Thin wrapper around `dart:developer.log`.
///
/// Never logs secrets: callers must not pass passwords, tokens or
/// authentication headers as [message] or [error].
class AppLogger {
  const AppLogger(this._name);

  final String _name;

  void info(String message, {String? correlationId}) {
    developer.log(
      _withCorrelation(message, correlationId),
      name: _name,
      level: 800,
    );
  }

  void warning(String message, {String? correlationId}) {
    developer.log(
      _withCorrelation(message, correlationId),
      name: _name,
      level: 900,
    );
  }

  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    String? correlationId,
  }) {
    developer.log(
      _withCorrelation(message, correlationId),
      name: _name,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void failure(AppFailure failure) {
    error(
      failure.technicalDetail ?? failure.userMessage,
      error: failure.cause,
      stackTrace: failure.stackTrace,
      correlationId: failure.correlationId,
    );
  }

  String _withCorrelation(String message, String? correlationId) {
    if (correlationId == null) return message;
    return '[$correlationId] $message';
  }
}
