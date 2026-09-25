import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/utils/ipv4_address.dart';
import '../../domain/repositories/http_banner_provider.dart';

const _maxBodyBytes = 32 * 1024;

/// Parses the classification-relevant parts of an HTTP response. Pure and
/// fixture-testable.
HttpBanner parseHttpBanner({
  required int port,
  required String? serverHeader,
  required String? authenticateHeader,
  required String body,
}) {
  String? clean(String? value) {
    if (value == null) return null;
    final text = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('&amp;', '&')
        .trim();
    if (text.isEmpty) return null;
    return text.length > 80 ? '${text.substring(0, 80)}…' : text;
  }

  final title = RegExp(
    r'<title[^>]*>([\s\S]*?)</title>',
    caseSensitive: false,
  ).firstMatch(body)?.group(1);
  final realm = authenticateHeader == null
      ? null
      : RegExp(
          r'realm="([^"]*)"',
          caseSensitive: false,
        ).firstMatch(authenticateHeader)?.group(1);
  return HttpBanner(
    port: port,
    title: clean(title),
    server: clean(serverHeader),
    realm: clean(realm),
  );
}

/// [HttpBannerProvider] over `dart:io`. HTTPS certificates are not checked:
/// nothing is sent but a plain GET of `/`, and devices use self-signed
/// certificates. Reads at most 32 KB.
class IoHttpBannerProvider implements HttpBannerProvider {
  const IoHttpBannerProvider();

  @override
  Future<HttpBanner?> fetch(
    Ipv4Address address,
    int port, {
    required Duration timeout,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..userAgent = 'network_monitor (device discovery)'
      ..badCertificateCallback = (_, _, _) => true;
    try {
      final uri = Uri(
        scheme: port == 443 || port == 8443 ? 'https' : 'http',
        host: address.toString(),
        port: port,
        path: '/',
      );
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);

      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        bytes.addAll(chunk);
        if (bytes.length >= _maxBodyBytes) break;
      }
      final banner = parseHttpBanner(
        port: port,
        serverHeader: response.headers.value(HttpHeaders.serverHeader),
        authenticateHeader: response.headers.value(
          HttpHeaders.wwwAuthenticateHeader,
        ),
        body: utf8.decode(bytes, allowMalformed: true),
      );
      return banner.isEmpty ? null : banner;
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
