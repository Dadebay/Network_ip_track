import '../entities/network_interface_info.dart';

/// Platform adapter contract for enumerating network interfaces. macOS and
/// (later) Windows implementations live in `infrastructure/`; nothing above
/// this interface may depend on OS-specific commands or APIs.
abstract interface class NetworkInterfaceProvider {
  Future<List<NetworkInterfaceInfo>> listInterfaces();
}
