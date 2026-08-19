class FolderUsage {
  const FolderUsage({
    required this.path,
    required this.displayName,
    required this.sizeBytes,
    this.error,
  });

  final String path;
  final String displayName;
  final int sizeBytes;
  final String? error;
}
