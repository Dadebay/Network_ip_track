import 'discovery_method.dart';

/// User-adjustable scan parameters. Defaults are intentionally conservative
/// per the spec ("Varsayılan concurrency düşük ve ayarlanabilir olsun").
class ScanSettings {
  const ScanSettings({
    this.concurrency = 8,
    this.chunkConcurrency = 4,
    this.pingTimeout = const Duration(milliseconds: 800),
    this.portProbeTimeout = const Duration(milliseconds: 500),
    this.methods = const {
      DiscoveryMethod.arpTable,
      DiscoveryMethod.icmpPing,
      DiscoveryMethod.reverseDns,
      DiscoveryMethod.mdns,
      DiscoveryMethod.ssdp,
      DiscoveryMethod.netbios,
      DiscoveryMethod.limitedPortScan,
      DiscoveryMethod.httpBanner,
      DiscoveryMethod.wsDiscovery,
    },
    this.limitedPorts = const [
      22,
      53,
      80,
      139,
      443,
      445,
      548,
      631,
      8008,
      8009,
      8080,
      9100,
    ],
  });

  final int concurrency;

  /// How many `/24` chunks the sweep works on at once. Total simultaneous
  /// probes is roughly `concurrency × chunkConcurrency`, so raising this is
  /// what actually shortens a large scope like the full `172.16.0.0/12`
  /// block — scanning one subnet at a time is why that estimate can run
  /// into days.
  final int chunkConcurrency;

  final Duration pingTimeout;
  final Duration portProbeTimeout;
  final Set<DiscoveryMethod> methods;
  final List<int> limitedPorts;

  ScanSettings copyWith({
    int? concurrency,
    int? chunkConcurrency,
    Duration? pingTimeout,
    Duration? portProbeTimeout,
    Set<DiscoveryMethod>? methods,
    List<int>? limitedPorts,
  }) {
    return ScanSettings(
      concurrency: concurrency ?? this.concurrency,
      chunkConcurrency: chunkConcurrency ?? this.chunkConcurrency,
      pingTimeout: pingTimeout ?? this.pingTimeout,
      portProbeTimeout: portProbeTimeout ?? this.portProbeTimeout,
      methods: methods ?? this.methods,
      limitedPorts: limitedPorts ?? this.limitedPorts,
    );
  }

  Map<String, dynamic> toJson() => {
    'concurrency': concurrency,
    'chunkConcurrency': chunkConcurrency,
    'pingTimeoutMs': pingTimeout.inMilliseconds,
    'portProbeTimeoutMs': portProbeTimeout.inMilliseconds,
    'methods': [for (final method in methods) method.name],
    // Methods that existed when this was saved: ones added later are
    // enabled by default on load instead of silently staying off.
    'knownMethods': [for (final method in DiscoveryMethod.values) method.name],
    'limitedPorts': limitedPorts,
  };

  factory ScanSettings.fromJson(Map<String, dynamic> json) => ScanSettings(
    concurrency: json['concurrency'] as int,
    // Settings saved before this field existed: fall back to the same
    // conservative default a fresh install gets, not to the old
    // one-chunk-at-a-time behavior that made a full /12 scan take days.
    chunkConcurrency: json['chunkConcurrency'] as int? ?? 4,
    pingTimeout: Duration(milliseconds: json['pingTimeoutMs'] as int),
    portProbeTimeout: Duration(milliseconds: json['portProbeTimeoutMs'] as int),
    methods: {
      for (final name in (json['methods'] as List).cast<String>())
        DiscoveryMethod.values.byName(name),
      for (final method in const ScanSettings().methods)
        if (!((json['knownMethods'] as List?)?.contains(method.name) ??
            _methodsBeforeKnownList.contains(method.name)))
          method,
    },
    limitedPorts: (json['limitedPorts'] as List).cast<int>(),
  );

  /// Method names that existed before settings recorded `knownMethods`.
  static const _methodsBeforeKnownList = {
    'arpTable',
    'icmpPing',
    'reverseDns',
    'mdns',
    'ssdp',
    'netbios',
    'limitedPortScan',
  };

  static const maxConcurrency = 32;
  static const maxChunkConcurrency = 16;
  static const maxLimitedPorts = 32;
  static const minTimeout = Duration(milliseconds: 200);
  static const maxTimeout = Duration(milliseconds: 3000);

  /// These settings pulled back inside the limits the settings screen
  /// allows — applied to anything read from disk, so an edited or corrupt
  /// file can't raise concurrency or turn the port check into a port scan.
  ScanSettings sanitized() {
    Duration clampTimeout(Duration value) => Duration(
      milliseconds: value.inMilliseconds.clamp(
        minTimeout.inMilliseconds,
        maxTimeout.inMilliseconds,
      ),
    );
    return ScanSettings(
      concurrency: concurrency.clamp(1, maxConcurrency),
      chunkConcurrency: chunkConcurrency.clamp(1, maxChunkConcurrency),
      pingTimeout: clampTimeout(pingTimeout),
      portProbeTimeout: clampTimeout(portProbeTimeout),
      methods: methods,
      limitedPorts: {
        for (final port in limitedPorts)
          if (port >= 1 && port <= 65535) port,
      }.take(maxLimitedPorts).toList()..sort(),
    );
  }
}
