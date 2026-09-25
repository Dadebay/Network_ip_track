/// Byte count -> human-readable size. Presentation-only: the database and
/// domain always carry integer bytes.
///
/// Decimal (default): 1 MB = 1000² bytes. Binary: 1 MiB = 1024² bytes.
/// Uses a Turkish decimal comma (`1,5 GB`) and drops a trailing `,0`.
String formatBytes(int bytes, {bool binary = false}) {
  final base = binary ? 1024 : 1000;
  final units = binary
      ? const ['B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB']
      : const ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];

  final sign = bytes < 0 ? '-' : '';
  var value = bytes.abs().toDouble();
  var unit = 0;
  while (value >= base && unit < units.length - 1) {
    value /= base;
    unit++;
  }
  if (unit == 0) return '$sign${bytes.abs()} B';

  // 1 decimal below 100, none above ("1,5 MB", "12,3 GB", "250 MB").
  var text = value.toStringAsFixed(value < 100 ? 1 : 0);
  // Rounding can reach the next unit ("999,95 KB" -> "1000,0 KB").
  if (double.parse(text) >= base && unit < units.length - 1) {
    unit++;
    text = (value / base).toStringAsFixed(1);
  }
  if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
  return '$sign${text.replaceAll('.', ',')} ${units[unit]}';
}
