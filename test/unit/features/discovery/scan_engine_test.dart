import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/utils/cidr.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/discovery/application/scan_control.dart';
import 'package:network_monitor/features/discovery/application/scan_engine.dart';
import 'package:network_monitor/features/discovery/domain/entities/arp_entry.dart';
import 'package:network_monitor/features/discovery/domain/entities/discovery_method.dart';
import 'package:network_monitor/features/discovery/domain/entities/mdns_service_record.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_checkpoint.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_chunk.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_chunk_status.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_scope_type.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_session_status.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_settings.dart';

import '../../../fixtures/fakes/fake_discovery_providers.dart';

Ipv4Address ip(String s) => Ipv4Address.parse(s);

// chunkConcurrency defaults to 1 here (unlike production's default of 4) so
// existing tests keep their original one-chunk-at-a-time assumptions; tests
// that care about cross-chunk parallelism opt in explicitly.
ScanCheckpoint checkpointFor(
  List<String> cidrs, {
  int concurrency = 4,
  int chunkConcurrency = 1,
}) => ScanCheckpoint(
  scopeType: ScanScopeType.customCidr,
  settings: ScanSettings(
    concurrency: concurrency,
    chunkConcurrency: chunkConcurrency,
  ),
  chunks: [for (final c in cidrs) ScanChunk(cidr: Cidr.parse(c))],
);

ScanEngine engineWith({
  FakePingProvider? ping,
  FakeArpTableProvider? arp,
  FakeMdnsProvider? mdns,
  FakeReverseDnsProvider? dns,
  FakePortProbeProvider? ports,
  FakeNetbiosProvider? netbios,
}) => ScanEngine(
  arpTable: arp ?? FakeArpTableProvider(),
  ping: ping ?? FakePingProvider(),
  reverseDns: dns ?? FakeReverseDnsProvider(),
  mdns: mdns ?? FakeMdnsProvider(),
  ssdp: FakeSsdpProvider(),
  portProbe: ports ?? FakePortProbeProvider(),
  netbios: netbios ?? FakeNetbiosProvider(),
  progressInterval: Duration.zero,
);

