/// Where FortiOS keeps the traffic logs the adapter reads.
enum FortiGateLogSource {
  memory('Bellek (memory)'),
  disk('Disk');

  const FortiGateLogSource(this.label);
  final String label;
}

/// Non-secret FortiGate connection settings. The REST API key lives only in
/// the Keychain.
class FortiGateConfig {
  const FortiGateConfig({
    this.host = '',
    this.port = 443,
    this.vdom = 'root',
    this.logSource = FortiGateLogSource.memory,
    this.pinnedCertificateSha256,
  });

  /// IP or hostname of the FortiGate's HTTPS admin interface.
  final String host;
  final int port;
  final String vdom;
  final FortiGateLogSource logSource;

  /// SHA-256 of the admin certificate the user confirmed (FortiGates ship
  /// with self-signed certificates). Only this exact certificate is accepted
  /// when the system trust store rejects it; TLS is never switched off.
  final String? pinnedCertificateSha256;

  static final _hostPattern = RegExp(
    r'^(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)*'
    r'[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$',
  );

  /// Null when valid, otherwise a user-facing reason.
  String? get validationError {
    if (host.trim().isEmpty) return 'FortiGate adresini girin.';
    if (!_hostPattern.hasMatch(host.trim())) {
      return 'Geçersiz adres. Yalnızca IP veya ana bilgisayar adı girin '
          '(https:// ve yol olmadan).';
    }
    if (port < 1 || port > 65535) return 'Port 1–65535 arasında olmalı.';
    if (!RegExp(r'^[A-Za-z0-9_-]{1,31}$').hasMatch(vdom)) {
      return 'Geçersiz VDOM adı.';
    }
    return null;
  }

  bool get isComplete => validationError == null;

  Uri uri(String path, [Map<String, String> query = const {}]) => Uri(
    scheme: 'https',
    host: host.trim(),
    port: port,
    path: path,
    queryParameters: {'vdom': vdom, ...query},
  );

  FortiGateConfig copyWith({
    String? host,
    int? port,
    String? vdom,
    FortiGateLogSource? logSource,
    String? Function()? pinnedCertificateSha256,
  }) => FortiGateConfig(
    host: host ?? this.host,
    port: port ?? this.port,
    vdom: vdom ?? this.vdom,
    logSource: logSource ?? this.logSource,
    pinnedCertificateSha256: pinnedCertificateSha256 != null
        ? pinnedCertificateSha256()
        : this.pinnedCertificateSha256,
  );

  Map<String, Object?> toJson() => {
    'host': host,
    'port': port,
    'vdom': vdom,
    'logSource': logSource.name,
    'pinnedCertificateSha256': pinnedCertificateSha256,
  };

  factory FortiGateConfig.fromJson(Map<String, Object?> json) {
    const defaults = FortiGateConfig();
    final port = json['port'];
    return FortiGateConfig(
      host: json['host'] as String? ?? defaults.host,
      port: port is int ? port : defaults.port,
      vdom: json['vdom'] as String? ?? defaults.vdom,
      logSource:
          FortiGateLogSource.values.asNameMap()[json['logSource']] ??
          defaults.logSource,
      pinnedCertificateSha256: json['pinnedCertificateSha256'] as String?,
    );
  }
}
