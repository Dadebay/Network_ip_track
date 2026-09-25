import '../../../../core/utils/ipv4_address.dart';
import '../entities/upnp_device_info.dart';

/// Reads a device's UPnP description XML (the SSDP `LOCATION` URL) — one
/// GET, no credentials — for its name and model.
abstract interface class UpnpDescriptionProvider {
  /// Null when [location] doesn't point at [address] itself, or the fetch
  /// fails or says nothing useful.
  Future<UpnpDeviceInfo?> fetch(
    Ipv4Address address,
    String location, {
    required Duration timeout,
  });
}
