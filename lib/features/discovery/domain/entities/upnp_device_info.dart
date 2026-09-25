/// What a device's UPnP description XML says about itself.
class UpnpDeviceInfo {
  const UpnpDeviceInfo({
    this.friendlyName,
    this.manufacturer,
    this.modelName,
    this.modelNumber,
  });

  final String? friendlyName;
  final String? manufacturer;
  final String? modelName;
  final String? modelNumber;

  bool get isEmpty =>
      friendlyName == null &&
      manufacturer == null &&
      modelName == null &&
      modelNumber == null;

  /// `modelName modelNumber`, without repeating a number the name already
  /// contains.
  String? get model {
    final name = modelName;
    final number = modelNumber;
    if (name == null) return number;
    if (number == null || name.contains(number)) return name;
    return '$name $number';
  }

  String describe() =>
      ['UPnP', ?friendlyName, ?model, ?manufacturer].join(' · ');
}
