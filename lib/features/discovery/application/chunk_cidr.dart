import '../../../core/utils/cidr.dart';
import '../../../core/utils/ipv4_address.dart';

/// Splits [cidr] into `/24`-sized (or smaller, if [cidr] itself is already
/// smaller than a /24) chunks, so a huge scope is queued as many bounded
/// jobs instead of one blind blast across the whole block.
List<Cidr> chunkCidrInto24s(Cidr cidr) {
  const chunkPrefixLength = 24;
  if (cidr.prefixLength >= chunkPrefixLength) {
    return [cidr];
  }

  final chunkCount = 1 << (chunkPrefixLength - cidr.prefixLength);
  final chunkSize = 1 << (32 - chunkPrefixLength);
  final chunks = <Cidr>[];
  for (var i = 0; i < chunkCount; i++) {
    final chunkNetworkValue = cidr.networkAddress.value + i * chunkSize;
    chunks.add(
      Cidr.fromAddressAndPrefix(
        Ipv4Address(chunkNetworkValue),
        chunkPrefixLength,
      ),
    );
  }
  return chunks;
}
