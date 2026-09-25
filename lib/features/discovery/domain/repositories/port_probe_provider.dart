import '../../../../core/utils/ipv4_address.dart';

/// Platform adapter for a limited, classification-only TCP connect probe.
///
/// Never a general port scanner: callers pass the small configured port
/// list (see [ScanSettings.limitedPorts]) and nothing else.
abstract interface class PortProbeProvider {
  Future<List<int>> probeOpenPorts(
    Ipv4Address address,
    List<int> ports, {
    required Duration timeout,
  });
}
