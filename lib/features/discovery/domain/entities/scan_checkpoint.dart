import 'dart:convert';

import 'scan_chunk.dart';
import 'scan_plan.dart';
import 'scan_scope_type.dart';
import 'scan_settings.dart';

/// Everything needed to continue a scan later — including after an app
/// restart — stored in `scan_sessions.checkpoint_json`. This is the
/// persisted queue: each chunk's status plus its resume offset.
class ScanCheckpoint {
  const ScanCheckpoint({
    required this.scopeType,
    required this.settings,
    required this.chunks,
    this.candidatePassDone = false,
    this.candidatesProbed = const {},
  });

  factory ScanCheckpoint.fromPlan(ScanPlan plan) => ScanCheckpoint(
    scopeType: plan.scopeType,
    settings: plan.settings,
    chunks: plan.chunks,
  );

  final ScanScopeType scopeType;
  final ScanSettings settings;
  final List<ScanChunk> chunks;

  /// True once the up-front pass over known candidates (ARP table, mDNS,
  /// SSDP, earlier observations) finished.
  final bool candidatePassDone;

  /// Addresses (as 32-bit values) already probed by the candidate pass, so
  /// the chunk sweep doesn't probe them a second time.
  final Set<int> candidatesProbed;

  ScanPlan toPlan() =>
      ScanPlan(scopeType: scopeType, chunks: chunks, settings: settings);

  ScanCheckpoint copyWith({
    List<ScanChunk>? chunks,
    bool? candidatePassDone,
    Set<int>? candidatesProbed,
  }) {
    return ScanCheckpoint(
      scopeType: scopeType,
      settings: settings,
      chunks: chunks ?? this.chunks,
      candidatePassDone: candidatePassDone ?? this.candidatePassDone,
      candidatesProbed: candidatesProbed ?? this.candidatesProbed,
    );
  }

  String encode() => jsonEncode({
    'version': 1,
    'scopeType': scopeType.name,
    'settings': settings.toJson(),
    'candidatePassDone': candidatePassDone,
    'candidatesProbed': candidatesProbed.toList(),
    'chunks': [for (final chunk in chunks) chunk.toJson()],
  });

  factory ScanCheckpoint.decode(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return ScanCheckpoint(
      scopeType: ScanScopeType.values.byName(json['scopeType'] as String),
      settings: ScanSettings.fromJson(json['settings'] as Map<String, dynamic>),
      candidatePassDone: json['candidatePassDone'] as bool,
      candidatesProbed: (json['candidatesProbed'] as List).cast<int>().toSet(),
      chunks: [
        for (final chunk in json['chunks'] as List)
          ScanChunk.fromJson(chunk as Map<String, dynamic>),
      ],
    );
  }
}
