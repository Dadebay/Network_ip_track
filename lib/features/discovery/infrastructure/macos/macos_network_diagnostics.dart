import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/platform/mac_process_runner.dart';
import '../../../../core/utils/ipv4_address.dart';
import '../../domain/repositories/network_diagnostics.dart';
import '../../domain/repositories/ping_provider.dart';

/// [NetworkDiagnostics] for macOS: the same commands the scan uses, run
/// once each. The report is also written to `diagnostics.txt` in the app
/// support directory.
class MacosNetworkDiagnostics implements NetworkDiagnostics {
  const MacosNetworkDiagnostics({
    required this.ping,
    this.processRunner = const MacProcessRunner(),
  });

  /// The ping the scan actually uses (in-process ICMP).
  final PingProvider ping;
  final MacProcessRunner processRunner;

  @override
  Future<String> run(Ipv4Address target) async {
    final ip = target.toString();
    final report = StringBuffer()
      ..writeln('Ağ tanılama · ${DateTime.now().toIso8601String()}')
      ..writeln('Hedef: $ip')
      ..writeln(
        'Sandbox: ${Platform.environment['APP_SANDBOX_CONTAINER_ID'] ?? 'yok'}',
      )
      ..writeln('PATH: ${Platform.environment['PATH']}')
      ..writeln();

    Future<void> step(
      String title,
      String executable,
      List<String> arguments, {
      Duration timeout = const Duration(seconds: 5),
    }) async {
      report.writeln('── $title: $executable ${arguments.join(' ')}');
      try {
        final result = await processRunner.run(
          executable,
          arguments,
          timeout: timeout,
        );
        report
          ..writeln('çıkış kodu: ${result.exitCode}')
          ..writeln('stdout: ${_trim(result.stdout)}')
          ..writeln('stderr: ${_trim(result.stderr)}');
      } on Object catch (error) {
        report.writeln('başlatılamadı: $error');
      }
      report.writeln();
    }

    report.writeln('── ICMP ping (uygulama içi, taramanın kullandığı)');
    try {
      final reply = await ping.ping(
        target,
        timeout: const Duration(milliseconds: 800),
      );
      report.writeln(
        reply == null
            ? 'yanıt yok'
            : 'yanıt: TTL ${reply.ttl ?? '?'}, '
                  '${reply.roundTrip?.inMicroseconds ?? '?'} µs',
      );
    } on Object catch (error) {
      report.writeln('hata: $error');
    }
    report.writeln();
    await step('ICMP ping (harici /sbin/ping, karşılaştırma)', '/sbin/ping', [
      '-n',
      '-c',
      '1',
      '-W',
      '800',
      ip,
    ]);
    await step('ARP', 'arp', ['-n', ip]);
    await step('Reverse DNS', 'dscacheutil', [
      '-q',
      'host',
      '-a',
      'ip_address',
      ip,
    ]);

    report.writeln('── mDNS: dns-sd -B _services._dns-sd._udp local. (3 sn)');
    try {
      final raw = await processRunner.runStreaming('dns-sd', [
        '-B',
        '_services._dns-sd._udp',
        'local.',
      ], collectFor: const Duration(seconds: 3));
      final adds = raw.split('\n').where((l) => l.contains(' Add ')).length;
      report
        ..writeln('bulunan servis türü satırı: $adds')
        ..writeln(_trim(raw));
    } on Object catch (error) {
      report.writeln('başlatılamadı: $error');
    }

    final text = report.toString();
    try {
      final dir = await getApplicationSupportDirectory();
      await File(p.join(dir.path, 'diagnostics.txt')).writeAsString(text);
    } on Object {
      // The on-screen report is what matters.
    }
    return text;
  }

  static String _trim(String value) {
    final text = value.trim();
    if (text.isEmpty) return '(boş)';
    return text.length > 1500 ? '${text.substring(0, 1500)}…' : text;
  }
}
