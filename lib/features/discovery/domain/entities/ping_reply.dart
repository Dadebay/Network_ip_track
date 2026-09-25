/// A successful ICMP echo reply.
class PingReply {
  const PingReply({this.ttl, this.roundTrip});

  /// Observed TTL of the reply, if the tool reported it. Only a weak OS hint
  /// (see spec limitation #5) — never a classification on its own.
  final int? ttl;
  final Duration? roundTrip;

  /// Human-readable classification hint derived from [ttl], guessing the
  /// sender's initial TTL from the nearest common default above it.
  String? get ttlSignal {
    final ttl = this.ttl;
    if (ttl == null) return null;
    if (ttl <= 64) return 'TTL $ttl (Unix-benzeri, zayıf sinyal)';
    if (ttl <= 128) return 'TTL $ttl (Windows-benzeri, zayıf sinyal)';
    return 'TTL $ttl (ağ cihazı-benzeri, zayıf sinyal)';
  }
}
