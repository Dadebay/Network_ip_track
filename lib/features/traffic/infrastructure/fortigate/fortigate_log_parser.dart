import 'dart:convert';

import '../../domain/entities/traffic_device_identity.dart';
import '../../domain/entities/traffic_usage_batch.dart';

/// One page of a FortiOS log query (`GET /api/v2/log/<source>/traffic/
/// forward`). The query runs asynchronously on the FortiGate: until
/// [isReady], the same request (with [sessionId]) must be repeated.
class FortiGateLogPage {
  const FortiGateLogPage({
    required this.rows,
    required this.isReady,
    this.sessionId,
    this.start,
    this.rowsRequested,
  });

  final List<Map<String, Object?>> rows;
  final bool isReady;
  final int? sessionId;
  final int? start;
  final int? rowsRequested;
}

int? _asInt(Object? value) => switch (value) {
  final int v => v,
  final double v => v.round(),
  final String v => int.tryParse(v.trim()),
  _ => null,
};

/// Parses a log query response. Throws [FormatException] for anything that
/// isn't a FortiOS log response.
FortiGateLogPage parseFortiGateLogPage(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Log yanıtı bir JSON nesnesi değil');
  }
  final results = decoded['results'];
  if (results is! List) {
    throw const FormatException('Log yanıtında "results" listesi yok');
  }
  final completed = _asInt(decoded['completed']);
  final ready = decoded['ready'];
  return FortiGateLogPage(
    rows: [
      for (final row in results)
        if (row is Map<String, Object?>) row,
    ],
    // Either flag may be absent depending on FortiOS version; a response
    // without them is a finished query.
    isReady: ready is bool ? ready : (completed == null || completed >= 100),
    sessionId: _asInt(decoded['session_id']),
    start: _asInt(decoded['start']),
    rowsRequested: _asInt(decoded['rows']),
  );
}

/// `eventtime` is nanoseconds on current FortiOS builds and seconds (or
/// milli/microseconds) on older ones; infer the unit from its magnitude.
DateTime? fortiGateEventTime(Object? raw) {
  final value = _asInt(raw);
  if (value == null || value <= 0) return null;
  if (value > 100000000000000000) {
    return DateTime.fromMicrosecondsSinceEpoch(value ~/ 1000);
  }
  if (value > 100000000000000) {
    return DateTime.fromMicrosecondsSinceEpoch(value);
  }
  if (value > 100000000000) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return DateTime.fromMillisecondsSinceEpoch(value * 1000);
}

const _skippedActions = {'deny', 'start', 'dns', 'ip-conn'};

/// Turns forward-traffic log rows into per-device usage records, from the
/// session originator's (`srcip`/`srcmac`) point of view: `sentbyte` is its
/// upload, `rcvdbyte` its download.
///
/// - Rows with `sentdelta`/`rcvddelta` are interim or close logs of a
///   session that already reported interim statistics: only the delta is
///   counted, so a session is never counted twice. They are placed at their
///   event time.
/// - Other rows carry the session total, spread over
///   `[eventtime − duration, eventtime]`.
/// - Denied/start/zero-byte rows and rows without a usable time or source
///   are skipped.
List<ProviderUsageRecord> fortiGateUsageRecords(
  Iterable<Map<String, Object?>> rows,
) {
  final records = <ProviderUsageRecord>[];
  for (final row in rows) {
    final action = (row['action'] as String?)?.toLowerCase();
    if (action != null && _skippedActions.contains(action)) continue;

    final end = fortiGateEventTime(row['eventtime']);
    if (end == null) continue;
    final identity = TrafficDeviceIdentity.tryCreate(
      macAddress: row['srcmac'] as String?,
      ipAddress: row['srcip'] as String?,
    );
    if (identity == null) continue;

    final hasDelta =
        row.containsKey('sentdelta') || row.containsKey('rcvddelta');
    final upload = _asInt(hasDelta ? row['sentdelta'] : row['sentbyte']) ?? 0;
    final download = _asInt(hasDelta ? row['rcvddelta'] : row['rcvdbyte']) ?? 0;
    if (upload <= 0 && download <= 0) continue;

    final durationSeconds = hasDelta ? 1 : (_asInt(row['duration']) ?? 0);
    final start = end.subtract(
      Duration(seconds: durationSeconds < 1 ? 1 : durationSeconds),
    );
    records.add(
      ProviderUsageRecord(
        key:
            '${row['sessionid'] ?? '?'}|${row['eventtime']}|'
            '${row['logid'] ?? ''}',
        identity: identity,
        periodStart: start,
        periodEnd: end,
        downloadBytes: download,
        uploadBytes: upload,
      ),
    );
  }
  return records;
}

/// `GET /api/v2/monitor/system/status` → a one-line description, e.g.
/// "FGT60F · FortiOS v7.2.5 build1517 · FGT60FTK20000000".
String describeFortiGateStatus(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('Durum yanıtı bir JSON nesnesi değil');
  }
  final results = decoded['results'];
  final model = results is Map<String, Object?>
      ? (results['model'] ?? results['model_name'] ?? results['hostname'])
      : null;
  final version = decoded['version'];
  final build = decoded['build'];
  return [
    model ?? 'FortiGate',
    if (version != null)
      'FortiOS $version${build != null ? ' build$build' : ''}',
    ?decoded['serial'] as String?,
  ].join(' · ');
}
