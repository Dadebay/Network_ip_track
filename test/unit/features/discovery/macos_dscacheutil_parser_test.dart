import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/discovery/infrastructure/macos/macos_dscacheutil_parser.dart';

void main() {
  test('extracts the name field', () {
    const raw = '''
name: gateway.local
ip_address: 172.16.14.254
''';
    expect(parseDscacheutilHostName(raw), 'gateway.local');
  });

  test('strips a trailing DNS root dot', () {
    const raw = 'name: gateway.local.\n';
    expect(parseDscacheutilHostName(raw), 'gateway.local');
  });

  test('returns null for empty output (no PTR record)', () {
    expect(parseDscacheutilHostName(''), isNull);
  });
}
