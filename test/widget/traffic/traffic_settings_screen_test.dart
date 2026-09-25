import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/database/app_database.dart';
import 'package:network_monitor/features/network_scope/presentation/providers/network_scope_providers.dart';
import 'package:network_monitor/features/traffic/domain/entities/traffic_settings.dart';
import 'package:network_monitor/features/traffic/domain/repositories/traffic_settings_repository.dart';
import 'package:network_monitor/features/traffic/presentation/providers/traffic_providers.dart';
import 'package:network_monitor/features/traffic/presentation/screens/traffic_settings_screen.dart';

class _MemorySettingsRepository implements TrafficSettingsRepository {
  TrafficSettings settings = const TrafficSettings();

  @override
  Future<TrafficSettings> load() async => settings;

  @override
  Future<void> save(TrafficSettings settings) async => this.settings = settings;
}

void main() {
  testWidgets('selects the demo provider and runs a connection test', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final settingsRepository = _MemorySettingsRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          // No real network detection in tests.
          currentNetworkLookupProvider.overrideWithValue(() async => null),
          trafficSettingsRepositoryProvider.overrideWithValue(
            settingsRepository,
          ),
          trafficClockProvider.overrideWithValue(
            () => DateTime(2026, 9, 24, 12),
          ),
        ],
        child: const MaterialApp(home: TrafficSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Starts in Keşif modu: nothing to test.
    expect(find.text('Keşif modu'), findsOneWidget);
    expect(
      find.text('Keşif modunda test edilecek bir trafik kaynağı yok.'),
      findsOneWidget,
    );
    expect(find.text('Demo (simüle veri)'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('traffic-provider-demo')));
    await tester.pumpAndSettle();
    expect(settingsRepository.settings.providerId, 'demo');

    // FortiGate is listed too, so the button may be below the fold.
    await tester.ensureVisible(find.text('Bağlantıyı test et'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bağlantıyı test et'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Demo sağlayıcı hazır'), findsOneWidget);
    expect(find.text('0 cihaz için sayaç bulundu.'), findsOneWidget);

    // Back to Keşif modu.
    await tester.ensureVisible(find.text('Keşif modu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keşif modu'));
    await tester.pumpAndSettle();
    expect(
      settingsRepository.settings.providerId,
      TrafficSettings.noProviderId,
    );

    // Dispose the scope so the polling timer is cancelled.
    await tester.pumpWidget(const SizedBox());
  });
}
