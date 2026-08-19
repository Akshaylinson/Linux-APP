import 'disk_info.dart';
import 'filesystem_info.dart';
import 'folder_usage.dart';
import 'partition_info.dart';

class StorageSnapshot {
  const StorageSnapshot({
    required this.disks,
    required this.partitions,
    required this.filesystems,
    required this.folderUsage,
  });

  final List<DiskInfo> disks;
  final List<PartitionInfo> partitions;
  final List<FilesystemInfo> filesystems;
  final Map<String, List<FolderUsage>> folderUsage;
}
