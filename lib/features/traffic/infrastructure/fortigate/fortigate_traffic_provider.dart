import 'dart:convert';

import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/fortigate_config.dart';
import '../../domain/entities/traffic_connection_test_result.dart';
import '../../domain/entities/traffic_counter_snapshot.dart';
import '../../domain/entities/traffic_provider_descriptor.dart';
import '../../domain/entities/traffic_usage_batch.dart';
import '../../domain/failures/traffic_failures.dart';
import '../../domain/repositories/router_credential_store.dart';
import '../../domain/repositories/traffic_provider.dart';
import 'fortigate_log_parser.dart';
import 'fortigate_transport.dart';

/// Per-device traffic from a FortiGate's forward-traffic logs via the
/// FortiOS REST API — read-only, with a REST API admin key from the
/// Keychain.
///
/// Uses exactly two endpoints:
/// - `GET /api/v2/monitor/system/status` (connection test)
/// - `GET /api/v2/log/<memory|disk>/traffic/forward` (usage)
///
/// FortiView's realtime per-source bytes are deliberately not used: they
/// cover only currently open sessions and drop when a session closes, so
/// they are not a per-device counter.
class FortiGateTrafficProvider extends UsageTrafficProvider {
  FortiGateTrafficProvider({
    required this.config,
    required RouterCredentialStore credentials,
    FortiGateTransport transport = const IoFortiGateTransport(),
    Future<void> Function(Duration)? delay,
    this.pageSize = 1000,
    this.maxPages = 20,
    this.maxReadyChecks = 15,
  }) : _credentials = credentials,
       _transport = transport,
       _delay = delay ?? ((duration) => Future<void>.delayed(duration));

  static const providerId = 'fortigate';

  final FortiGateConfig config;
  final RouterCredentialStore _credentials;
  final FortiGateTransport _transport;
  final Future<void> Function(Duration) _delay;
  final int pageSize;
  final int maxPages;
  final int maxReadyChecks;

  @override
  TrafficProviderDescriptor get descriptor => const TrafficProviderDescriptor(
    id: providerId,
    displayName: 'FortiGate (FortiOS REST API)',
    description:
        'Cihaz başına trafik, FortiGate forward-traffic loglarından okunur. '
        'Salt okunur REST API anahtarı gerekir.',
    perspective: CounterPerspective.device,
    requiresCredentials: true,
  );

  @override
  Future<TrafficConnectionTestResult> testConnection() async {
    try {
      final status = await _get('/api/v2/monitor/system/status');
      final description = describeFortiGateStatus(status);
      // Also prove the key may read the configured log source.
      final page = await _readLogPage(start: null, rows: 1);
      return TrafficConnectionTestResult.success(
        checkedAt: DateTime.now(),
        message:
            'Bağlandı: $description. ${config.logSource.label} trafik '
            'logları okunabiliyor${page.rows.isEmpty ? ' (şu an kayıt yok)' : ''}.',
      );
    } catch (error, stackTrace) {
      return TrafficConnectionTestResult.failure(
        checkedAt: DateTime.now(),
        failure: asAppFailure(error, stackTrace),
      );
    }
  }

  @override
  Future<TrafficUsageBatch> readUsage({required UsageCursor after}) async {
    final fresh = <ProviderUsageRecord>[];
    var truncated = false;
    int? start;
    for (var pageIndex = 0; ; pageIndex++) {
      if (pageIndex == maxPages) {
        truncated = true;
        break;
      }
      final page = await _readLogPage(start: start, rows: pageSize);
      fresh.addAll(fortiGateUsageRecords(page.rows).where(after.isNew));
      if (page.rows.length < pageSize) break;
      // Continue from where the FortiGate says this page began, so the
      // server's own start convention (0- or 1-based) is respected.
      start = (page.start ?? start ?? 0) + page.rows.length;
    }
    // A record can appear twice across pages if logs arrive mid-read.
    final byKey = {for (final record in fresh) record.key: record};
    final records = byKey.values.toList()
      ..sort((a, b) => a.periodEnd.compareTo(b.periodEnd));
    return TrafficUsageBatch(
      records: records,
      next: after.advancedPast(records),
      truncated: truncated,
    );
  }

  Future<FortiGateLogPage> _readLogPage({
    required int? start,
    required int rows,
  }) async {
    final query = {'rows': '$rows', 'start': ?start?.toString()};
    final path = '/api/v2/log/${config.logSource.name}/traffic/forward';
    for (var check = 0; check < maxReadyChecks; check++) {
      final FortiGateLogPage page;
      try {
        page = parseFortiGateLogPage(await _get(path, query));
      } on FormatException catch (error) {
        throw FortiGateLogQueryFailure(technicalDetail: error.message);
      }
      if (page.isReady) return page;
      final sessionId = page.sessionId;
      if (sessionId == null) return page;
      query['session_id'] = '$sessionId';
      await _delay(const Duration(seconds: 1));
    }
    throw FortiGateLogQueryFailure(
      technicalDetail:
          'Log araması $maxReadyChecks denemede tamamlanmadı ($path).',
    );
  }

  Future<String> _get(
    String path, [
    Map<String, String> query = const {},
  ]) async {
    final problem = config.validationError;
    if (problem != null) {
      throw FortiGateNotConfiguredFailure(reason: problem);
    }
    final apiKey = (await _credentials.read(providerId))?.token;
    if (apiKey == null || apiKey.isEmpty) {
      throw FortiGateNotConfiguredFailure(
        reason:
            'FortiGate REST API anahtarı kayıtlı değil. Ayarlardan anahtarı '
            'girin; yalnızca macOS Keychain\'de saklanır.',
      );
    }
    final response = await _transport.get(
      config.uri(path, query),
      apiKey: apiKey,
      pinnedCertificateSha256: config.pinnedCertificateSha256,
    );
    final detail = 'GET $path → HTTP ${response.statusCode}';
    switch (response.statusCode) {
      case 200:
        return response.body;
      case 401 || 403:
        throw TrafficProviderAuthFailure(
          technicalDetail:
              '$detail. Anahtar geçersiz, yetkisi eksik veya bu Mac REST '
              'API admin\'in "trusted hosts" listesinde değil.',
        );
      case 429:
        throw TrafficProviderRateLimitedFailure(technicalDetail: detail);
      case 404:
        throw FortiGateLogQueryFailure(
          technicalDetail:
              '$detail. Uç bulunamadı: log kaynağı veya VDOM (${config.vdom}) '
              'hatalı olabilir.',
        );
      default:
        throw TrafficProviderUnreachableFailure(
          technicalDetail: '$detail ${_snippet(response.body)}',
        );
    }
  }

  static String _snippet(String body) {
    final text = body.length > 200 ? '${body.substring(0, 200)}…' : body;
    return const LineSplitter().convert(text).join(' ');
  }
}