void main() {
  test('streams found hosts and completes every chunk', () async {
    final ping = FakePingProvider(
      alive: {ip('172.16.14.1'), ip('172.16.14.200')},
    );
    final events =
        await engineWith(
              ping: ping,
              dns: FakeReverseDnsProvider({ip('172.16.14.1'): 'router.lan'}),
              ports: FakePortProbeProvider({
                ip('172.16.14.1'): [80, 443, 12345],
              }),
            )
            .run(
              from: checkpointFor(['172.16.14.0/24']),
              control: ScanControl(),
            )
            .toList();

    final found = events.whereType<ScanHostFoundEvent>().toList();
    expect(found.map((e) => e.device.ipAddress.toString()), [
      '172.16.14.1',
      '172.16.14.200',
    ]);
    expect(found.first.device.hostname, 'router.lan');
    // Only the configured limited ports are ever probed.
    expect(found.first.device.openPorts, [80, 443]);
    expect(found.first.device.signals, contains('ICMP yanıtı'));

    final finished = events.last as ScanFinishedEvent;
    expect(finished.status, ScanSessionStatus.completed);
    expect(finished.checkpoint.chunks.single.status, ScanChunkStatus.completed);
    expect(finished.checkpoint.chunks.single.hostsScanned, 254);
    expect(finished.checkpoint.chunks.single.devicesFound, 2);
    // Network and broadcast addresses are never pinged.
    expect(ping.pinged, isNot(contains(ip('172.16.14.0'))));
    expect(ping.pinged, isNot(contains(ip('172.16.14.255'))));
    expect(ping.pinged, hasLength(254));
  });

  test(
    'host found only via ARP (ICMP dropped) is reported with its MAC',
    () async {
      final events =
          await engineWith(
                arp: FakeArpTableProvider(
                  lookupResults: {ip('172.16.14.30'): 'aa:bb:cc:00:00:01'},
                ),
              )
              .run(
                from: checkpointFor(['172.16.14.0/24']),
                control: ScanControl(),
                context: ScanEngineContext(
                  localSegments: [Cidr.parse('172.16.14.0/24')],
                ),
              )
              .toList();

      final found = events.whereType<ScanHostFoundEvent>().single.device;
      expect(found.ipAddress, ip('172.16.14.30'));
      expect(found.macAddress, 'aa:bb:cc:00:00:01');
      expect(found.signals, contains('ARP yanıtı'));
    },
  );

  test(
    'routed host dropping ICMP with no ARP entry is found by an open port',
    () async {
      final ports = FakePortProbeProvider({
        ip('172.16.20.7'): [443],
      });
      final events = await engineWith(ports: ports)
          .run(
            from: checkpointFor(['172.16.20.0/24']),
            control: ScanControl(),
            // 172.16.20.0/24 is routed, not a local segment: no ARP.
            context: ScanEngineContext(
              localSegments: [Cidr.parse('172.16.14.0/24')],
            ),
          )
          .toList();

      final found = events.whereType<ScanHostFoundEvent>().single.device;
      expect(found.ipAddress, ip('172.16.20.7'));
      expect(found.macAddress, isNull);
      expect(found.openPorts, [443]);
      expect(found.signals, contains('TCP port yanıtı'));
      expect(found.signals, isNot(contains('ICMP yanıtı')));
    },
  );

  test('with the port check disabled, a silent host is not reported', () async {
    final checkpoint = checkpointFor(['172.16.20.0/24']);
    final noPorts = ScanCheckpoint(
      scopeType: checkpoint.scopeType,
      settings: checkpoint.settings.copyWith(
        methods: {...checkpoint.settings.methods}
          ..remove(DiscoveryMethod.limitedPortScan),
      ),
      chunks: checkpoint.chunks,
    );
    final events = await engineWith(
      ports: FakePortProbeProvider({
        ip('172.16.20.7'): [443],
      }),
    ).run(from: noPorts, control: ScanControl()).toList();
    expect(events.whereType<ScanHostFoundEvent>(), isEmpty);
  });

  test('ARP/mDNS candidates are probed first and not probed twice', () async {
    final ping = FakePingProvider();
    final events =
        await engineWith(
              ping: ping,
              arp: FakeArpTableProvider(
                table: [
                  ArpEntry(
                    ipAddress: ip('172.16.14.50'),
                    macAddress: 'aa:bb:cc:00:00:50',
                  ),
                  // Outside the plan: must be ignored.
                  ArpEntry(
                    ipAddress: ip('172.16.99.1'),
                    macAddress: 'aa:bb:cc:00:99:01',
                  ),
                  // Multicast MAC: not a device.
                  ArpEntry(
                    ipAddress: ip('172.16.14.251'),
                    macAddress: '01:00:5e:00:00:fb',
                  ),
                ],
              ),
              mdns: FakeMdnsProvider({
                ip('172.16.14.60'): [
                  const MdnsServiceRecord(
                    instanceName: 'Yazıcı',
                    serviceType: '_ipp._tcp',
                  ),
                ],
              }),
            )
            .run(
              from: checkpointFor(['172.16.14.0/24']),
              control: ScanControl(),
            )
            .toList();

    expect(ping.pinged.take(2), [ip('172.16.14.50'), ip('172.16.14.60')]);
    expect(ping.pinged.where((a) => a == ip('172.16.14.50')), hasLength(1));
    expect(ping.pinged, isNot(contains(ip('172.16.99.1'))));

    final found = events.whereType<ScanHostFoundEvent>().map((e) => e.device);
    expect(found.map((d) => d.ipAddress.toString()), [
      '172.16.14.50',
      '172.16.14.60',
    ]);
    expect(found.last.mdnsServices, ['Yazıcı (_ipp._tcp)']);
  });

  test('never exceeds the configured concurrency', () async {
    final ping = FakePingProvider(delay: const Duration(milliseconds: 1));
    await engineWith(ping: ping)
        .run(
          from: checkpointFor(['172.16.14.0/26'], concurrency: 3),
          control: ScanControl(),
        )
        .toList();
    expect(ping.maxInFlight, lessThanOrEqualTo(3));
    expect(ping.pinged, hasLength(62));
  });

  test('pause stops scheduling and records an exact resume offset', () async {
    final control = ScanControl();
    final ping = FakePingProvider(
      alive: {ip('172.16.14.3'), ip('172.16.14.100')},
    );
    ping.onPing = (address) {
      if (address == ip('172.16.14.40')) control.pause();
    };
    final engine = engineWith(ping: ping);

    final first = await engine
        .run(
          from: checkpointFor(['172.16.14.0/24', '172.16.15.0/24']),
          control: control,
        )
        .toList();
    final paused = first.last as ScanFinishedEvent;
    expect(paused.status, ScanSessionStatus.paused);

    final chunk = paused.checkpoint.chunks.first;
    expect(chunk.status, ScanChunkStatus.paused);
    // Every address before the offset was probed; none after it.
    final probedBefore = ping.pinged.toSet();
    for (final (i, address) in chunk.hostAddresses.indexed) {
      expect(probedBefore.contains(address), i < chunk.hostsScanned);
    }
    expect(paused.checkpoint.chunks.last.status, ScanChunkStatus.pending);

    ping.pinged.clear();
    ping.onPing = null;
    final second = await engine
        .run(from: paused.checkpoint, control: ScanControl())
        .toList();
    final done = second.last as ScanFinishedEvent;
    expect(done.status, ScanSessionStatus.completed);
    expect(
      done.checkpoint.chunks.every(
        (c) => c.status == ScanChunkStatus.completed,
      ),
      isTrue,
    );
    // Resume picks up exactly where it stopped: no address probed twice
    // across the two runs, none skipped.
    expect(ping.pinged.toSet().intersection(probedBefore), isEmpty);
    expect(ping.pinged.length + probedBefore.length, 254 * 2);

    final foundIps = [
      ...first.whereType<ScanHostFoundEvent>(),
      ...second.whereType<ScanHostFoundEvent>(),
    ].map((e) => e.device.ipAddress.toString());
    expect(foundIps, ['172.16.14.3', '172.16.14.100']);
  });

  test('cancel ends the scan as cancelled without probing further', () async {
    final control = ScanControl();
    final ping = FakePingProvider();
    ping.onPing = (address) {
      if (ping.pinged.length == 10) control.cancel();
    };
    final events = await engineWith(ping: ping)
        .run(
          from: checkpointFor([
            '172.16.14.0/24',
            '172.16.15.0/24',
          ], concurrency: 2),
          control: control,
        )
        .toList();

    final finished = events.last as ScanFinishedEvent;
    expect(finished.status, ScanSessionStatus.cancelled);
    expect(ping.pinged.length, lessThan(14));
    expect(finished.checkpoint.chunks.first.status, ScanChunkStatus.cancelled);
  });

  test(
    'a probe permission failure fails the scan instead of finding nothing',
    () async {
      final events =
          await ScanEngine(
                arpTable: FakeArpTableProvider(),
                ping: _ThrowingPing(),
                reverseDns: FakeReverseDnsProvider(),
                mdns: FakeMdnsProvider(),
                ssdp: FakeSsdpProvider(),
                portProbe: FakePortProbeProvider(),
                netbios: FakeNetbiosProvider(),
              )
              .run(
                from: checkpointFor(['172.16.14.0/30']),
                control: ScanControl(),
              )
              .toList();

      final finished = events.last as ScanFinishedEvent;
      expect(finished.status, ScanSessionStatus.failed);
      expect(finished.failure, isNotNull);
    },
  );

  test('checkpoint survives an encode/decode round trip', () {
    final checkpoint = checkpointFor(['172.16.14.0/24']).copyWith(
      candidatePassDone: true,
      candidatesProbed: {ip('172.16.14.5').value},
      chunks: [
        ScanChunk(
          cidr: Cidr.parse('172.16.14.0/24'),
          status: ScanChunkStatus.paused,
          hostsScanned: 77,
          devicesFound: 3,
        ),
      ],
    );
    final decoded = ScanCheckpoint.decode(checkpoint.encode());
    expect(decoded.candidatePassDone, isTrue);
    expect(decoded.candidatesProbed, {ip('172.16.14.5').value});
    expect(decoded.chunks.single.hostsScanned, 77);
    expect(decoded.chunks.single.status, ScanChunkStatus.paused);
    expect(decoded.settings.limitedPorts, checkpoint.settings.limitedPorts);
    expect(decoded.settings.methods, checkpoint.settings.methods);
  });
}

class _ThrowingPing extends FakePingProvider {
  @override
  Future<Never> ping(Ipv4Address address, {required Duration timeout}) async {
    throw StateError('ping: socket: Operation not permitted');
  }
}
