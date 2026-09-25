import '../../../../core/utils/ipv4_address.dart';
import '../entities/ping_reply.dart';

/// Platform adapter for a single low-rate ICMP echo probe.
///
/// A `null` result means "no reply within the timeout", which per spec
/// limitation #6 does not by itself mean the host is off — callers must not
/// treat one failed probe as a final offline verdict.
abstract interface class PingProvider {
  Future<PingReply?> ping(Ipv4Address address, {required Duration timeout});
}
