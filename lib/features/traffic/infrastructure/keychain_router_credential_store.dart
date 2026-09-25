import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/entities/router_credentials.dart';
import '../domain/failures/traffic_failures.dart';
import '../domain/repositories/router_credential_store.dart';

/// [RouterCredentialStore] backed by the macOS Keychain via the Runner's
/// `network_monitor/keychain` channel (see `MainFlutterWindow.swift`).
///
/// Credentials cross the channel as one JSON value per provider id and are
/// never cached, logged or written anywhere else. Any Keychain error becomes
/// a [RouterCredentialStoreUnavailableFailure] — there is no fallback.
class KeychainRouterCredentialStore implements RouterCredentialStore {
  const KeychainRouterCredentialStore({
    MethodChannel channel = const MethodChannel('network_monitor/keychain'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<RouterCredentials?> read(String providerId) async {
    final raw = await _call<String>('read', {'account': providerId});
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return RouterCredentials(
        username: json['username'] as String?,
        password: json['password'] as String?,
        token: json['token'] as String?,
      );
    } on Object {
      // Deliberately no detail: the payload is secret.
      throw RouterCredentialStoreUnavailableFailure(
        technicalDetail: 'Keychain kaydı çözümlenemedi ($providerId).',
      );
    }
  }

  @override
  Future<void> save(String providerId, RouterCredentials credentials) {
    return _call<void>('write', {
      'account': providerId,
      'value': jsonEncode({
        'username': ?credentials.username,
        'password': ?credentials.password,
        'token': ?credentials.token,
      }),
    });
  }

  @override
  Future<void> delete(String providerId) =>
      _call<void>('delete', {'account': providerId});

  Future<T?> _call<T>(String method, Map<String, String> arguments) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      // error.message is an OSStatus, never the secret.
      throw RouterCredentialStoreUnavailableFailure(
        technicalDetail: 'Keychain $method: ${error.code} ${error.message}',
      );
    } on MissingPluginException {
      throw RouterCredentialStoreUnavailableFailure(
        technicalDetail: 'Keychain kanalı yok ($method).',
      );
    }
  }
}
