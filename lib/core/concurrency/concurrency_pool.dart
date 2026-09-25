import 'dart:async';
import 'dart:collection';

/// Runs async tasks with a bounded number in flight at once.
///
/// Everything scanning does is I/O-bound (process spawning, socket
/// connects) and `await`s the whole way through, so bounding concurrency
/// this way keeps the UI isolate's event loop free without needing a
/// separate `Isolate` — the requirement is "don't block the UI thread", not
/// "don't use the UI isolate at all", and nothing here ever blocks
/// synchronously.
class ConcurrencyPool {
  ConcurrencyPool(this.maxConcurrent)
    : assert(maxConcurrent > 0, 'maxConcurrent must be positive');

  final int maxConcurrent;
  int _active = 0;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  /// Runs [task], queuing it if [maxConcurrent] tasks are already running.
  Future<T> run<T>(Future<T> Function() task) async {
    if (_active >= maxConcurrent) {
      final completer = Completer<void>();
      _waiters.add(completer);
      await completer.future;
    }
    _active++;
    try {
      return await task();
    } finally {
      _active--;
      if (_waiters.isNotEmpty) {
        _waiters.removeFirst().complete();
      }
    }
  }
}
