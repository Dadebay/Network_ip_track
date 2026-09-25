import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/core/database/app_database.dart';
import 'package:network_monitor/core/errors/app_failure.dart';
import 'package:network_monitor/features/classification/application/device_classifier.dart';
import 'package:network_monitor/features/classification/domain/entities/device_classification.dart';
import 'package:network_monitor/core/utils/cidr.dart';
import 'package:network_monitor/core/utils/ipv4_address.dart';
import 'package:network_monitor/features/devices/domain/entities/device_confidence.dart';
import 'package:network_monitor/features/devices/domain/entities/device_status.dart';
import 'package:network_monitor/features/devices/domain/entities/device_type.dart';
import 'package:network_monitor/features/devices/infrastructure/drift_device_repository.dart';
import 'package:network_monitor/features/discovery/application/scan_coordinator.dart';
import 'package:network_monitor/features/discovery/application/scan_engine.dart';
import 'package:network_monitor/features/discovery/domain/entities/discovered_device.dart';
import 'package:network_monitor/features/discovery/domain/entities/mdns_service_record.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_chunk.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_plan.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_progress.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_scope_type.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_session_status.dart';
import 'package:network_monitor/features/discovery/domain/entities/scan_settings.dart';
import 'package:network_monitor/features/discovery/infrastructure/drift_scan_session_repository.dart';

import '../fixtures/fakes/fake_discovery_providers.dart';

