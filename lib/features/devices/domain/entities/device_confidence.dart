/// Confidence labels from the spec: `Kesin`, `Yüksek olasılık`, `Tahmini`,
/// `Bilinmiyor`. A device's inferred type/OS must always carry one of these
/// — never shown as if it were certain without a signal to back it up.
enum DeviceConfidence { certain, highProbability, estimated, unknown }

extension DeviceConfidenceLabel on DeviceConfidence {
  String get label => switch (this) {
    DeviceConfidence.certain => 'Kesin',
    DeviceConfidence.highProbability => 'Yüksek olasılık',
    DeviceConfidence.estimated => 'Tahmini',
    DeviceConfidence.unknown => 'Bilinmiyor',
  };
}
