/// Physical/virtual classification of a network interface, used to label
/// loopback/VPN/bridge/virtual interfaces in the UI per the spec.
enum InterfaceKind {
  wifi,
  ethernet,
  loopback,
  vpn,
  bridge,
  virtual,
  other;

  bool get isPhysicalCandidate => this == wifi || this == ethernet;
}
