import '../../domain/entities/ping_reply.dart';

final _replyLinePattern = RegExp(
  r'bytes from [\d.]+:.*?ttl=(\d+)(?:.*?time=([\d.]+) ms)?',
);

/// Parses macOS `ping -c 1` output. Returns null when no echo reply line is
/// present. Pure and fixture-testable.
PingReply? parsePingReply(String raw) {
  for (final line in raw.split('\n')) {
    final match = _replyLinePattern.firstMatch(line);
    if (match == null) continue;
    final ttl = int.tryParse(match.group(1)!);
    final timeMs = double.tryParse(match.group(2) ?? '');
    return PingReply(
      ttl: ttl,
      roundTrip: timeMs == null
          ? null
          : Duration(microseconds: (timeMs * 1000).round()),
    );
  }
  return null;
}
