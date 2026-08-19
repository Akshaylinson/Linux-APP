import '../../models/memory_info.dart';

class MeminfoParser {
  MemoryInfo parse(String input) {
    final values = <String, int>{};
    for (final line in input.split('\n')) {
      final match = RegExp(r'^([A-Za-z_()]+):\s+(\d+)').firstMatch(line);
      if (match != null) {
        values[match.group(1)!] = int.parse(match.group(2)!) * 1024;
      }
    }

    final total = values['MemTotal'] ?? 0;
    final available = values['MemAvailable'] ?? 0;
    final cached = (values['Cached'] ?? 0) + (values['Buffers'] ?? 0);
    final used = total == 0 ? 0 : total - available;
    final swapTotal = values['SwapTotal'] ?? 0;
    final swapFree = values['SwapFree'] ?? 0;

    return MemoryInfo(
      totalBytes: total,
      usedBytes: used,
      availableBytes: available,
      cachedBytes: cached,
      swapTotalBytes: swapTotal,
      swapUsedBytes: swapTotal - swapFree,
    );
  }
}
