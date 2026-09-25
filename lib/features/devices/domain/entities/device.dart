import '../../../../core/utils/ipv4_address.dart';
import 'device_confidence.dart';
import 'device_status.dart';
import 'device_type.dart';

/// A discovered (or manually annotated) device — mirrors the `devices`
/// table. The user's own [customName]/[customType]/[note] always take
/// precedence over anything inferred, and survive future scans.
class Device {
  const Device({
    required this.id,
    required this.networkId,
    required this.currentIp,
    required this.inferredType,
    required this.confidence,
    required this.isGateway,
    required this.isLocalDevice,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.status,
    this.macAddress,
    this.hostname,
    this.vendor,
    this.inferredOs,
    this.osConfidence,
    this.inferenceReasons = const [],
    this.customName,
    this.customType,
    this.note,
    this.isKnown = false,
    this.pingConfirmed = false,
  });

  final int id;
  final int networkId;
  final String? macAddress;
  final Ipv4Address currentIp;
  final String? hostname;
  final String? vendor;
  final DeviceType inferredType;
  final String? inferredOs;

  /// Confidence of [inferredType].
  final DeviceConfidence confidence;

  /// Confidence of [inferredOs]; null when no OS is inferred.
  final DeviceConfidence? osConfidence;

  /// Why the classifier chose [inferredType]/[inferredOs].
  final List<String> inferenceReasons;

  final String? customName;
  final DeviceType? customType;
  final String? note;

  /// The user marked this device as one they recognize.
  final bool isKnown;

  /// True once an ICMP echo reply has ever been seen from this IP. The one
  /// liveness signal that's hard for a network middlebox to fake — see
  /// `Devices.pingConfirmed` for why this exists.
  final bool pingConfirmed;

  final bool isGateway;
  final bool isLocalDevice;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final DeviceStatus status;

  /// What the tree/list should show as the device's name: the user's own
  /// name first, then hostname, then the raw IP as a last resort.
  String get displayName => customName ?? shortHostname ?? currentIp.toString();

  /// [hostname] without the mDNS `.local` suffix, which adds nothing on a
  /// LAN and pushes long serial-number names (e.g. IP cameras) off-screen.
  String? get shortHostname =>
      hostname?.replaceFirst(RegExp(r'\.local\.?$', caseSensitive: false), '');

  /// Whether a name beyond the bare IP is known.
  bool get hasName => customName != null || hostname != null;

  /// The user's type when set, otherwise the inferred one — used for
  /// grouping, filtering and icons.
  DeviceType get effectiveType => customType ?? inferredType;

  String get displayType => effectiveType.label;
}
