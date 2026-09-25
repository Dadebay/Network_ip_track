import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../domain/failures/traffic_failures.dart';

class FortiGateResponse {
  const FortiGateResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

/// One authenticated GET to the FortiOS REST API.
abstract interface class FortiGateTransport {
  /// [apiKey] goes only into the `Authorization` header — never the URL,
  /// where it would end up in access logs. Throws
  /// [FortiGateUntrustedCertificateFailure] or
  /// [TrafficProviderUnreachableFailure]; HTTP error statuses are returned.
  Future<FortiGateResponse> get(
    Uri uri, {
    required String apiKey,
    String? pinnedCertificateSha256,
  });
}

/// Colon-separated uppercase SHA-256 of a DER certificate, the format
/// browsers and the FortiGate GUI show.
String certificateSha256(List<int> der) => sha256
    .convert(der)
    .bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join(':');

/// [FortiGateTransport] over `dart:io` HTTPS. Certificates the system trusts
/// are accepted normally; otherwise only the pinned fingerprint is.
class IoFortiGateTransport implements FortiGateTransport {
  const IoFortiGateTransport({this.timeout = const Duration(seconds: 15)});

  final Duration timeout;

  @override
  Future<FortiGateResponse> get(
    Uri uri, {
    required String apiKey,
    String? pinnedCertificateSha256,
  }) async {
    if (uri.scheme != 'https') {
      throw TrafficProviderUnreachableFailure(
        technicalDetail: 'Yalnızca HTTPS desteklenir: ${uri.scheme}',
      );
    }
    String? presented;
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..badCertificateCallback = (certificate, host, port) {
        presented = certificateSha256(certificate.der);
        return pinnedCertificateSha256 != null &&
            presented == pinnedCertificateSha256;
      };
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers
        ..set(HttpHeaders.authorizationHeader, 'Bearer $apiKey')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      final body = await response
          .transform(utf8.decoder)
          .join()
          .timeout(timeout);
      return FortiGateResponse(statusCode: response.statusCode, body: body);
    } on HandshakeException catch (error) {
      final fingerprint = presented;
      if (fingerprint != null) {
        throw FortiGateUntrustedCertificateFailure(
          presentedSha256: fingerprint,
          technicalDetail: 'TLS: ${error.message}',
        );
      }
      throw TrafficProviderUnreachableFailure(
        technicalDetail: 'TLS: ${error.message}',
        cause: error,
      );
    } on SocketException catch (error) {
      throw TrafficProviderUnreachableFailure(
        technicalDetail: '${uri.host}:${uri.port}: ${error.message}',
        cause: error,
      );
    } on TimeoutException catch (error) {
      throw TrafficProviderUnreachableFailure(
        technicalDetail: '${uri.host}:${uri.port}: zaman aşımı',
        cause: error,
      );
    } finally {
      client.close(force: true);
    }
  }
}
