import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/discovery/domain/entities/discovery_method.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_settings.dart';
import 'package:network_monitor/features/discovery/infrastructure/settings/file_scan_settings_repository.dart';

void main() {
  late Directory directory;
  late FileScanSettingsRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('scan_settings_test');
    repository = FileScanSettingsRepository(directory: () async => directory);
  });

  tearDown(() => directory.delete(recursive: true));

  File settingsFile() => File('${directory.path}/scan_settings.json');

  test('defaults when nothing is stored', () async {
    final loaded = await repository.load();
    expect(loaded.concurrency, const ScanSettings().concurrency);
  });

  test('round-trips saved settings', () async {
    await repository.save(
      const ScanSettings(
        concurrency: 4,
        pingTimeout: Duration(milliseconds: 1200),
        methods: {DiscoveryMethod.arpTable, DiscoveryMethod.icmpPing},
        limitedPorts: [443, 22],
      ),
    );
    final loaded = await repository.load();
    expect(loaded.concurrency, 4);
    expect(loaded.pingTimeout, const Duration(milliseconds: 1200));
    expect(loaded.methods, {
      DiscoveryMethod.arpTable,
      DiscoveryMethod.icmpPing,
    });
    expect(loaded.limitedPorts, [22, 443]);
  });

  test('an edited file cannot exceed the allowed limits', () async {
    await settingsFile().writeAsString('''
      {"concurrency": 5000, "pingTimeoutMs": 1, "portProbeTimeoutMs": 99999,
       "methods": ["icmpPing"],
       "limitedPorts": ${List.generate(1000, (i) => i + 1)}}
    ''');
    final loaded = await repository.load();
    expect(loaded.concurrency, ScanSettings.maxConcurrency);
    expect(loaded.pingTimeout, ScanSettings.minTimeout);
    expect(loaded.portProbeTimeout, ScanSettings.maxTimeout);
    expect(loaded.limitedPorts, hasLength(ScanSettings.maxLimitedPorts));
  });

  test('a corrupt file falls back to defaults', () async {
    await settingsFile().writeAsString(
      '{"concurrency": "fast", "methods": ["warp"]',
    );
    expect(
      (await repository.load()).concurrency,
      const ScanSettings().concurrency,
    );
    await settingsFile().writeAsString(
      '{"concurrency": 4, "pingTimeoutMs": 800, "portProbeTimeoutMs": 500, '
      '"methods": ["warp"], "limitedPorts": []}',
    );
    expect(
      (await repository.load()).concurrency,
      const ScanSettings().concurrency,
    );
  });

  test(
    'rapid unawaited saves land in order; the newest wins, no temp left',
    () async {
      final saves = [
        for (var concurrency = 1; concurrency <= 20; concurrency++)
          repository.save(ScanSettings(concurrency: concurrency)),
      ];
      await Future.wait(saves);

      expect((await repository.load()).concurrency, 20);
      final leftovers = directory.listSync().where(
        (entry) => entry.path.endsWith('.tmp'),
      );
      expect(leftovers, isEmpty);
    },
  );
}
