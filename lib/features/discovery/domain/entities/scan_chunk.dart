import '../../../../core/utils/cidr.dart';
import '../../../../core/utils/ipv4_address.dart';
import 'scan_chunk_status.dart';

/// One unit of scan work — never larger than a /24 — so a huge scope like
/// `172.16.0.0/12` (1,048,576 addresses) is queued as many small, individually
/// pausable/resumable/cancellable jobs instead of one blind blast.
class ScanChunk {
  const ScanChunk({
    required this.cidr,
    this.status = ScanChunkStatus.pending,
    this.hostsScanned = 0,
    this.devicesFound = 0,
  });

  final Cidr cidr;
  final ScanChunkStatus status;

  /// Number of [hostAddresses] already probed, in order. Doubles as the
  /// resume offset: after a pause every host before this index is done.
  final int hostsScanned;
  final int devicesFound;

  /// The addresses this chunk actually probes. The chunk's own network and
  /// broadcast addresses are skipped (for /30 and larger) so the sweep never
  /// sends a directed-broadcast ping.
  Iterable<Ipv4Address> get hostAddresses sync* {
    final first = cidr.prefixLength >= 31
        ? cidr.networkAddress.value
        : cidr.networkAddress.value + 1;
    for (var i = 0; i < hostsTotal; i++) {
      yield Ipv4Address(first + i);
    }
  }

  int get hostsTotal {
    final total = cidr.totalAddressCount.toInt();
    return cidr.prefixLength >= 31 ? total : total - 2;
  }

  bool get isFinished =>
      status == ScanChunkStatus.completed ||
      status == ScanChunkStatus.cancelled;

  ScanChunk copyWith({
    ScanChunkStatus? status,
    int? hostsScanned,
    int? devicesFound,
  }) {
    return ScanChunk(
      cidr: cidr,
      status: status ?? this.status,
      hostsScanned: hostsScanned ?? this.hostsScanned,
      devicesFound: devicesFound ?? this.devicesFound,
    );
  }

  Map<String, dynamic> toJson() => {
    'cidr': cidr.toString(),
    'status': status.name,
    'hostsScanned': hostsScanned,
    'devicesFound': devicesFound,
  };

  factory ScanChunk.fromJson(Map<String, dynamic> json) => ScanChunk(
    cidr: Cidr.parse(json['cidr'] as String),
    status: ScanChunkStatus.values.byName(json['status'] as String),
    hostsScanned: json['hostsScanned'] as int,
    devicesFound: json['devicesFound'] as int,
  );
}