/// Coordinator + real Drift repositories on an in-memory SQLite database,
/// with fake discovery adapters — never touches the real network.
void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase database;
  late DriftDeviceRepository devices;
  late DriftScanSessionRepository sessions;
  late int networkId;

  Ipv4Address ip(String s) => Ipv4Address.parse(s);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    devices = DriftDeviceRepository(database);
    sessions = DriftScanSessionRepository(database);
    networkId = await database.upsertActiveNetwork(
      interfaceName: 'en0',
      displayName: 'Wi-Fi',
      cidr: '172.16.14.0/24',
      gatewayIp: '172.16.14.254',
      observedAt: DateTime(2026, 9, 1),
    );
  });

  tearDown(() => database.close());

  ScanNetworkContext network() => ScanNetworkContext(
    networkId: networkId,
    interfaceName: 'en0',
    interfaceCidr: Cidr.parse('172.16.14.0/24'),
    localAddress: ip('172.16.14.26'),
    gatewayAddress: ip('172.16.14.254'),
    localSegments: [Cidr.parse('172.16.14.0/24')],
  );

  ScanPlan plan(List<String> cidrs) => ScanPlan(
    scopeType: ScanScopeType.customCidr,
    settings: const ScanSettings(concurrency: 4),
    chunks: [for (final c in cidrs) ScanChunk(cidr: Cidr.parse(c))],
  );

  // SQLite stores DateTimes at second precision; an advancing clock keeps
  // back-to-back test scans in distinct seconds, as real scans are.
  var now = DateTime(2026, 9, 10, 12);
  DateTime clock() => now = now.add(const Duration(seconds: 5));

  ScanCoordinator coordinatorWith(
    FakePingProvider ping, {
    FakeArpTableProvider? arp,
    FakePortProbeProvider? ports,
    FakeMdnsProvider? mdns,
    ScanNetworkProbe? networkProbe,
    FakeOuiLookup? oui,
  }) => ScanCoordinator(
    clock: clock,
    networkProbe: networkProbe,
    ouiLoader: oui == null ? null : () async => oui,
    networkCheckInterval: const Duration(seconds: 30),
    engine: ScanEngine(
      clock: clock,
      arpTable: arp ?? FakeArpTableProvider(),
      ping: ping,
      reverseDns: FakeReverseDnsProvider(),
      mdns: mdns ?? FakeMdnsProvider(),
      ssdp: FakeSsdpProvider(),
      portProbe: ports ?? FakePortProbeProvider(),
      netbios: FakeNetbiosProvider(),
      progressInterval: Duration.zero,
    ),
    sessions: sessions,
    devices: devices,
  );

  test(
    'devices are persisted while the scan streams, gateway and this Mac tagged',
    () async {
      final ping = FakePingProvider(
        alive: {ip('172.16.14.12'), ip('172.16.14.26'), ip('172.16.14.254')},
      );
      final run = await coordinatorWith(
        ping,
      ).start(plan: plan(['172.16.14.0/24']), network: network());

      final seenCounts = <int>[];
      final sub = devices
          .watchDevicesForNetwork(networkId)
          .listen((list) => seenCounts.add(list.length));
      final progress = await run.progress.toList();
      await pumpEventQueue();
      await sub.cancel();

      expect(progress.last.status, ScanSessionStatus.completed);
      expect(progress.last.devicesFoundTotal, 3);
      // The list grew one device at a time, before the scan finished.
      expect(seenCounts, containsAllInOrder([1, 2, 3]));

      final stored = await devices.getDevicesForNetwork(networkId);
      final gateway = stored.singleWhere((d) => d.isGateway);
      expect(gateway.currentIp, ip('172.16.14.254'));
      expect(gateway.inferredType, DeviceType.routerGateway);
      // A fact from the route table, not an inference.
      expect(gateway.confidence, DeviceConfidence.certain);
      final mac = stored.singleWhere((d) => d.isLocalDevice);
      expect(mac.inferredType, DeviceType.mac);
      // Anything the network didn't prove stays unknown in Phase 2.
      final other = stored.singleWhere(
        (d) => d.currentIp == ip('172.16.14.12'),
      );
      expect(other.inferredType, DeviceType.unknown);
      expect(other.confidence, DeviceConfidence.unknown);

      final session = await sessions.getSession(run.sessionId);
      expect(session!.status, ScanSessionStatus.completed);
      expect(session.finishedAt, isNotNull);
      expect(session.hostsScanned, 254);
      expect(session.devicesFound, 3);
    },
  );

  test(
    'same MAC at a new IP (DHCP) stays one device with IP history',
    () async {
      DiscoveredDevice seen(String address, DateTime at) => DiscoveredDevice(
        ipAddress: ip(address),
        respondedAt: at,
        macAddress: 'aa:bb:cc:dd:ee:01',
      );
      await devices.upsertDiscoveredDevice(
        networkId: networkId,
        discovered: seen('172.16.14.40', DateTime(2026, 9, 1)),
        classification: DeviceClassification.unknown,
      );
      await devices.upsertDiscoveredDevice(
        networkId: networkId,
        discovered: seen('172.16.14.41', DateTime(2026, 9, 2)),
        classification: DeviceClassification.unknown,
      );

      final stored = await devices.getDevicesForNetwork(networkId);
      expect(stored, hasLength(1));
      expect(stored.single.currentIp, ip('172.16.14.41'));
      expect(stored.single.firstSeenAt, DateTime(2026, 9, 1));

      final history = await devices.watchObservations(stored.single.id).first;
      expect(history.map((o) => o.ipAddress.toString()), [
        '172.16.14.41',
        '172.16.14.40',
      ]);
    },
  );

  test(
    'temporary IP identity merges into the MAC device once the MAC is learned',
    () async {
      // Device A known by MAC at .40; DHCP moves it to .41 where it's first
      // seen without a MAC (temporary identity), then with its MAC.
      await devices.upsertDiscoveredDevice(
        networkId: networkId,
        discovered: DiscoveredDevice(
          ipAddress: ip('172.16.14.40'),
          respondedAt: DateTime(2026, 9, 1),
          macAddress: 'aa:bb:cc:dd:ee:01',
        ),
        classification: DeviceClassification.unknown,
      );
      final tempId = await devices.upsertDiscoveredDevice(
        networkId: networkId,
        discovered: DiscoveredDevice(
          ipAddress: ip('172.16.14.41'),
          respondedAt: DateTime(2026, 9, 2),
        ),
        classification: DeviceClassification.unknown,
      );
      await devices.updateUserInfo(
        deviceId: tempId,
        customName: null,
        customType: null,
        note: 'masadaki cihaz',
        isKnown: true,
      );
      expect(await devices.getDevicesForNetwork(networkId), hasLength(2));

      await devices.upsertDiscoveredDevice(
        networkId: networkId,
        discovered: DiscoveredDevice(
          ipAddress: ip('172.16.14.41'),
          respondedAt: DateTime(2026, 9, 3),
          macAddress: 'aa:bb:cc:dd:ee:01',
        ),
        classification: DeviceClassification.unknown,
      );

      final stored = await devices.getDevicesForNetwork(networkId);
      expect(stored, hasLength(1));
      expect(stored.single.macAddress, 'aa:bb:cc:dd:ee:01');
      expect(stored.single.note, 'masadaki cihaz');
      final history = await devices.watchObservations(stored.single.id).first;
      expect(history, hasLength(3));
    },
  );

  test(
    'paused scan resumes from its checkpoint after an app restart',
    () async {
      final ping = FakePingProvider(
        alive: {ip('172.16.14.5'), ip('172.16.15.5')},
      );
      late ScanCoordinator coordinator;
      coordinator = coordinatorWith(ping);
      final run = await coordinator.start(
        plan: plan(['172.16.14.0/24', '172.16.15.0/24']),
        network: network(),
      );
      ping.onPing = (address) {
        if (address == ip('172.16.14.100')) run.control.pause();
      };
      final first = await run.progress.toList();
      expect(first.last.status, ScanSessionStatus.paused);

      // Simulate an app that quit while the row still said `running`.
      await sessions.markStatus(
        sessionId: run.sessionId,
        status: ScanSessionStatus.running,
      );
      // "Restart": fresh repositories/coordinator over the same database.
      sessions = DriftScanSessionRepository(database);
      devices = DriftDeviceRepository(database);
      await sessions.markInterruptedSessionsPaused();
      final resumable = await sessions.findResumableSession();
      expect(resumable, isNotNull);
      expect(resumable!.id, run.sessionId);
      expect(resumable.status, ScanSessionStatus.paused);

      final probedBefore = ping.pinged.toSet();
      ping
        ..pinged.clear()
        ..onPing = null;
      final resumed = await coordinatorWith(
        ping,
      ).resume(session: resumable, network: network());
      final second = await resumed.progress.toList();

      expect(second.last.status, ScanSessionStatus.completed);
      expect(ping.pinged.toSet().intersection(probedBefore), isEmpty);
      final stored = await devices.getDevicesForNetwork(networkId);
      expect(stored.map((d) => d.currentIp.toString()).toSet(), {
        '172.16.14.5',
        '172.16.15.5',
      });
      final session = await sessions.getSession(run.sessionId);
      expect(session!.status, ScanSessionStatus.completed);
      expect(session.devicesFound, 2);
      expect(await sessions.findResumableSession(), isNull);
    },
  );

  test('resume refuses a session from a different network', () async {
    final ping = FakePingProvider();
    final run = await coordinatorWith(
      ping,
    ).start(plan: plan(['172.16.14.0/30']), network: network());
    run.control.pause();
    await run.progress.drain<void>();
    final session = (await sessions.getSession(run.sessionId))!;

    final otherNetwork = await database.upsertActiveNetwork(
      interfaceName: 'en0',
      displayName: 'Wi-Fi',
      cidr: '172.16.30.0/24',
      observedAt: DateTime(2026, 9, 2),
    );
    expect(otherNetwork, isNot(networkId));
    expect(
      () => coordinatorWith(ping).resume(
        session: session,
        network: ScanNetworkContext(
          networkId: otherNetwork,
          interfaceName: 'en0',
          interfaceCidr: Cidr.parse('172.16.30.0/24'),
          localAddress: ip('172.16.30.2'),
          localSegments: const [],
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'a device goes offline only after two completed scans miss it',
    () async {
      final ping = FakePingProvider(alive: {ip('172.16.14.12')});
      await (await coordinatorWith(ping).start(
        plan: plan(['172.16.14.0/24']),
        network: network(),
      )).progress.drain<void>();
      Future<DeviceStatus> status() async =>
          (await devices.getDevicesForNetwork(networkId)).single.status;
      expect(await status(), DeviceStatus.online);

      final gone = FakePingProvider();
      await (await coordinatorWith(gone).start(
        plan: plan(['172.16.14.0/24']),
        network: network(),
      )).progress.drain<void>();
      expect(await status(), DeviceStatus.unknown);

      await (await coordinatorWith(gone).start(
        plan: plan(['172.16.14.0/24']),
        network: network(),
      )).progress.drain<void>();
      expect(await status(), DeviceStatus.offline);
    },
  );

  test('a cancelled scan does not age devices', () async {
    final ping = FakePingProvider(alive: {ip('172.16.14.12')});
    await (await coordinatorWith(ping).start(
      plan: plan(['172.16.14.0/24']),
      network: network(),
    )).progress.drain<void>();

    final gone = FakePingProvider();
    final run = await coordinatorWith(
      gone,
    ).start(plan: plan(['172.16.14.0/24']), network: network());
    run.control.cancel();
    final last = (await run.progress.toList()).last;
    expect(last.status, ScanSessionStatus.cancelled);
    expect(
      (await devices.getDevicesForNetwork(networkId)).single.status,
      DeviceStatus.online,
    );
  });

  test(
    'open-port-only host is persisted with a "Port X açık" signal',
    () async {
      final run = await coordinatorWith(
        FakePingProvider(),
        ports: FakePortProbeProvider({
          ip('172.16.20.7'): [22, 443],
        }),
      ).start(plan: plan(['172.16.20.0/24']), network: network());
      await run.progress.drain<void>();

      final device = (await devices.getDevicesForNetwork(networkId)).single;
      expect(device.currentIp, ip('172.16.20.7'));
      final observation =
          (await devices.watchObservations(device.id).first).single;
      expect(
        observation.signals,
        containsAll(['Port 22 açık', 'Port 443 açık']),
      );
    },
  );

  group('network change during a scan', () {
    Future<(List<ScanProgress>, FakePingProvider, int)> scanWhile(
      ScanNetworkProbe probe,
    ) async {
      final ping = FakePingProvider();
      final run = await coordinatorWith(ping, networkProbe: probe).start(
        plan: plan(['172.16.14.0/24', '172.16.15.0/24']),
        network: network(),
      );
      final progress = await run.progress.toList();
      return (progress, ping, run.sessionId);
    }

    test('pauses safely, reports ScanNetworkChangedFailure, never finishes '
        'the old scope on the new network', () async {
      var calls = 0;
      final (progress, ping, sessionId) = await scanWhile(() async {
        calls++;
        // Same network for a while, then the Mac joins another Wi-Fi.
        return calls < 3
            ? network().identity
            : ScanNetworkIdentity(
                networkId: networkId + 1,
                interfaceName: 'en0',
                cidr: Cidr.parse('172.16.30.0/24'),
              );
      });

      final last = progress.last;
      expect(last.status, ScanSessionStatus.paused);
      expect(last.failure, isA<ScanNetworkChangedFailure>());
      // Stopped well short of the full scope.
      expect(ping.pinged.length, lessThan(254 * 2));

      final session = (await sessions.getSession(sessionId))!;
      expect(session.status, ScanSessionStatus.paused);
      expect(session.errorMessage, isNotNull);
      expect(session.isResumable, isTrue);

      // Resuming from the new network is refused…
      await expectLater(
        coordinatorWith(FakePingProvider()).resume(
          session: session,
          network: ScanNetworkContext(
            networkId: networkId + 1,
            interfaceName: 'en0',
            interfaceCidr: Cidr.parse('172.16.30.0/24'),
            localAddress: ip('172.16.30.2'),
            localSegments: const [],
          ),
        ),
        throwsA(isA<ScanNetworkChangedFailure>()),
      );
      // …while back on the original network it continues where it stopped.
      final resumePing = FakePingProvider();
      final resumed = await coordinatorWith(
        resumePing,
      ).resume(session: session, network: network());
      expect(
        (await resumed.progress.toList()).last.status,
        ScanSessionStatus.completed,
      );
      expect(
        resumePing.pinged.toSet().intersection(ping.pinged.toSet()),
        isEmpty,
      );
    });

    test(
      'also pauses when the active network can no longer be detected',
      () async {
        var calls = 0;
        final (progress, _, _) = await scanWhile(() async {
          calls++;
          if (calls < 2) return network().identity;
          throw StateError('ifconfig failed');
        });
        expect(progress.last.status, ScanSessionStatus.paused);
        expect(progress.last.failure, isA<ScanNetworkChangedFailure>());
        expect(
          progress.last.failure!.technicalDetail,
          contains('algılanamadı'),
        );
      },
    );

    test('an unchanged network lets the scan complete', () async {
      final (progress, ping, _) = await scanWhile(
        () async => network().identity,
      );
      expect(progress.last.status, ScanSessionStatus.completed);
      expect(progress.last.failure, isNull);
      expect(ping.pinged, hasLength(254 * 2));
    });
  });

  group('classification', () {
    DiscoveredDevice seen({String? hostname, String? netbios, int? ttl}) =>
        DiscoveredDevice(
          ipAddress: ip('172.16.14.40'),
          respondedAt: clock(),
          macAddress: 'aa:bb:cc:dd:ee:40',
          hostname: hostname,
          netbiosName: netbios,
          ttl: ttl,
        );

    test('vendor from OUI and the classifier verdict are stored', () async {
      final run = await coordinatorWith(
        FakePingProvider(alive: {ip('172.16.14.40')}),
        arp: FakeArpTableProvider(
          lookupResults: {ip('172.16.14.40'): 'a4:83:e7:00:00:40'},
        ),
        mdns: FakeMdnsProvider({
          ip('172.16.14.40'): [
            const MdnsServiceRecord(
              instanceName: 'Johns iPhone',
              serviceType: '_device-info._tcp',
              hostname: 'Johns-iPhone.local',
              txt: {'model': 'iPhone15,2'},
            ),
          ],
        }),
        oui: const FakeOuiLookup({'a4:83:e7': 'Apple, Inc.'}),
      ).start(plan: plan(['172.16.14.0/24']), network: network());
      await run.progress.drain<void>();

      final device = (await devices.getDevicesForNetwork(networkId)).single;
      expect(device.vendor, 'Apple, Inc.');
      // mDNS host name fills in when reverse DNS has none.
      expect(device.hostname, 'Johns-iPhone.local');
      expect(device.inferredType, DeviceType.phone);
      expect(device.confidence, DeviceConfidence.highProbability);
      expect(device.inferredOs, 'iOS');
      expect(device.osConfidence, DeviceConfidence.highProbability);
      expect(
        device.inferenceReasons,
        contains('mDNS cihaz modeli "iPhone15,2"'),
      );
    });

    test('a later, weaker verdict never downgrades a stronger one', () async {
      const classifier = DeviceClassifier();
      final strong = seen(
        hostname: 'DESKTOP-AB12CD3',
        netbios: 'DESKTOP-AB12CD3',
        ttl: 128,
      );
      await devices.upsertDiscoveredDevice(
        networkId: networkId,
        discovered: strong,
        classification: classifier.classify(device: strong),
      );
      final before = (await devices.getDevicesForNetwork(networkId)).single;
      expect(before.inferredType, DeviceType.windowsComputer);
      expect(before.confidence, DeviceConfidence.highProbability);

      // Next scan: no hostname, nothing to go on.
      final weak = seen();
      await devices.upsertDiscoveredDevice(
        networkId: networkId,
        discovered: weak,
        classification: classifier.classify(device: weak),
      );
      final after = (await devices.getDevicesForNetwork(networkId)).single;
      expect(after.inferredType, DeviceType.windowsComputer);
      expect(after.confidence, DeviceConfidence.highProbability);
      expect(after.inferredOs, 'Windows');
      expect(after.inferenceReasons, before.inferenceReasons);
    });

    test(
      'user name/type/note/known survive later scans and can be cleared',
      () async {
        const classifier = DeviceClassifier();
        final first = seen(hostname: 'DESKTOP-AB12CD3');
        final id = await devices.upsertDiscoveredDevice(
          networkId: networkId,
          discovered: first,
          classification: classifier.classify(device: first),
        );
        await devices.updateUserInfo(
          deviceId: id,
          customName: '  Muhasebe PC  ',
          customType: DeviceType.linuxComputerServer,
          note: 'Dual boot',
          isKnown: true,
        );

        final again = seen(hostname: 'DESKTOP-AB12CD3', ttl: 128);
        await devices.upsertDiscoveredDevice(
          networkId: networkId,
          discovered: again,
          classification: classifier.classify(device: again),
        );
        var device = (await devices.getDevicesForNetwork(networkId)).single;
        expect(device.customName, 'Muhasebe PC');
        expect(device.customType, DeviceType.linuxComputerServer);
        expect(device.effectiveType, DeviceType.linuxComputerServer);
        expect(device.inferredType, DeviceType.windowsComputer);
        expect(device.note, 'Dual boot');
        expect(device.isKnown, isTrue);
        expect(device.displayName, 'Muhasebe PC');

        await devices.updateUserInfo(
          deviceId: id,
          customName: '',
          customType: null,
          note: null,
          isKnown: false,
        );
        device = (await devices.getDevicesForNetwork(networkId)).single;
        expect(device.customName, isNull);
        expect(device.customType, isNull);
        expect(device.effectiveType, DeviceType.windowsComputer);
        expect(device.isKnown, isFalse);
      },
    );
  });
}
