class MemoryInfo {
  const MemoryInfo({
    required this.totalBytes,
    required this.usedBytes,
    required this.availableBytes,
    required this.cachedBytes,
    required this.swapTotalBytes,
    required this.swapUsedBytes,
  });

  final int totalBytes;
  final int usedBytes;
  final int availableBytes;
  final int cachedBytes;
  final int swapTotalBytes;
  final int swapUsedBytes;

  double get usagePercent =>
      totalBytes == 0 ? 0 : (usedBytes / totalBytes) * 100;
}
