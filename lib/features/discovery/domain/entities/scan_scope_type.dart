/// The four scope options from the spec's "Tarama kapsamı ve büyük ağ
/// yönetimi" section.
enum ScanScopeType {
  /// `Bu alt ağı tara` — the currently active interface's own /24 (or
  /// whatever prefix it has).
  currentSubnet,

  /// `Erişilebilir tüm özel 172 ağlarını tara` — every private-172 subnet
  /// the route table says is reachable. Suggested default.
  allAccessiblePrivate172,

  /// `Özel CIDR ekle` — a user-supplied CIDR, validated to lie fully inside
  /// `172.16.0.0/12`.
  customCidr,

  /// `Tüm özel 172 bloğunu tara` — the entire `172.16.0.0/12` block.
  /// Advanced option: requires explicit confirmation and always runs as a
  /// chunked, pausable/resumable queue.
  fullPrivate172Block,
}
