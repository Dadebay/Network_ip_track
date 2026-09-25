import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/traffic/domain/entities/fortigate_config.dart';
import 'package:network_monitor/features/traffic/domain/entities/router_credentials.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_usage_batch.dart';
import 'package:network_monitor/features/traffic/domain/failures/traffic_failures.dart';
import 'package:network_monitor/features/traffic/domain/repositories/router_credential_store.dart';
import 'package:network_monitor/features/traffic/infrastructure/fortigate/fortigate_log_parser.dart';
import 'package:network_monitor/features/traffic/infrastructure/fortigate/fortigate_traffic_provider.dart';
import 'package:network_monitor/features/traffic/infrastructure/fortigate/fortigate_transport.dart';

String fixture(String name) =>
    File('test/fixtures/fortigate/$name').readAsStringSync();

class MemoryCredentials implements RouterCredentialStore {
  final Map<String, RouterCredentials> stored = {};

  @override
  Future<RouterCredentials?> read(String providerId) async =>
      stored[providerId];

  @override
  Future<void> save(String providerId, RouterCredentials credentials) async =>
      stored[providerId] = credentials;

  @override
  Future<void> delete(String providerId) async => stored.remove(providerId);
}

/// Answers each request with the next scripted response and records it.
class ScriptedTransport implements FortiGateTransport {
  ScriptedTransport(this.responder);

  final FortiGateResponse Function(Uri uri) responder;
  final List<Uri> requests = [];
  final List<String> apiKeys = [];
  final List<String?> pins = [];

  @override
  Future<FortiGateResponse> get(
    Uri uri, {
    required String apiKey,
    String? pinnedCertificateSha256,
  }) async {
    requests.add(uri);
    apiKeys.add(apiKey);
    pins.add(pinnedCertificateSha256);
    return responder(uri);
  }
}

String logPage(
  List<Map<String, Object?>> rows, {
  int start = 1,
  int rows_ = 2,
}) => jsonEncode({
  'results': rows,
  'start': start,
  'rows': rows_,
  'completed': 100,
  'ready': true,
  'status': 'success',
});

Map<String, Object?> row(
  int id, {
  int eventSeconds = 1790323000,
  int bytes = 100,
}) => {
  'eventtime': eventSeconds * 1000000000,
  'logid': '0000000013',
  'action': 'close',
  'srcip': '172.16.14.12',
  'srcmac': 'a4:83:e7:01:02:03',
  'sessionid': id,
  'duration': 10,
  'sentbyte': bytes,
  'rcvdbyte': bytes * 10,
};

