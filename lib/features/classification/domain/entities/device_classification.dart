import '../../../devices/domain/entities/device_confidence.dart';
import '../../../devices/domain/entities/device_type.dart';

/// The classifier's verdict for one device. [type]/[os] are never presented
/// without their confidence, and [reasons] say which signals led here.
class DeviceClassification {
  const DeviceClassification({
    required this.type,
    required this.typeConfidence,
    required this.reasons,
    this.os,
    this.osConfidence,
  });

  static const unknown = DeviceClassification(
    type: DeviceType.unknown,
    typeConfidence: DeviceConfidence.unknown,
    reasons: [],
  );

  final DeviceType type;
  final DeviceConfidence typeConfidence;

  /// Null when the evidence doesn't support any OS.
  final String? os;
  final DeviceConfidence? osConfidence;
  final List<String> reasons;
}

extension DeviceConfidenceRank on DeviceConfidence {
  /// Higher is stronger; used to keep a stronger earlier verdict when a
  /// later scan sees fewer signals.
  int get rank => switch (this) {
    DeviceConfidence.certain => 3,
    DeviceConfidence.highProbability => 2,
    DeviceConfidence.estimated => 1,
    DeviceConfidence.unknown => 0,
  };
}
