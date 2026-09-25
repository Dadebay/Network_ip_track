import '../../discovery/domain/entities/discovered_device.dart';

/// A name and model the device announces about itself, beyond its
/// hostname: UPnP description, mDNS/Bonjour names and TXT records, and the
/// web interface title.
class DeviceIdentity {
  const DeviceIdentity({this.name, this.model, this.webPort});

  final String? name;
  final String? model;

  /// Port of the device's web interface, when one answered or was open.
  final int? webPort;
}

const _webPorts = [80, 8080, 443, 8443];

/// mDNS services whose instance name is a user-facing device name rather
/// than a technical identifier.
const _namedServices = {
  '_airplay._tcp',
  '_raop._tcp',
  '_googlecast._tcp',
  '_ipp._tcp',
  '_ipps._tcp',
  '_printer._tcp',
  '_pdl-datastream._tcp',
  '_device-info._tcp',
  '_companion-link._tcp',
  '_hap._tcp',
  '_homekit._tcp',
  '_smb._tcp',
  '_afpovertcp._tcp',
  '_spotify-connect._tcp',
};

final _genericTitle = RegExp(
  r'^(log ?in|sign ?in|index|home( page)?|web( service| server| management)?'
  r'|webserver|http server|document|untitled|default|main|admin'
  r'|management|loading.*|redirect.*|welcome.*|error.*|\d{3}\b.*'
  r'|(wireless )?router( login)?|web ?ui|mini_httpd|lighttpd|nginx|apache)$',
  caseSensitive: false,
);

DeviceIdentity deriveDeviceIdentity(DiscoveredDevice device) {
  final upnp = device.upnp;
  final banner = device.httpBanner;

  String? name = _clean(_upnpFriendlyName(upnp?.friendlyName));
  String? model = _clean(upnp?.model);

  for (final record in device.mdnsRecords) {
    name ??= _clean(record.txt['fn']);
    if (_namedServices.contains(record.serviceType)) {
      name ??= _clean(_mdnsInstanceName(record.instanceName));
    }
    model ??= _clean(
      record.txt['md'] ??
          record.txt['ty'] ??
          record.txt['usb_MDL'] ??
          record.txt['model'],
    );
  }

  model ??= _meaningfulTitle(banner?.title) ?? _meaningfulTitle(banner?.realm);

  if (name != null && model != null && _same(name, model)) name = null;

  final webPort =
      banner?.port ?? _webPorts.where(device.openPorts.contains).firstOrNull;
  return DeviceIdentity(name: name, model: model, webPort: webPort);
}

/// Windows Media sharing reports `PC-NAME: user:`; keep the machine name.
String? _upnpFriendlyName(String? value) {
  if (value == null) return null;
  final match = RegExp(r'^([^:]+):\s').firstMatch(value);
  return match?.group(1) ?? value;
}

/// AirPlay audio (RAOP) instances are `AABBCCDDEEFF@Living Room`.
String? _mdnsInstanceName(String value) {
  final at = value.indexOf('@');
  final name = at == -1 ? value : value.substring(at + 1);
  // Skip opaque ids (serial numbers, UUIDs) some devices use as the name.
  final opaque =
      RegExp(r'^[0-9A-Za-z_-]{12,}$').hasMatch(name) &&
      RegExp(r'\d').allMatches(name).length >= 3;
  if (opaque) return null;
  return name;
}

String? _meaningfulTitle(String? value) {
  final text = _clean(value);
  if (text == null || _genericTitle.hasMatch(text)) return null;
  if (!RegExp(r'[A-Za-z]').hasMatch(text)) return null;
  return text;
}

String? _clean(String? value) {
  if (value == null) return null;
  final text = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.length < 2) return null;
  if (RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(text)) return null;
  if (RegExp(
    r'^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$',
    caseSensitive: false,
  ).hasMatch(text)) {
    return null;
  }
  return text.length > 60 ? '${text.substring(0, 60)}…' : text;
}

bool _same(String a, String b) => a.toLowerCase() == b.toLowerCase();
