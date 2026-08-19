class FilesystemInfo {
  const FilesystemInfo({
    required this.device,
    required this.mountPoint,
    required this.totalBytes,
    required this.usedBytes,
    required this.availableBytes,
    required this.usagePercent,
    required this.fileSystemType,
    this.isPseudo = false,
  });

  final String device;
  final String mountPoint;
  final int totalBytes;
  final int usedBytes;
  final int availableBytes;
  final double usagePercent;
  final String fileSystemType;
  final bool isPseudo;
}
