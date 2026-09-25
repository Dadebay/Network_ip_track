import '../../../../core/concurrency/concurrency_pool.dart';
import '../../../../core/platform/mac_process_runner.dart';
import '../../../../core/utils/ipv4_address.dart';
import '../../domain/entities/mdns_service_record.dart';
import '../../domain/repositories/mdns_provider.dart';
import 'macos_dns_sd_parser.dart';

/// Common service types worth browsing for device classification. Not
/// exhaustive — mDNS/Bonjour has no single "list everything" query — but
/// covers the device kinds the spec cares about (media/casting, printing,
/// file sharing, smart-home, remote access).
const _candidateServiceTypes = [
  '_airplay._tcp',
  '_raop._tcp',
  '_googlecast._tcp',
  '_http._tcp',
  '_https._tcp',
  '_ipp._tcp',
  '_ipps._tcp',
  '_printer._tcp',
  '_pdl-datastream._tcp',
  '_ssh._tcp',
  '_smb._tcp',
  '_afpovertcp._tcp',
  '_homekit._tcp',
  '_hap._tcp',
  '_companion-link._tcp',
  '_spotify-connect._tcp',
  '_device-info._tcp',
];

/// [MdnsProvider] backed by macOS `dns-sd`.
///
/// `dns-sd -B`/`-G` are streaming tools with no natural end, so this browses
/// each candidate service type for a short shared window, resolves each
/// found instance to a hostname, then to an IPv4 address — three short
/// `dns-sd` invocations per instance, run with bounded concurrency so a
/// chatty network can't spawn unbounded processes.
class MacosMdnsProvider implements MdnsProvider {
  MacosMdnsProvider({
    this.processRunner = const MacProcessRunner(),
    ConcurrencyPool? pool,
  }) : _pool = pool ?? ConcurrencyPool(8);

  final MacProcessRunner processRunner;
  final ConcurrencyPool _pool;

  @override
  Future<Map<Ipv4Address, List<MdnsServiceRecord>>> browse({
    required Duration timeout,
  }) async {
    final browseWindow = Duration(
      milliseconds: (timeout.inMilliseconds * 0.5).round(),
    );
    final resolveWindow = Duration(
      milliseconds: (timeout.inMilliseconds * 0.25).round(),
    );

    final browseResults = await Future.wait(
      _candidateServiceTypes.map(
        (type) => _pool.run(() => _browseType(type, browseWindow)),
      ),
    );

    final result = <Ipv4Address, List<MdnsServiceRecord>>{};
    final seenInstances = <String>{};

    for (final instances in browseResults) {
      for (final instance in instances) {
        final dedupeKey = '${instance.serviceType}|${instance.instanceName}';
        if (!seenInstances.add(dedupeKey)) continue;

        final resolved = await _pool.run(
          () => _resolveInstance(instance, resolveWindow),
        );
        if (resolved == null) continue;
        (result[resolved.$1] ??= []).add(resolved.$2);
      }
    }

    return result;
  }

  Future<List<DnsSdBrowseResult>> _browseType(
    String serviceType,
    Duration window,
  ) async {
    final raw = await processRunner.runStreaming('dns-sd', [
      '-B',
      serviceType,
      'local.',
    ], collectFor: window);
    return parseDnsSdBrowseOutput(raw);
  }

  Future<(Ipv4Address, MdnsServiceRecord)?> _resolveInstance(
    DnsSdBrowseResult instance,
    Duration window,
  ) async {
    final lookupRaw = await processRunner.runStreaming('dns-sd', [
      '-L',
      instance.instanceName,
      instance.serviceType,
      'local.',
    ], collectFor: window);
    final hostname = parseDnsSdLookupHostname(lookupRaw);
    if (hostname == null) return null;

    final resolveRaw = await processRunner.runStreaming('dns-sd', [
      '-G',
      'v4',
      hostname,
    ], collectFor: window);
    final address = parseDnsSdResolveAddress(resolveRaw);
    if (address == null) return null;

    String trimDot(String value) =>
        value.endsWith('.') ? value.substring(0, value.length - 1) : value;
    return (
      address,
      MdnsServiceRecord(
        instanceName: instance.instanceName,
        serviceType: trimDot(instance.serviceType),
        hostname: trimDot(hostname),
        txt: parseDnsSdLookupTxt(lookupRaw),
      ),
    );
  }
}
