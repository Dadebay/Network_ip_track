/// One Bonjour/mDNS service instance a host advertises.
class MdnsServiceRecord {
  const MdnsServiceRecord({
    required this.instanceName,
    required this.serviceType,
    this.hostname,
    this.txt = const {},
  });

  final String instanceName;

  /// Normalized without the trailing dot, e.g. `_ipp._tcp`.
  final String serviceType;

  /// The `.local` host the instance resolves to, without the trailing dot.
  final String? hostname;

  /// TXT record key/values (keys lowercased), e.g. `model=MacBookPro18,3`,
  /// `md=Chromecast`, `ty=HP LaserJet`.
  final Map<String, String> txt;

  /// One-line summary for storage/display.
  String describe() {
    final model = txt['model'] ?? txt['md'] ?? txt['ty'];
    return model == null
        ? '$instanceName ($serviceType)'
        : '$instanceName ($serviceType) · $model';
  }
}
