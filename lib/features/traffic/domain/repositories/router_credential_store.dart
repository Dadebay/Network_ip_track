import '../entities/router_credentials.dart';

/// Secure storage for router credentials, backed by the macOS Keychain.
///
/// Implementations must never write credentials to SQLite, settings files or
/// logs, and must throw [RouterCredentialStoreUnavailableFailure] rather than
/// fall back to insecure storage.
abstract interface class RouterCredentialStore {
  /// Null when nothing is stored for [providerId].
  Future<RouterCredentials?> read(String providerId);

  Future<void> save(String providerId, RouterCredentials credentials);

  Future<void> delete(String providerId);
}
