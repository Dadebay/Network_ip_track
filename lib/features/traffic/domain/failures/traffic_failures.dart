import '../../../../core/errors/app_failure.dart';

/// Router API'ye ulaşılamıyor.
class TrafficProviderUnreachableFailure extends AppFailure {
  TrafficProviderUnreachableFailure({
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  }) : super(
         userMessage:
             'Trafik kaynağına ulaşılamadı. Router adresini ve ağ '
             'bağlantınızı kontrol edip bağlantı testini tekrarlayın.',
       );
}

/// Router authentication başarısız.
class TrafficProviderAuthFailure extends AppFailure {
  TrafficProviderAuthFailure({
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  }) : super(
         userMessage:
             'Router kimlik doğrulaması başarısız. Kullanıcı adı, parola veya '
             'token bilgisini Trafik ayarlarından güncelleyin.',
       );
}

/// Rate limit.
class TrafficProviderRateLimitedFailure extends AppFailure {
  TrafficProviderRateLimitedFailure({
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  }) : super(
         userMessage:
             'Router istek sınırına ulaşıldı. Sorgulama aralığını artırın '
             'veya birkaç dakika sonra tekrar deneyin.',
       );
}

/// Keychain erişimi henüz kurulmadı veya başarısız oldu.
class RouterCredentialStoreUnavailableFailure extends AppFailure {
  RouterCredentialStoreUnavailableFailure({
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  }) : super(
         userMessage:
             'Router kimlik bilgileri macOS Keychain\'e kaydedilemiyor. '
             'Keychain erişimini kontrol edin; bilgiler güvenlik nedeniyle '
             'başka bir yerde saklanmaz.',
       );
}

/// The FortiGate's certificate isn't trusted by the system and doesn't match
/// the pinned fingerprint. Carries the presented fingerprint so the user can
/// compare it with the one in the FortiGate GUI and choose to trust it.
class FortiGateUntrustedCertificateFailure extends AppFailure {
  FortiGateUntrustedCertificateFailure({
    required this.presentedSha256,
    super.technicalDetail,
    super.correlationId,
  }) : super(
         userMessage:
             'FortiGate sertifikası doğrulanamadı. Aşağıdaki parmak izini '
             'FortiGate panelindeki sertifikayla (System > Certificates) '
             'karşılaştırın; aynıysa bu sertifikaya güvenebilirsiniz.',
       );

  /// Colon-separated uppercase hex.
  final String presentedSha256;
}

/// FortiGate address or API key not set up yet.
class FortiGateNotConfiguredFailure extends AppFailure {
  FortiGateNotConfiguredFailure({required String reason, super.correlationId})
    : super(userMessage: reason);
}

/// The log search didn't produce results (not ready in time, logging off,
/// or an unexpected response shape).
class FortiGateLogQueryFailure extends AppFailure {
  FortiGateLogQueryFailure({
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  }) : super(
         userMessage:
             'FortiGate trafik logları okunamadı. LAN→WAN politikalarında '
             '"Log Allowed Traffic: All Sessions" açık mı ve seçilen log '
             'kaynağı (bellek/disk) doğru mu kontrol edin.',
       );
}
