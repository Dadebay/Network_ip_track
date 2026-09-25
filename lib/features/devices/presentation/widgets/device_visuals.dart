import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/widgets/themed_huge_icon.dart';
import '../../domain/entities/device.dart';
import '../../domain/entities/device_confidence.dart';
import '../../domain/entities/device_status.dart';
import '../../domain/entities/device_type.dart';

List<List<dynamic>> deviceTypeIcon(DeviceType type) => switch (type) {
  DeviceType.phone => HugeIcons.strokeRoundedSmartPhone01,
  DeviceType.tablet => HugeIcons.strokeRoundedTablet01,
  DeviceType.windowsComputer => HugeIcons.strokeRoundedComputer,
  DeviceType.mac => HugeIcons.strokeRoundedLaptop,
  DeviceType.linuxComputerServer => HugeIcons.strokeRoundedServerStack01,
  DeviceType.routerGateway => HugeIcons.strokeRoundedRouter01,
  DeviceType.printer => HugeIcons.strokeRoundedPrinter,
  DeviceType.smartTvMedia => HugeIcons.strokeRoundedTv01,
  DeviceType.iotSmartHome => HugeIcons.strokeRoundedHome01,
  DeviceType.gameConsole => HugeIcons.strokeRoundedGameController01,
  DeviceType.camera => HugeIcons.strokeRoundedCctvCamera,
  DeviceType.unknown => HugeIcons.strokeRoundedHelpCircle,
};

List<List<dynamic>> deviceStatusIcon(DeviceStatus status) => switch (status) {
  DeviceStatus.online => HugeIcons.strokeRoundedCheckmarkCircle02,
  DeviceStatus.offline => HugeIcons.strokeRoundedCancelCircle,
  DeviceStatus.unknown => HugeIcons.strokeRoundedHelpCircle,
};

Color deviceStatusColor(BuildContext context, DeviceStatus status) {
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    DeviceStatus.online => scheme.primary,
    DeviceStatus.offline => scheme.error,
    DeviceStatus.unknown => scheme.outline,
  };
}

/// Status as icon *and* text, so it never relies on color alone.
class DeviceStatusBadge extends StatelessWidget {
  const DeviceStatusBadge({
    super.key,
    required this.status,
    this.dense = false,
  });

  final DeviceStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = deviceStatusColor(context, status);
    return Semantics(
      label: 'Durum: ${status.label}',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThemedHugeIcon(
            deviceStatusIcon(status),
            size: dense ? 14 : 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            status.label,
            style:
                (dense
                        ? Theme.of(context).textTheme.bodySmall
                        : Theme.of(context).textTheme.bodyMedium)
                    ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// "Router/gateway · Yüksek olasılık" — an inferred type is never shown
/// without its confidence label; the user's own type says so.
String deviceTypeWithConfidence(Device device) {
  final customType = device.customType;
  if (customType != null) return '${customType.label} · Kullanıcı';
  if (device.inferredType == DeviceType.unknown) return 'Bilinmiyor';
  return '${device.inferredType.label} · ${device.confidence.label}';
}

/// "iOS · Yüksek olasılık", or "Bilinmiyor".
String deviceOsWithConfidence(Device device) {
  final os = device.inferredOs;
  if (os == null) return 'Bilinmiyor';
  final confidence = device.osConfidence;
  return confidence == null ? os : '$os · ${confidence.label}';
}

/// Small tags: `Gateway`, `Bu Mac`.
class DeviceTags extends StatelessWidget {
  const DeviceTags({super.key, required this.device});

  final Device device;

  @override
  Widget build(BuildContext context) {
    final tags = [
      if (device.isGateway) 'Gateway',
      if (device.isLocalDevice) 'Bu Mac',
      if (device.isKnown) 'Tanıdık',
    ];
    if (tags.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 4,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSecondaryContainer,
              ),
            ),
          ),
      ],
    );
  }
}
