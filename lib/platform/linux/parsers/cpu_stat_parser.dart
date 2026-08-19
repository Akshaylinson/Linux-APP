import '../../../models/cpu_info.dart';

class CpuStatParser {
  CpuInfo parse({
    required String cpuInfo,
    required String procStat,
    required double usagePercent,
    required List<double> perCoreUsage,
    required List<double> loadAverage,
  }) {
    final modelMatch = RegExp(r'model name\s+:\s+(.+)').firstMatch(cpuInfo);
    final cores = RegExp(r'^cpu\d+', multiLine: true)
        .allMatches(procStat)
        .length;
    final threads = RegExp(r'^processor\s+:\s+\d+', multiLine: true)
        .allMatches(cpuInfo)
        .length;
    final frequencyMatch = RegExp(r'cpu MHz\s+:\s+([\d.]+)').firstMatch(cpuInfo);

    return CpuInfo(
      model: modelMatch?.group(1)?.trim() ?? 'Unknown CPU',
      coreCount: cores == 0 ? threads : cores,
      threadCount: threads == 0 ? cores : threads,
      usagePercent: usagePercent,
      perCoreUsage: perCoreUsage,
      frequencyMhz: double.tryParse(frequencyMatch?.group(1) ?? ''),
      loadAverage: loadAverage,
    );
  }
}
