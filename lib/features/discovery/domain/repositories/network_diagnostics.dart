import '../../../../core/utils/ipv4_address.dart';

/// Runs each discovery tool once against [target] from inside the app (so
/// under the app's own sandbox) and reports exactly what happened — exit
/// codes and error output included — to explain why a scan found less than
/// expected.
abstract interface class NetworkDiagnostics {
  Future<String> run(Ipv4Address target);
}
