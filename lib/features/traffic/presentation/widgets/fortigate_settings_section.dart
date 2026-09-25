import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/themed_huge_icon.dart';
import '../../../../core/errors/app_failure.dart';
import '../../domain/entities/fortigate_config.dart';
import '../../domain/entities/router_credentials.dart';
import '../../infrastructure/fortigate/fortigate_traffic_provider.dart';
import '../providers/traffic_providers.dart';

/// FortiGate connection settings: address, VDOM, log source and the REST
/// API key (saved only to the Keychain), plus what to ask the firewall
/// administrator for.
class FortiGateSettingsSection extends ConsumerStatefulWidget {
  const FortiGateSettingsSection({super.key});

  @override
  ConsumerState<FortiGateSettingsSection> createState() =>
      _FortiGateSettingsSectionState();
}

class _FortiGateSettingsSectionState
    extends ConsumerState<FortiGateSettingsSection> {
  final _host = TextEditingController();
  final _port = TextEditingController();
  final _vdom = TextEditingController();
  final _apiKey = TextEditingController();
  FortiGateLogSource _logSource = FortiGateLogSource.memory;
  bool _loaded = false;
  bool _saving = false;
  bool? _hasKey;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _refreshKeyState();
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    _vdom.dispose();
    _apiKey.dispose();
    super.dispose();
  }

  Future<void> _refreshKeyState() async {
    try {
      final stored = await ref
          .read(routerCredentialStoreProvider)
          .read(FortiGateTrafficProvider.providerId);
      if (mounted) setState(() => _hasKey = stored?.token?.isNotEmpty ?? false);
    } catch (_) {
      if (mounted) setState(() => _hasKey = false);
    }
  }

  void _fill(FortiGateConfig config) {
    if (_loaded) return;
    _loaded = true;
    _host.text = config.host;
    _port.text = '${config.port}';
    _vdom.text = config.vdom;
    _logSource = config.logSource;
  }

  FortiGateConfig _configFromFields(FortiGateConfig current) =>
      current.copyWith(
        host: _host.text.trim(),
        port: int.tryParse(_port.text.trim()) ?? -1,
        vdom: _vdom.text.trim(),
        logSource: _logSource,
      );

  Future<void> _save(FortiGateConfig current) async {
    final config = _configFromFields(current);
    final problem = config.validationError;
    if (problem != null) {
      setState(() {
        _error = problem;
        _notice = null;
      });
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(fortiGateConfigProvider.notifier).save(config);
      final key = _apiKey.text.trim();
      if (key.isNotEmpty) {
        await ref
            .read(routerCredentialStoreProvider)
            .save(
              FortiGateTrafficProvider.providerId,
              RouterCredentials(token: key),
            );
        _apiKey.clear();
      }
      await _refreshKeyState();
      if (mounted) {
        setState(
          () => _notice = key.isEmpty
              ? 'Ayarlar kaydedildi.'
              : 'Ayarlar kaydedildi; API anahtarı Keychain\'e yazıldı.',
        );
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _error = asAppFailure(error, stackTrace).userMessage);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteKey() async {
    try {
      await ref
          .read(routerCredentialStoreProvider)
          .delete(FortiGateTrafficProvider.providerId);
      await _refreshKeyState();
      if (mounted) {
        setState(() => _notice = 'API anahtarı Keychain\'den silindi.');
      }
    } catch (error, stackTrace) {
      if (mounted) {
        setState(() => _error = asAppFailure(error, stackTrace).userMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final configAsync = ref.watch(fortiGateConfigProvider);
    final config = configAsync.value;
    if (config == null) return const LinearProgressIndicator();
    _fill(config);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FortiGate bağlantısı', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _host,
                decoration: const InputDecoration(
                  labelText: 'Adres',
                  hintText: '172.16.14.254',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _port,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'HTTPS port',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _vdom,
                decoration: const InputDecoration(
                  labelText: 'VDOM',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Log kaynağı'),
            const SizedBox(width: 12),
            SegmentedButton<FortiGateLogSource>(
              segments: [
                for (final source in FortiGateLogSource.values)
                  ButtonSegment(value: source, label: Text(source.label)),
              ],
              selected: {_logSource},
              onSelectionChanged: (selection) =>
                  setState(() => _logSource = selection.single),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _apiKey,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'REST API anahtarı',
            helperText: switch (_hasKey) {
              true =>
                'Keychain\'de kayıtlı bir anahtar var. Değiştirmek için yenisini '
                    'girin.',
              false => 'Anahtar yalnızca macOS Keychain\'de saklanır.',
              null => null,
            },
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: ThemedHugeIcon(HugeIcons.strokeRoundedKey01, size: 18),
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        if (config.pinnedCertificateSha256 != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ThemedHugeIcon(
                  HugeIcons.strokeRoundedCertificate01,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SelectableText(
                    'Güvenilen sertifika (SHA-256): '
                    '${config.pinnedCertificateSha256}',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton(
              onPressed: _saving ? null : () => _save(config),
              child: const Text('Kaydet'),
            ),
            if (_hasKey ?? false)
              TextButton(
                onPressed: _saving ? null : _deleteKey,
                child: const Text('Anahtarı sil'),
              ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _error!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_notice!, style: theme.textTheme.bodySmall),
          ),
        const SizedBox(height: 16),
        const _AdminChecklist(),
      ],
    );
  }
}

/// What the user needs from the FortiGate administrator.
class _AdminChecklist extends StatelessWidget {
  const _AdminChecklist();

  static const _items = [
    'FortiOS sürümü (System > Dashboard).',
    'Salt okunur bir REST API yöneticisi (System > Administrators > Create '
        'New > REST API Admin). Yönetici profilinde "Log & Report" için '
        'okuma izni yeterli.',
    '"Trusted Hosts" listesine bu Mac\'in adresi (ör. 172.16.14.26/32).',
    'Oluşturulan API anahtarı (yalnızca bir kez gösterilir).',
    'LAN→internet politikalarında "Log Allowed Traffic: All Sessions" açık '
        'olmalı; yoksa oturum logu, dolayısıyla cihaz başına trafik oluşmaz.',
    'Logların nerede tutulduğu: bellek, disk, ya da yalnızca FortiAnalyzer/'
        'FortiGate Cloud (bu son durumda bu uygulama logları okuyamaz).',
    'HTTPS yönetim portu 443 değilse port numarası.',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ThemedHugeIcon(
                HugeIcons.strokeRoundedFirewall,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Güvenlik duvarı yöneticisinden istenecekler',
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final (index, item) in _items.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '${index + 1}. $item',
                style: theme.textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Uygulama yalnızca okuma yapar: yapılandırmayı değiştirmez, oturum '
            'açmaz, parola denemez.',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
