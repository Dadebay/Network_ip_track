final _nameLinePattern = RegExp(r'^name:\s*(.+)$');

/// Parses `dscacheutil -q host -a ip_address <ip>` output, returning the
/// first `name:` value with any trailing DNS root dot stripped. Pure and
/// fixture-testable.
String? parseDscacheutilHostName(String raw) {
  for (final line in raw.split('\n')) {
    final match = _nameLinePattern.firstMatch(line.trim());
    if (match == null) continue;
    var name = match.group(1)!.trim();
    if (name.endsWith('.')) name = name.substring(0, name.length - 1);
    return name.isEmpty ? null : name;
  }
  return null;
}
