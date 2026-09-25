import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/traffic/presentation/formatting/byte_format.dart';

void main() {
  group('formatBytes (decimal, 1000²)', () {
    test('small values stay in bytes', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(999), '999 B');
    });

    test('uses MB/GB with a decimal comma', () {
      expect(formatBytes(1000), '1 KB');
      expect(formatBytes(1500000), '1,5 MB');
      expect(formatBytes(250000000), '250 MB');
      expect(formatBytes(1234567890), '1,2 GB');
      expect(formatBytes(3000000000000), '3 TB');
    });

    test('rounding up to the next unit switches units', () {
      expect(formatBytes(999960), '1 MB');
    });
  });

  group('formatBytes (binary, 1024²)', () {
    test('uses MiB/GiB', () {
      expect(formatBytes(1024, binary: true), '1 KiB');
      expect(formatBytes(1048576, binary: true), '1 MiB');
      expect(formatBytes(1610612736, binary: true), '1,5 GiB');
    });

    test('the same byte count differs between MB and MiB', () {
      expect(formatBytes(100000000), '100 MB');
      expect(formatBytes(100000000, binary: true), '95,4 MiB');
    });
  });
}
