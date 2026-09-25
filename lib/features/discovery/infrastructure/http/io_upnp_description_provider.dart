import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/utils/ipv4_address.dart';
import '../../domain/entities/upnp_device_info.dart';
import '../../domain/repositories/upnp_description_provider.dart';

const _maxBodyBytes = 64 * 1024;

/// Reads the first `<device>`'s identity fields from a UPnP description
/// document. Pure and fixture-testable; a regex scan rather than a full XML
/// parser, since only four flat text elements are needed.
UpnpDeviceInfo? parseUpnpDescription(String xml) {
  final deviceStart = xml.indexOf(RegExp(r'<device[\s>]'));
  final scope = deviceStart == -1 ? xml : xml.substring(deviceStart);

  String? field(String name) {
    final raw = RegExp(
      '<$name>([^<]*)</$name>',
      caseSensitive: false,
    ).firstMatch(scope)?.group(1);
    if (raw == null) return null;
    final text = raw
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.isEmpty) return null;
    return text.length > 80 ? text.substring(0, 80) : text;
  }

  final info = UpnpDeviceInfo(
    friendlyName: field('friendlyName'),
    manufacturer: field('manufacturer'),
    modelName: field('modelName'),
    modelNumber: field('modelNumber'),
  );
  return info.isEmpty ? null : info;
}

/// [UpnpDescriptionProvider] over `dart:io`. Only fetches a `LOCATION`
/// whose host is the responding device itself, so a spoofed SSDP reply
/// can't make the app request an arbitrary URL.
class IoUpnpDescriptionProvider implements UpnpDescriptionProvider {
  const IoUpnpDescriptionProvider();

  @override
  Future<UpnpDeviceInfo?> fetch(
    Ipv4Address address,
    String location, {
    required Duration timeout,
  }) async {
    final uri = Uri.tryParse(location);
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host != address.toString()) {
      return null;
    }
    final client = HttpClient()
      ..connectionTimeout = timeout
      ..userAgent = 'network_monitor (device discovery)'
      ..badCertificateCallback = (_, _, _) => true;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok) return null;

      final bytes = <int>[];
      await for (final chunk in response.timeout(timeout)) {
        bytes.addAll(chunk);
        if (bytes.length >= _maxBodyBytes) break;
      }
      return parseUpnpDescription(utf8.decode(bytes, allowMalformed: true));
    } on Object {
      return null;
    } finally {
      client.close(force: true);
    }
  }
}
