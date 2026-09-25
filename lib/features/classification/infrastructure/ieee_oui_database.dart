import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/utils/mac_address.dart';
import '../domain/repositories/oui_lookup.dart';

/// Where the IEEE MA-L registry export is bundled.
const ouiAssetPath = 'assets/oui/oui.csv';

/// [OuiLookup] over the IEEE MA-L registry (24-bit prefixes).
class IeeeOuiDatabase implements OuiLookup {
  IeeeOuiDatabase(this._vendorsByPrefix);

  /// No registry installed: every lookup is "unknown".
  IeeeOuiDatabase.unavailable() : _vendorsByPrefix = const {};

  /// Keyed by the uppercase 6-hex-digit prefix, e.g. `ACDE48`.
  final Map<String, String> _vendorsByPrefix;

  static const _logger = AppLogger('OUI');

  @override
  bool get isAvailable => _vendorsByPrefix.isNotEmpty;

  @override
  String? vendorFor(String normalizedMac) {
    if (isLocallyAdministeredMac(normalizedMac)) return null;
    final prefix = ouiOf(normalizedMac).replaceAll(':', '').toUpperCase();
    return _vendorsByPrefix[prefix];
  }

  /// Loads [ouiAssetPath], parsing off the UI isolate. A missing asset is
  /// not an error — vendors then simply stay unknown.
  static Future<IeeeOuiDatabase> load(AssetBundle bundle) async {
    final String raw;
    try {
      raw = await bundle.loadString(ouiAssetPath, cache: false);
    } on Object {
      _logger.warning(
        'OUI verisi bulunamadı ($ouiAssetPath); üreticiler "Bilinmiyor" '
        'kalacak.',
      );
      return IeeeOuiDatabase.unavailable();
    }
    return IeeeOuiDatabase(await compute(parseIeeeOuiCsv, raw));
  }
}

/// Parses the IEEE registry CSV export
/// (`Registry,Assignment,Organization Name,Organization Address`), keeping
/// MA-L rows. Handles quoted fields containing commas and `""` escapes.
/// Pure and fixture-testable.
Map<String, String> parseIeeeOuiCsv(String raw) {
  final result = <String, String>{};
  var isHeader = true;
  for (final fields in _csvRows(raw)) {
    if (isHeader) {
      isHeader = false;
      continue;
    }
    if (fields.length < 3 || fields[0] != 'MA-L') continue;
    final assignment = fields[1].trim().toUpperCase();
    final organization = fields[2].trim();
    if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(assignment)) continue;
    if (organization.isEmpty) continue;
    result[assignment] = organization;
  }
  return result;
}

Iterable<List<String>> _csvRows(String raw) sync* {
  var fields = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  for (var i = 0; i < raw.length; i++) {
    final char = raw[i];
    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < raw.length && raw[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        field.write(char);
      }
    } else if (char == '"') {
      inQuotes = true;
    } else if (char == ',') {
      fields.add(field.toString());
      field.clear();
    } else if (char == '\n' || char == '\r') {
      if (char == '\r' && i + 1 < raw.length && raw[i + 1] == '\n') i++;
      fields.add(field.toString());
      field.clear();
      if (fields.any((f) => f.isNotEmpty)) yield fields;
      fields = <String>[];
    } else {
      field.write(char);
    }
  }
  if (field.isNotEmpty || fields.isNotEmpty) {
    fields.add(field.toString());
    if (fields.any((f) => f.isNotEmpty)) yield fields;
  }
}
