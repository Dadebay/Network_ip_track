/// Non-sensitive traffic settings. Router credentials never live here; they
/// go through [RouterCredentialStore] (macOS Keychain).
class TrafficSettings {
  const TrafficSettings({
    this.providerId = noProviderId,
    this.dailyRetentionDays = 90,
    this.useBinaryUnits = false,
    this.pollInterval = const Duration(minutes: 1),
  });

  /// "Keşif modu": no traffic provider configured.
  static const noProviderId = 'none';

  static const dailyRetentionChoices = [30, 90, 180, 365];

  final String providerId;
  final int dailyRetentionDays;

  /// MiB/GiB (1024²) instead of MB/GB (1000²).
  final bool useBinaryUnits;
  final Duration pollInterval;

  bool get hasProvider => providerId != noProviderId;

  TrafficSettings copyWith({
    String? providerId,
    int? dailyRetentionDays,
    bool? useBinaryUnits,
    Duration? pollInterval,
  }) => TrafficSettings(
    providerId: providerId ?? this.providerId,
    dailyRetentionDays: dailyRetentionDays ?? this.dailyRetentionDays,
    useBinaryUnits: useBinaryUnits ?? this.useBinaryUnits,
    pollInterval: pollInterval ?? this.pollInterval,
  );

  Map<String, Object?> toJson() => {
    'providerId': providerId,
    'dailyRetentionDays': dailyRetentionDays,
    'useBinaryUnits': useBinaryUnits,
    'pollIntervalSeconds': pollInterval.inSeconds,
  };

  factory TrafficSettings.fromJson(Map<String, Object?> json) {
    const defaults = TrafficSettings();
    final pollSeconds = json['pollIntervalSeconds'];
    return TrafficSettings(
      providerId: json['providerId'] as String? ?? defaults.providerId,
      dailyRetentionDays:
          json['dailyRetentionDays'] as int? ?? defaults.dailyRetentionDays,
      useBinaryUnits: json['useBinaryUnits'] as bool? ?? false,
      pollInterval: pollSeconds is int && pollSeconds >= 10
          ? Duration(seconds: pollSeconds)
          : defaults.pollInterval,
    );
  }
}