void main() {
  const config = FortiGateConfig(host: '172.16.14.254', vdom: 'root');

  group('log parsing', () {
    test('turns documented traffic-log rows into usage records', () {
      final page = parseFortiGateLogPage(fixture('traffic_forward_page.json'));
      expect(page.isReady, isTrue);
      expect(page.rows, hasLength(5));

      final records = fortiGateUsageRecords(page.rows);
      // deny row and the row without eventtime are skipped.
      expect(records, hasLength(3));

      final phone = records[0];
      expect(phone.identity.macAddress, 'a4:83:e7:01:02:03');
      expect(phone.identity.ipAddress, '172.16.14.12');
      // sentbyte = originator's upload, rcvdbyte = its download.
      expect(phone.uploadBytes, 1800000);
      expect(phone.downloadBytes, 18000000);
      // Spread over the session: [eventtime − duration, eventtime].
      expect(
        phone.periodEnd.difference(phone.periodStart),
        const Duration(seconds: 1800),
      );

      // Interim-stat row: only the delta counts (strings are accepted).
      final interim = records[1];
      expect(interim.uploadBytes, 100);
      expect(interim.downloadBytes, 2000);

      // Seconds-resolution eventtime from older builds; no MAC.
      final older = records[2];
      expect(
        older.periodEnd,
        DateTime.fromMillisecondsSinceEpoch(1790323195000),
      );
      expect(older.identity.macAddress, isNull);
      expect(older.identity.ipAddress, '172.16.14.77');
    });

    test('eventtime unit is inferred from its magnitude', () {
      final expected = DateTime.fromMillisecondsSinceEpoch(1790323195000);
      expect(fortiGateEventTime(1790323195), expected);
      expect(fortiGateEventTime(1790323195000), expected);
      expect(fortiGateEventTime(1790323195000000), expected);
      expect(fortiGateEventTime('1790323195000000000'), expected);
      expect(fortiGateEventTime(null), isNull);
    });

    test('status response is summarized', () {
      expect(
        describeFortiGateStatus(fixture('system_status.json')),
        'FGT60F · FortiOS v7.2.5 build1517 · FGT60FTK20000000',
      );
    });

    test('a non-log response is rejected', () {
      expect(
        () => parseFortiGateLogPage('{"status":"error"}'),
        throwsFormatException,
      );
    });
  });

  group('config', () {
    test(
      'rejects URLs, paths and bad ports; builds https URIs with the VDOM',
      () {
        expect(const FortiGateConfig(host: '').validationError, isNotNull);
        expect(
          const FortiGateConfig(host: 'https://fw/').validationError,
          isNotNull,
        );
        expect(
          const FortiGateConfig(host: 'fw', port: 0).validationError,
          isNotNull,
        );
        expect(config.validationError, isNull);
        final uri = config.uri('/api/v2/monitor/system/status');
        expect(uri.scheme, 'https');
        expect(uri.queryParameters['vdom'], 'root');
      },
    );

    test('certificate fingerprints are colon-separated uppercase SHA-256', () {
      final fingerprint = certificateSha256(utf8.encode('abc'));
      expect(
        fingerprint,
        'BA:78:16:BF:8F:01:CF:EA:41:41:40:DE:5D:AE:22:23:'
        'B0:03:61:A3:96:17:7A:9C:B4:10:FF:61:F2:00:15:AD',
      );
    });
  });

  group('provider', () {
    late MemoryCredentials credentials;

    setUp(() {
      credentials = MemoryCredentials()
        ..stored[FortiGateTrafficProvider.providerId] = const RouterCredentials(
          token: 'KEY-123',
        );
    });

    FortiGateTrafficProvider provider(
      ScriptedTransport transport, {
      FortiGateConfig cfg = config,
      int pageSize = 2,
    }) => FortiGateTrafficProvider(
      config: cfg,
      credentials: credentials,
      transport: transport,
      delay: (_) async {},
      pageSize: pageSize,
      maxPages: 5,
    );

    test('connection test reads status and probes the log endpoint', () async {
      final transport = ScriptedTransport(
        (uri) => FortiGateResponse(
          statusCode: 200,
          body: uri.path.endsWith('status')
              ? fixture('system_status.json')
              : fixture('traffic_forward_page.json'),
        ),
      );
      final result = await provider(transport).testConnection();
      expect(result.isSuccess, isTrue, reason: result.failure?.toString());
      expect(result.message, contains('FGT60F'));
      expect(transport.requests.map((u) => u.path), [
        '/api/v2/monitor/system/status',
        '/api/v2/log/memory/traffic/forward',
      ]);
      // The key goes in the header only, never the URL.
      expect(transport.apiKeys.toSet(), {'KEY-123'});
      for (final uri in transport.requests) {
        expect(uri.toString(), isNot(contains('KEY-123')));
        expect(uri.queryParameters.containsKey('access_token'), isFalse);
      }
    });

    test('without an API key nothing is sent', () async {
      credentials.stored.clear();
      final transport = ScriptedTransport((_) => throw StateError('no call'));
      final result = await provider(transport).testConnection();
      expect(result.failure, isA<FortiGateNotConfiguredFailure>());
      expect(transport.requests, isEmpty);
    });

    test('HTTP 401/403 is an authentication failure', () async {
      final transport = ScriptedTransport(
        (_) => const FortiGateResponse(statusCode: 401, body: ''),
      );
      final result = await provider(transport).testConnection();
      expect(result.failure, isA<TrafficProviderAuthFailure>());
    });

    test('an untrusted certificate is surfaced with its fingerprint', () async {
      final transport = ScriptedTransport(
        (_) => throw FortiGateUntrustedCertificateFailure(
          presentedSha256: 'AA:BB',
        ),
      );
      final result = await provider(transport).testConnection();
      expect(
        (result.failure! as FortiGateUntrustedCertificateFailure)
            .presentedSha256,
        'AA:BB',
      );
    });

    test('the pinned fingerprint is passed to the transport', () async {
      final transport = ScriptedTransport(
        (_) => FortiGateResponse(
          statusCode: 200,
          body: fixture('system_status.json'),
        ),
      );
      await provider(
        transport,
        cfg: config.copyWith(pinnedCertificateSha256: () => 'AA:BB'),
      ).testConnection();
      expect(transport.pins.first, 'AA:BB');
    });

    test('waits for an asynchronous log search using its session_id', () async {
      var calls = 0;
      final transport = ScriptedTransport((uri) {
        calls++;
        if (calls < 3) {
          return FortiGateResponse(
            statusCode: 200,
            body: jsonEncode({
              'results': [],
              'session_id': 77,
              'completed': calls * 30,
              'ready': false,
            }),
          );
        }
        expect(uri.queryParameters['session_id'], '77');
        return FortiGateResponse(statusCode: 200, body: logPage([row(1)]));
      });
      final batch = await provider(
        transport,
      ).readUsage(after: UsageCursor(endedAfter: DateTime(2020)));
      expect(batch.records, hasLength(1));
      expect(calls, 3);
    });

    test(
      'pages through logs and returns only records after the cursor',
      () async {
        final pages = [
          logPage([
            row(1, eventSeconds: 1790323000),
            row(2, eventSeconds: 1790323100),
          ]),
          logPage([
            row(3, eventSeconds: 1790323200),
            row(4, eventSeconds: 1790323300),
          ], start: 3),
          logPage([row(5, eventSeconds: 1790323400)], start: 5),
        ];
        final transport = ScriptedTransport((uri) {
          final start = int.tryParse(uri.queryParameters['start'] ?? '') ?? 1;
          return FortiGateResponse(
            statusCode: 200,
            body: pages[(start - 1) ~/ 2],
          );
        });
        // As left by a previous read that ended with session 2.
        final cursor = UsageCursor(
          endedAfter: DateTime.fromMillisecondsSinceEpoch(1790323100000),
          keysAtBoundary: const {'2|1790323100000000000|0000000013'},
        );
        final batch = await provider(transport).readUsage(after: cursor);
        expect(batch.truncated, isFalse);
        expect(transport.requests.map((u) => u.queryParameters['start']), [
          null,
          '3',
          '5',
        ]);
        expect(batch.records.map((r) => r.key.split('|').first), [
          '3',
          '4',
          '5',
        ]);
        expect(
          batch.next.endedAfter,
          DateTime.fromMillisecondsSinceEpoch(1790323400000),
        );

        // Reading again from the new cursor yields nothing new.
        final again = await provider(transport).readUsage(after: batch.next);
        expect(again.records, isEmpty);
      },
    );

    test('stops at maxPages and reports truncation', () async {
      final transport = ScriptedTransport(
        (uri) =>
            FortiGateResponse(statusCode: 200, body: logPage([row(1), row(2)])),
      );
      final batch = await provider(
        transport,
      ).readUsage(after: UsageCursor(endedAfter: DateTime(2020)));
      expect(batch.truncated, isTrue);
      expect(transport.requests, hasLength(5));
      // Same rows on every page are deduplicated.
      expect(batch.records, hasLength(2));
    });
  });
}
