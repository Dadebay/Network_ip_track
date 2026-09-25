/// IEEE OUI (MAC prefix) -> organization name.
abstract interface class OuiLookup {
  /// False when no OUI data is installed; every lookup then returns null
  /// ("Bilinmiyor"), never a guess.
  bool get isAvailable;

  /// The registered organization for a normalized MAC
  /// (`aa:bb:cc:dd:ee:ff`), or null when unregistered or the MAC is locally
  /// administered (randomized/private addresses carry no vendor).
  String? vendorFor(String normalizedMac);
}
