class PartitionInfo {
  const PartitionInfo({
    required this.device,
    required this.name,
    required this.sizeBytes,
    required this.mountPoint,
    required this.fileSystemType,
    this.label,
    this.usedBytes,
    this.availableBytes,
    this.usagePercent,
  });

  final String device;
  final String name;
  final int sizeBytes;
  final String mountPoint;
  final String fileSystemType;
  final String? label;
  final int? usedBytes;
  final int? availableBytes;
  final double? usagePercent;
}
