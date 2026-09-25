/// Online/offline/unknown per the spec — never derived from a single failed
/// ping (see spec limitation #6).
enum DeviceStatus {
  online('Online'),
  offline('Offline'),
  unknown('Bilinmiyor');

  const DeviceStatus(this.label);
  final String label;
}
