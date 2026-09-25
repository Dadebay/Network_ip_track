import '../../../../core/utils/ipv4_address.dart';

/// What a device's own web interface says about itself.
class HttpBanner {
  const HttpBanner({required this.port, this.title, this.server, this.realm});

  final int port;

  /// `<title>` of the front page.
  final String? title;

  /// `Server` response header.
  final String? server;

  /// `WWW-Authenticate` realm — often the device model on cameras/NVRs.
  final String? realm;

  bool get isEmpty => title == null && server == null && realm == null;

  /// One line for storage/display, e.g. `Web:80 · WEB SERVICE · realm=IPC`.
  String describe() => [
    'Web:$port',
    ?title,
    if (server != null) 'server=$server',
    if (realm != null) 'realm=$realm',
  ].join(' · ');

  /// Lowercased text the classifier matches against.
  String get searchText =>
      [title, server, realm].whereType<String>().join(' ').toLowerCase();

  /// Parses [describe] output back (for re-classifying stored devices).
  static HttpBanner? tryParse(String line) {
    if (!line.startsWith('Web:')) return null;
    final parts = line.split(' · ');
    final port = int.tryParse(parts.first.substring(4));
    if (port == null) return null;
    String? title;
    String? server;
    String? realm;
    for (final part in parts.skip(1)) {
      if (part.startsWith('server=')) {
        server = part.substring(7);
      } else if (part.startsWith('realm=')) {
        realm = part.substring(6);
      } else {
        title = part;
      }
    }
    return HttpBanner(port: port, title: title, server: server, realm: realm);
  }
}

/// Fetches the front page of a device's web interface — one GET of `/`, no
/// credentials, no redirects followed — for classification only.
abstract interface class HttpBannerProvider {
  Future<HttpBanner?> fetch(
    Ipv4Address address,
    int port, {
    required Duration timeout,
  });
}
