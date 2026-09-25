import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_monitor/features/traffic/domain/entities/router_credentials.dart';
import 'package:network_monitor/features/traffic/domain/failures/traffic_failures.dart';
import 'package:network_monitor/features/traffic/infrastructure/keychain_router_credential_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('network_monitor/keychain');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Map<String, String> keychain;
  late List<MethodCall> calls;

  setUp(() {
    keychain = {};
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final args = (call.arguments as Map).cast<String, String>();
      final account = args['account']!;
      switch (call.method) {
        case 'read':
          return keychain[account];
        case 'write':
          keychain[account] = args['value']!;
          return null;
        case 'delete':
          keychain.remove(account);
          return null;
      }
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  const store = KeychainRouterCredentialStore();

  test('saves, reads back and deletes per provider id', () async {
    expect(await store.read('openwrt'), isNull);
    await store.save(
      'openwrt',
      const RouterCredentials(username: 'admin', password: 's3cret'),
    );
    final read = await store.read('openwrt');
    expect(read!.username, 'admin');
    expect(read.password, 's3cret');
    expect(read.token, isNull);
    expect(await store.read('unifi'), isNull);

    await store.delete('openwrt');
    expect(await store.read('openwrt'), isNull);
  });

  test('Keychain errors surface as a failure without the secret', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'keychain_error',
        message: 'OSStatus -25308',
      );
    });
    await expectLater(
      store.save('openwrt', const RouterCredentials(password: 's3cret')),
      throwsA(
        isA<RouterCredentialStoreUnavailableFailure>().having(
          (f) => f.toString(),
          'toString',
          isNot(contains('s3cret')),
        ),
      ),
    );
  });

  test('credentials never print their secrets', () {
    const credentials = RouterCredentials(
      username: 'admin',
      password: 's3cret',
      token: 'T0KEN-XYZ',
    );
    expect(credentials.toString(), isNot(contains('s3cret')));
    expect(credentials.toString(), isNot(contains('T0KEN-XYZ')));
  });
}
