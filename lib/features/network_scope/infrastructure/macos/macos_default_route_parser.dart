import '../../../../core/utils/ipv4_address.dart';

/// Result of parsing `route -n get default`.
class ParsedDefaultRoute {
  const ParsedDefaultRoute({required this.interfaceName, this.gateway});

  final String? interfaceName;
  final Ipv4Address? gateway;

  bool get isKnown => interfaceName != null;
}

final _gatewayLinePattern = RegExp(r'^\s*gateway:\s*(\S+)');
final _interfaceLinePattern = RegExp(r'^\s*interface:\s*(\S+)');

/// Parses the stdout of `route -n get default`. Pure and fixture-testable.
ParsedDefaultRoute parseDefaultRouteOutput(String raw) {
  String? interfaceName;
  Ipv4Address? gateway;

  for (final line in raw.split('\n')) {
    final gatewayMatch = _gatewayLinePattern.firstMatch(line);
    if (gatewayMatch != null) {
      gateway = Ipv4Address.tryParse(gatewayMatch.group(1)!);
      continue;
    }
    final interfaceMatch = _interfaceLinePattern.firstMatch(line);
    if (interfaceMatch != null) {
      interfaceName = interfaceMatch.group(1);
    }
  }

  return ParsedDefaultRoute(interfaceName: interfaceName, gateway: gateway);
}
