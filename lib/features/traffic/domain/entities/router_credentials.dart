/// Router login material. Only ever held in memory and in the macOS
/// Keychain — never written to SQLite, settings files or logs.
class RouterCredentials {
  const RouterCredentials({this.username, this.password, this.token});

  final String? username;
  final String? password;
  final String? token;

  /// Redacted on purpose so credentials can't leak through logging or error
  /// messages.
  @override
  String toString() =>
      'RouterCredentials(username: ${username == null ? 'null' : '<set>'}, '
      'password: ${password == null ? 'null' : '<redacted>'}, '
      'token: ${token == null ? 'null' : '<redacted>'})';
}
