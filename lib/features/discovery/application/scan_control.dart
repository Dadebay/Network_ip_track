import 'dart:async';

enum ScanStopRequest { pause, cancel }

/// Cooperative stop signal shared between the UI and a running scan. The
/// engine checks it before scheduling each new probe, so a stop never
/// starts new work; probes already in flight finish (each is bounded by
/// its own timeout) and are recorded before the scan reports it stopped.
class ScanControl {
  ScanStopRequest? _request;
  final _stopped = Completer<void>();

  ScanStopRequest? get request => _request;
  bool get isStopRequested => _request != null;

  /// Completes when a stop is first requested, so waits (mDNS/SSDP
  /// listening windows) can end early.
  Future<void> get onStopRequested => _stopped.future;

  void pause() => _requestStop(ScanStopRequest.pause);

  /// Cancel wins over an earlier pause request.
  void cancel() => _requestStop(ScanStopRequest.cancel);

  void _requestStop(ScanStopRequest request) {
    if (_request == ScanStopRequest.cancel) return;
    _request = request;
    if (!_stopped.isCompleted) _stopped.complete();
  }
}
