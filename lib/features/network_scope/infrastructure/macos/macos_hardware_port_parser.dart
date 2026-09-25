final _hardwarePortLinePattern = RegExp(r'^Hardware Port:\s*(.+)$');
final _deviceLinePattern = RegExp(r'^Device:\s*(\S+)$');

/// Parses `networksetup -listallhardwareports` into a map of BSD device name
/// (e.g. `en0`) to its human-readable hardware port name (e.g. `Wi-Fi`).
/// Pure and fixture-testable.
Map<String, String> parseHardwarePorts(String raw) {
  final result = <String, String>{};
  String? pendingPortName;

  for (final line in raw.split('\n')) {
    final trimmed = line.trim();
    final portMatch = _hardwarePortLinePattern.firstMatch(trimmed);
    if (portMatch != null) {
      pendingPortName = portMatch.group(1)!.trim();
      continue;
    }
    final deviceMatch = _deviceLinePattern.firstMatch(trimmed);
    if (deviceMatch != null && pendingPortName != null) {
      result[deviceMatch.group(1)!] = pendingPortName;
      pendingPortName = null;
    }
  }

  return result;
}
