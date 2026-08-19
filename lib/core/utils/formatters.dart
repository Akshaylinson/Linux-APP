import 'dart:math';

String formatBytes(num bytes) {
  final abs = bytes.abs();
  if (abs < 1024) return '${bytes.toStringAsFixed(0)} B';
  const units = ['KB', 'MB', 'GB', 'TB', 'PB'];
  var value = bytes.toDouble();
  var index = -1;
  do {
    value /= 1024;
    index++;
  } while (value >= 1024 && index < units.length - 1);
  return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[index]}';
}

String formatPercent(num value) => '${value.toStringAsFixed(1)}%';

String formatTemperature(num? value, {bool fahrenheit = false}) {
  if (value == null) return 'N/A';
  final display = fahrenheit ? (value * 9 / 5) + 32 : value;
  return '${display.toStringAsFixed(display % 1 == 0 ? 0 : 1)}${fahrenheit ? 'F' : 'C'}';
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${duration.inMinutes}m';
}

double clampPercent(num value) => max(0, min(100, value.toDouble()));
