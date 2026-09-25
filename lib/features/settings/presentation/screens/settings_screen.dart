import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Ayarlar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Tarama', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Ayarlar kaydedilir ve yeni başlatılan taramalara uygulanır; '
            'devam ettirilen taramalar başladıkları ayarlarla sürer.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _SliderSetting(
            label: 'Eşzamanlı yoklama',
            valueLabel: '${settings.concurrency}',
            value: settings.concurrency.toDouble(),
            min: 1,
            max: 32,
            divisions: 31,
            onChanged: (value) =>
                _update((s) => s.copyWith(concurrency: value.round())),
          ),
          _SliderSetting(
            label: 'Eşzamanlı alt ağ',
            valueLabel: '${settings.chunkConcurrency}',
            value: settings.chunkConcurrency.toDouble(),
            min: 1,
            max: 16,
            divisions: 15,
            onChanged: (value) =>
                _update((s) => s.copyWith(chunkConcurrency: value.round())),
          ),
          Text(
            'Aynı anda taranan /24 alt ağ sayısı. Büyük kapsamlarda (ör. tüm '
            '172.16.0.0/12 bloğu) bunu artırmak taramayı orantılı hızlandırır.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          _SliderSetting(
            label: 'Ping zaman aşımı',
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
          _SliderSetting(
            label: 'Port zaman aşımı',
            valueLabel: '${settings.portProbeTimeout.inMilliseconds} ms',
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
          const SizedBox(height: 16),
          Text('Keşif yöntemleri', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final method in DiscoveryMethod.values)
                FilterChip(
                  label: Text(method.label),
                  selected: settings.methods.contains(method),
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
          const SizedBox(height: 24),
          Text('Sınırlı port listesi', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _portsController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              helperText:
                  'Virgülle ayırın. Yalnızca cihaz türü tahmini için bağlantı '
                  'denemesi yapılır; veri gönderilmez.',
              errorText: _portsError,
            ),
            onSubmitted: (_) => _savePorts(),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: _savePorts,
                  child: const Text('Portları kaydet'),
                ),
                TextButton(
                  onPressed: () {
                    _portsController.text = const ScanSettings().limitedPorts
                        .join(', ');
                    _savePorts();
                  },
                  child: const Text('Varsayılana dön'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _DiagnosticsSection(),
          const SizedBox(height: 24),
          Text('Trafik', style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Card(
            child: ListTile(
              title: const Text('Trafik kaynağı'),
              subtitle: const Text(
                'Keşif modu veya router entegrasyonu, bağlantı testi, saklama '
                'süresi ve MB/MiB tercihi',
              ),
              trailing: const ThemedHugeIcon(
                HugeIcons.strokeRoundedArrowRight01,
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TrafficSettingsScreen(),
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
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 180, child: Text(label)),
        Expanded(
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
        SizedBox(width: 80, child: Text(valueLabel, textAlign: TextAlign.end)),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ağ tanılama', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Taramanın kullandığı araçları (ping, ARP, reverse DNS, mDNS) '
          'gateway\'e karşı bir kez çalıştırır ve sonuçları gösterir. Tarama '
          'beklenenden az bilgi bulduysa nedenini gösterir.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _running ? null : _run,
          child: Text(_running ? 'Çalışıyor…' : 'Ağ tanılamayı çalıştır'),
        ),
        if (_report != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _report!,
              style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'Menlo'),
            ),
          ),
        ],
      ],
    );
  }
}
