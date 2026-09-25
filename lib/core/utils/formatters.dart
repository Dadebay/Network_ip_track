// Display formatting shared by presentation code. Turkish conventions:
// `.` thousands separator, `dd.MM.yyyy HH:mm` dates.

String formatCount(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String formatDuration(Duration duration) {
  if (duration.inSeconds < 60) return '${duration.inSeconds} sn';
  if (duration.inMinutes < 60) {
    final seconds = duration.inSeconds % 60;
    return seconds == 0
        ? '${duration.inMinutes} dk'
        : '${duration.inMinutes} dk $seconds sn';
  }
  if (duration.inHours < 48) {
    final minutes = duration.inMinutes % 60;
    return minutes == 0
        ? '${duration.inHours} sa'
        : '${duration.inHours} sa $minutes dk';
  }
  return '${duration.inDays} gün ${duration.inHours % 24} sa';
}

String formatDateTime(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} '
      '${two(local.hour)}:${two(local.minute)}';
}
