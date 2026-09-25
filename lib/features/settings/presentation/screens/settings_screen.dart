import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/theme_mode_controller.dart';
import '../../../../app/widgets/page_layout.dart';
import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../discovery/domain/entities/discovery_method.dart';
import '../../../discovery/domain/entities/scan_settings.dart';
import '../../../discovery/presentation/providers/scan_providers.dart';
import '../../../network_scope/presentation/providers/network_scope_providers.dart';
import '../../../traffic/presentation/screens/traffic_settings_screen.dart';

/// Scan settings (concurrency, timeouts, discovery methods, the limited
/// port list) and the entry to traffic-provider settings.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _maxPorts = ScanSettings.maxLimitedPorts;

  late final _portsController = TextEditingController(
    text: ref.read(scanSettingsProvider).limitedPorts.join(', '),
  );

  @override
  void initState() {
    super.initState();
    // Stored settings load asynchronously; keep the field in sync until
    // the user starts editing it.
    ref.listenManual(scanSettingsProvider, (previous, next) {
      if (_portsError == null &&
          previous?.limitedPorts.join(', ') == _portsController.text) {
        _portsController.text = next.limitedPorts.join(', ');
      }
    });
  }

  String? _portsError;

  @override
  void dispose() {
    _portsController.dispose();
    super.dispose();
  }

  void _update(ScanSettings Function(ScanSettings) change) {
    final notifier = ref.read(scanSettingsProvider.notifier);
    notifier.set(change(ref.read(scanSettingsProvider)));
  }

  void _savePorts() {
    final parts = _portsController.text
        .split(RegExp(r'[,\s]+'))
        .where((part) => part.isNotEmpty);
    final ports = <int>{};
    for (final part in parts) {
      final port = int.tryParse(part);
      if (port == null || port < 1 || port > 65535) {
        setState(
          () => _portsError = '"$part" geçerli bir port değil (1-65535).',
        );
        return;
      }
      ports.add(port);
    }
    if (ports.length > _maxPorts) {
      setState(
        () => _portsError =
            'En fazla $_maxPorts port: bu yalnızca sınıflandırma içindir, '
            'kapsamlı port taraması yapılmaz.',
      );
      return;
    }
    setState(() => _portsError = null);
    _update((s) => s.copyWith(limitedPorts: ports.toList()..sort()));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Port listesi kaydedildi.')));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(scanSettingsProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: PageListView(
        maxContentWidth: 880,
        children: [
          PageSection(
            title: 'Görünüm',
            subtitle: 'Uygulamanın açık veya koyu temada görünmesi.',
            child: SurfaceCard(
              child: Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('Sistem'),
                      icon: ThemedHugeIcon(
                        HugeIcons.strokeRoundedComputerSettings,
                        size: 16,
                      ),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Açık'),
                      icon: ThemedHugeIcon(
                        HugeIcons.strokeRoundedSun03,
                        size: 16,
                      ),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Koyu'),
                      icon: ThemedHugeIcon(
                        HugeIcons.strokeRoundedMoon02,
                        size: 16,
                      ),
                    ),
                  ],
                  selected: {ref.watch(themeModeProvider)},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) => ref
                      .read(themeModeProvider.notifier)
                      .set(selection.single),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          PageSection(
            title: 'Tarama',
            subtitle:
                'Ayarlar kaydedilir ve yeni başlatılan taramalara uygulanır; '
                'devam ettirilen taramalar başladıkları ayarlarla sürer.',
            child: SurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Column(
                children: [
                  _SliderSetting(
                    label: 'Eşzamanlı yoklama',
                    description:
                        'Bir alt ağ içinde aynı anda yoklanan adres sayısı.',
                    valueLabel: '${settings.concurrency}',
                    value: settings.concurrency.toDouble(),
                    min: 1,
                    max: 32,
                    divisions: 31,
                    onChanged: (value) =>
                        _update((s) => s.copyWith(concurrency: value.round())),
                  ),
                  const Divider(height: 1),
                  _SliderSetting(
                    label: 'Eşzamanlı alt ağ',
                    description:
                        'Aynı anda taranan /24 alt ağ sayısı. Büyük '
                        'kapsamlarda (ör. tüm 172.16.0.0/12 bloğu) bunu '
                        'artırmak taramayı orantılı hızlandırır.',
                    valueLabel: '${settings.chunkConcurrency}',
                    value: settings.chunkConcurrency.toDouble(),
                    min: 1,
                    max: 16,
                    divisions: 15,
                    onChanged: (value) => _update(
                      (s) => s.copyWith(chunkConcurrency: value.round()),
                    ),
                  ),
                  const Divider(height: 1),
                  _SliderSetting(
                    label: 'Ping zaman aşımı',
                    description:
                        'Cevap vermeyen bir adres için ping bekleme süresi.',
                    valueLabel: '${settings.pingTimeout.inMilliseconds} ms',
                    value: settings.pingTimeout.inMilliseconds.toDouble(),
                    min: 200,
                    max: 3000,
                    divisions: 28,
                    onChanged: (value) => _update(
                      (s) => s.copyWith(
                        pingTimeout: Duration(milliseconds: value.round()),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  _SliderSetting(
                    label: 'Port zaman aşımı',
                    description: 'Port kontrolünde bağlantı başına bekleme.',
                    valueLabel:
                        '${settings.portProbeTimeout.inMilliseconds} ms',
                    value: settings.portProbeTimeout.inMilliseconds.toDouble(),
                    min: 200,
                    max: 3000,
                    divisions: 28,
                    onChanged: (value) => _update(
                      (s) => s.copyWith(
                        portProbeTimeout: Duration(milliseconds: value.round()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          PageSection(
            title: 'Keşif yöntemleri',
            subtitle: 'Taramada cihazları bulmak ve tanımak için kullanılır.',
            child: SurfaceCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final method in DiscoveryMethod.values)
                    FilterChip(
                      label: Text(method.label),
                      selected: settings.methods.contains(method),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      onSelected: (selected) => _update(
                        (s) => s.copyWith(
                          methods: selected
                              ? {...s.methods, method}
                              : ({...s.methods}..remove(method)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          PageSection(
            title: 'Sınırlı port listesi',
            subtitle:
                'Yalnızca cihaz türü tahmini için bağlantı denemesi yapılır; '
                'veri gönderilmez.',
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _portsController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      helperText: 'Virgülle ayırın. En fazla $_maxPorts port.',
                      errorText: _portsError,
                    ),
                    onSubmitted: (_) => _savePorts(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () {
                          _portsController.text = const ScanSettings()
                              .limitedPorts
                              .join(', ');
                          _savePorts();
                        },
                        child: const Text('Varsayılana dön'),
                      ),
                      FilledButton(
                        onPressed: _savePorts,
                        child: const Text('Portları kaydet'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const _DiagnosticsSection(),
          const SizedBox(height: 28),
          PageSection(
            title: 'Trafik',
            child: SurfaceCard(
              padding: EdgeInsets.zero,
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TrafficSettingsScreen(),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const IconBadge(
                          icon: HugeIcons.strokeRoundedChartLineData01,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Trafik kaynağı',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Keşif modu veya router entegrasyonu, bağlantı '
                                'testi, saklama süresi ve MB/MiB tercihi',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ThemedHugeIcon(
                          HugeIcons.strokeRoundedArrowRight01,
                          size: 18,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.description,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String description;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                constraints: const BoxConstraints(minWidth: 64),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  valueLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              tickMarkShape: SliderTickMarkShape.noTickMark,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              label: valueLabel,
              semanticFormatterCallback: (_) => '$label $valueLabel',
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Runs each discovery tool once against the gateway from inside the app,
/// to explain why a scan found less than expected.
class _DiagnosticsSection extends ConsumerStatefulWidget {
  const _DiagnosticsSection();

  @override
  ConsumerState<_DiagnosticsSection> createState() =>
      _DiagnosticsSectionState();
}

class _DiagnosticsSectionState extends ConsumerState<_DiagnosticsSection> {
  bool _running = false;
  String? _report;

  Future<void> _run() async {
    setState(() {
      _running = true;
      _report = null;
    });
    String report;
    try {
      // Detect directly: an autoDispose provider read without a listener
      // would be disposed mid-await.
      final snapshot = await ref.read(detectNetworkScopeUseCaseProvider)();
      final target =
          snapshot.activeInterface?.gatewayAddress ??
          snapshot.activeInterface?.address;
      report = target == null
          ? 'Aktif ağ arayüzü bulunamadı.'
          : await ref.read(networkDiagnosticsProvider).run(target);
    } catch (error) {
      report = 'Tanılama çalıştırılamadı: $error';
    }
    if (mounted) {
      setState(() {
        _running = false;
        _report = report;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PageSection(
      title: 'Ağ tanılama',
      subtitle:
          'Taramanın kullandığı araçları (ping, ARP, reverse DNS, mDNS) '
          'gateway\'e karşı bir kez çalıştırır. Tarama beklenenden az bilgi '
          'bulduysa nedenini gösterir.',
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const IconBadge(icon: HugeIcons.strokeRoundedStethoscope),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _report == null
                        ? 'Gateway\'e karşı tek seferlik kontrol'
                        : 'Son tanılama sonucu',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: _running ? null : _run,
                  icon: _running
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const ThemedHugeIcon(
                          HugeIcons.strokeRoundedPlay,
                          size: 16,
                        ),
                  label: Text(
                    _running ? 'Çalışıyor…' : 'Ağ tanılamayı çalıştır',
                  ),
                ),
              ],
            ),
            if (_report != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  _report!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'Menlo',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
