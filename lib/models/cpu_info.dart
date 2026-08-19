class CpuInfo {
  const CpuInfo({
    required this.model,
    required this.coreCount,
    required this.threadCount,
    required this.usagePercent,
    this.perCoreUsage = const [],
    this.frequencyMhz,
    this.loadAverage,
  });

  final String model;
  final int coreCount;
  final int threadCount;
  final double usagePercent;
  final List<double> perCoreUsage;
  final double? frequencyMhz;
  final List<double>? loadAverage;
}
