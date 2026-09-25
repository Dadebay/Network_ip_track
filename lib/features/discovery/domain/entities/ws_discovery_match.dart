/// One WS-Discovery `ProbeMatch`: what a device (Windows PC, printer, ONVIF
/// camera) says it is.
class WsDiscoveryMatch {
  const WsDiscoveryMatch({this.types = const [], this.scopes = const []});

  /// e.g. `dn:NetworkVideoTransmitter`, `pub:Computer`.
  final List<String> types;

  /// e.g. `onvif://www.onvif.org/hardware/DS-2CD2143G0-I`.
  final List<String> scopes;

  /// Value of the first ONVIF scope under [category] (`name`, `hardware`),
  /// URL-decoded.
  String? onvifScope(String category) {
    final prefix = 'onvif://www.onvif.org/$category/';
    for (final scope in scopes) {
      if (scope.toLowerCase().startsWith(prefix)) {
        final value = scope.substring(prefix.length);
        try {
          return Uri.decodeComponent(value).trim();
        } on ArgumentError {
          return value;
        }
      }
    }
    return null;
  }

  String describe() => [
    'WS-Discovery',
    if (types.isNotEmpty) types.join(' '),
    ?onvifScope('hardware'),
  ].join(' · ');
}
