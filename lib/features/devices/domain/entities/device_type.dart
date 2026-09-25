/// Device type buckets from the spec's "Cihaz sınıflandırma" list.
enum DeviceType {
  phone,
  tablet,
  windowsComputer,
  mac,
  linuxComputerServer,
  routerGateway,
  printer,
  smartTvMedia,
  iotSmartHome,
  gameConsole,
  camera,
  unknown;

  String get label => switch (this) {
    DeviceType.phone => 'Telefon',
    DeviceType.tablet => 'Tablet',
    DeviceType.windowsComputer => 'Windows bilgisayar',
    DeviceType.mac => 'Mac',
    DeviceType.linuxComputerServer => 'Linux bilgisayar/sunucu',
    DeviceType.routerGateway => 'Router/gateway',
    DeviceType.printer => 'Yazıcı',
    DeviceType.smartTvMedia => 'Akıllı TV/medya cihazı',
    DeviceType.iotSmartHome => 'IoT/akıllı ev',
    DeviceType.gameConsole => 'Oyun konsolu',
    DeviceType.camera => 'Kamera',
    DeviceType.unknown => 'Bilinmiyor',
  };
}
