import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../domain/entities/scan_chunk_status.dart';
import '../../domain/entities/scan_scope_type.dart';
import '../../domain/entities/scan_session_status.dart';

extension ScanScopeTypeLabels on ScanScopeType {
  String get label => switch (this) {
    ScanScopeType.currentSubnet => 'Bu alt ağı tara',
    ScanScopeType.allAccessiblePrivate172 =>
      'Erişilebilir tüm özel 172 ağlarını tara',
    ScanScopeType.customCidr => 'Özel CIDR ekle',
    ScanScopeType.fullPrivate172Block => 'Tüm özel 172 bloğunu tara',
  };
}

extension ScanSessionStatusLabels on ScanSessionStatus {
  String get label => switch (this) {
    ScanSessionStatus.notStarted => 'Başlamadı',
    ScanSessionStatus.running => 'Sürüyor',
    ScanSessionStatus.paused => 'Duraklatıldı',
    ScanSessionStatus.completed => 'Tamamlandı',
    ScanSessionStatus.cancelled => 'İptal edildi',
    ScanSessionStatus.failed => 'Başarısız',
  };

  List<List<dynamic>> get icon => switch (this) {
    ScanSessionStatus.notStarted => HugeIcons.strokeRoundedHourglass,
    ScanSessionStatus.running => HugeIcons.strokeRoundedRadar01,
    ScanSessionStatus.paused => HugeIcons.strokeRoundedPause,
    ScanSessionStatus.completed => HugeIcons.strokeRoundedCheckmarkCircle02,
    ScanSessionStatus.cancelled => HugeIcons.strokeRoundedCancelCircle,
    ScanSessionStatus.failed => HugeIcons.strokeRoundedAlertCircle,
  };

  Color color(ColorScheme scheme) => switch (this) {
    ScanSessionStatus.completed => scheme.primary,
    ScanSessionStatus.failed => scheme.error,
    _ => scheme.onSurfaceVariant,
  };
}

extension ScanChunkStatusLabels on ScanChunkStatus {
  String get label => switch (this) {
    ScanChunkStatus.pending => 'Sırada',
    ScanChunkStatus.running => 'Taranıyor',
    ScanChunkStatus.paused => 'Duraklatıldı',
    ScanChunkStatus.completed => 'Tamamlandı',
    ScanChunkStatus.cancelled => 'İptal',
    ScanChunkStatus.failed => 'Başarısız',
  };
}
