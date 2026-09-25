import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/cidr.dart';
import 'package:network_monitor/features/discovery/application/chunk_cidr.dart';

void main() {
  test('a /24 or smaller CIDR is returned as a single chunk', () {
    expect(chunkCidrInto24s(Cidr.parse('172.16.14.0/24')), [
      Cidr.parse('172.16.14.0/24'),
    ]);
    expect(chunkCidrInto24s(Cidr.parse('172.16.14.4/30')), [
      Cidr.parse('172.16.14.4/30'),
    ]);
  });

  test('a /16 splits into 256 contiguous /24 chunks', () {
    final chunks = chunkCidrInto24s(Cidr.parse('172.20.0.0/16'));
    expect(chunks, hasLength(256));
    expect(chunks.first.toString(), '172.20.0.0/24');
    expect(chunks.last.toString(), '172.20.255.0/24');
    expect(chunks.map((c) => c.toString()).toSet().length, 256);
  });

  test('the full private-172 /12 splits into exactly 4096 /24 chunks', () {
    final chunks = chunkCidrInto24s(Cidr.parse('172.16.0.0/12'));
    expect(chunks, hasLength(4096));
    expect(chunks.first.toString(), '172.16.0.0/24');
    expect(chunks.last.toString(), '172.31.255.0/24');
  });
}
