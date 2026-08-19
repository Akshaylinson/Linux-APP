class GpuInfo {
  const GpuInfo({
    required this.vendor,
    required this.model,
    required this.status,
    this.driver,
    this.temperatureC,
    this.memoryUsedBytes,
    this.memoryTotalBytes,
  });

  final String vendor;
  final String model;
  final String status;
  final String? driver;
  final double? temperatureC;
  final int? memoryUsedBytes;
  final int? memoryTotalBytes;
}
