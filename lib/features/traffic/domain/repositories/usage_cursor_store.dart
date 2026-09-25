import '../entities/traffic_usage_batch.dart';

/// Persists each usage provider's [UsageCursor] (not secret).
abstract interface class UsageCursorStore {
  Future<UsageCursor?> load(String providerId);
  Future<void> save(String providerId, UsageCursor cursor);
  Future<void> clear(String providerId);
}
