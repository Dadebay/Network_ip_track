import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Base type for user-facing failures.
///
/// [userMessage] must always include a recovery suggestion and must never be
/// shown to the user without one. [technicalDetail] and [correlationId] are
/// for the collapsible "technical details" section and the log line, not the
/// primary message.
abstract class AppFailure implements Exception {
  AppFailure({
    required this.userMessage,
    this.technicalDetail,
    this.cause,
    this.stackTrace,
    String? correlationId,
  }) : correlationId = correlationId ?? _uuid.v4();

  final String userMessage;
  final String? technicalDetail;
  final Object? cause;
  final StackTrace? stackTrace;
  final String correlationId;

  @override
  String toString() =>
      '$runtimeType(correlationId: $correlationId, userMessage: $userMessage, '
      'technicalDetail: $technicalDetail)';
}

/// Ağ arayüzü bulunamadı.
class NoActiveNetworkInterfaceFailure extends AppFailure {
  NoActiveNetworkInterfaceFailure({
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  }) : super(
         userMessage:
             'Aktif bir ağ arayüzü bulunamadı. Wi-Fi veya Ethernet bağlantınızı kontrol edip tekrar deneyin.',
       );
}

/// Route tablosu okunamadı.
class RouteTableUnavailableFailure extends AppFailure {
  RouteTableUnavailableFailure({
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  }) : super(
         userMessage:
             'Ağ rota tablosu okunamadı. Sistem izinlerini kontrol edip tekrar deneyin.',
       );
}

/// VPN aktif veya varsayılan route belirsiz (birden fazla aday arayüz).
class AmbiguousDefaultRouteFailure extends AppFailure {
  AmbiguousDefaultRouteFailure({
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  }) : super(
         userMessage:
             'Aktif ağ belirsiz (VPN etkin olabilir). Lütfen kullanılacak ağ arayüzünü elle seçin.',
       );
}

/// Veritabanı işlemi başarısız oldu.
class DatabaseFailure extends AppFailure {
  DatabaseFailure({
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  }) : super(
         userMessage:
             'Yerel veritabanına erişilemedi. Uygulamayı yeniden başlatıp tekrar deneyin.',
       );
}

/// Seçilen tarama kapsamı geçersiz (hedef yok veya özel 172 bloğu dışında).
class InvalidScanScopeFailure extends AppFailure {
  InvalidScanScopeFailure({
    required super.userMessage,
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  });
}

/// Ping/ARP için gereken izin yok (ör. App Sandbox ICMP soketini engelledi).
class NetworkProbePermissionFailure extends AppFailure {
  NetworkProbePermissionFailure({
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  }) : super(
         userMessage:
             'Ağ yoklaması için izin yok (ping/ARP engellendi). Uygulamanın ağ '
             'erişim iznini kontrol edin veya README\'deki macOS izinleri '
             'bölümüne bakın.',
       );
}

/// Kaydedilmiş tarama farklı bir ağa ait; devam ettirmek yanlış hedefi tarar.
class ScanNetworkChangedFailure extends AppFailure {
  ScanNetworkChangedFailure({
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  }) : super(
         userMessage:
             'Bu tarama başka bir ağda başlatılmış. Aynı ağa bağlanıp devam '
             'edin ya da yeni bir tarama başlatın.',
       );
}

/// Beklenmeyen/sınıflandırılmamış hata.
class UnexpectedFailure extends AppFailure {
  UnexpectedFailure({
    super.technicalDetail,
    super.cause,
    super.stackTrace,
    super.correlationId,
  }) : super(
         userMessage: 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
       );
}

/// Normalizes any thrown [error] into an [AppFailure] so presentation code
/// always has a user message + technical detail + correlation ID to show,
/// even for errors that were not raised as an [AppFailure].
AppFailure asAppFailure(Object error, [StackTrace? stackTrace]) {
  if (error is AppFailure) return error;
  return UnexpectedFailure(
    technicalDetail: error.toString(),
    cause: error,
    stackTrace: stackTrace,
  );
}
