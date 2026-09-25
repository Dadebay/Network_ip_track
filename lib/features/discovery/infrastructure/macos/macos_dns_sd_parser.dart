import '../../../../core/utils/ipv4_address.dart';

/// One `Add` row from `dns-sd -B <type> <domain>`.
class DnsSdBrowseResult {
  const DnsSdBrowseResult({
    required this.serviceType,
    required this.instanceName,
  });
  final String serviceType;
  final String instanceName;
}

final _browseLinePattern = RegExp(
  r'^\S+\s+Add\s+\S+\s+\S+\s+(\S+)\s+(\S+)\s+(.+)$',
);

/// Parses `dns-sd -B <type> <domain>` streaming output into the instances
/// that were advertising by the time we stopped listening. Pure and
/// fixture-testable.
List<DnsSdBrowseResult> parseDnsSdBrowseOutput(String raw) {
  final results = <DnsSdBrowseResult>[];
  for (final line in raw.split('\n')) {
    final match = _browseLinePattern.firstMatch(line.trimRight());
    if (match == null) continue;
    final serviceType = match.group(2)!;
    final instanceName = match.group(3)!.trim();
    if (instanceName.isEmpty) continue;
    results.add(
      DnsSdBrowseResult(serviceType: serviceType, instanceName: instanceName),
    );
  }
  return results;
}

final _lookupLinePattern = RegExp(r'can be reached at\s+(\S+):(\d+)');

/// Parses `dns-sd -L "<instance>" <type> <domain>` output, returning the
/// target hostname the instance resolves to (without the port).
String? parseDnsSdLookupHostname(String raw) {
  final match = _lookupLinePattern.firstMatch(raw);
  return match?.group(1);
}

/// Parses the TXT record printed on the indented line(s) after the
/// "can be reached at" line of `dns-sd -L` output: space-separated
/// `key=value` pairs, where a literal space inside a value is `\ `.
/// Keys are lowercased; entries without `=` are ignored.
Map<String, String> parseDnsSdLookupTxt(String raw) {
  final lines = raw.split('\n');
  final start = lines.indexWhere((line) => line.contains('can be reached at'));
  if (start == -1) return const {};

  final txt = <String, String>{};
  for (final line in lines.skip(start + 1)) {
    if (line.isEmpty || !line.startsWith(RegExp(r'\s'))) break;
    for (final token in _splitEscaped(line.trim())) {
      final separator = token.indexOf('=');
      if (separator <= 0) continue;
      txt[token.substring(0, separator).toLowerCase()] = token.substring(
        separator + 1,
      );
    }
  }
  return txt;
}

List<String> _splitEscaped(String input) {
  final tokens = <String>[];
  final current = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (char == '\\' && i + 1 < input.length) {
      current.write(input[++i]);
    } else if (char == ' ') {
      if (current.isNotEmpty) tokens.add(current.toString());
      current.clear();
    } else {
      current.write(char);
    }
  }
  if (current.isNotEmpty) tokens.add(current.toString());
  return tokens;
}

final _resolveLinePattern = RegExp(
  r'^\S+\s+Add\s+\S+\s+\S+\s+(\S+)\s+([\d.]+)\s+\d+',
);

/// Parses `dns-sd -G v4 <hostname>` streaming output into the resolved
/// IPv4 address, if one appeared before we stopped listening.
Ipv4Address? parseDnsSdResolveAddress(String raw) {
  for (final line in raw.split('\n')) {
    final match = _resolveLinePattern.firstMatch(line.trimRight());
    if (match == null) continue;
    final address = Ipv4Address.tryParse(match.group(2)!);
    if (address != null) return address;
  }
  return null;
}
