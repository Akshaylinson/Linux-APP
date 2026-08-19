import '../models/folder_usage.dart';
import '../models/storage_snapshot.dart';
import '../platform/linux/linux_storage_provider.dart';

class StorageService {
  StorageService(this._provider);

  final LinuxStorageProvider _provider;

  Future<StorageSnapshot> loadSnapshot() => _provider.readStorageSnapshot();

  Future<List<FolderUsage>> scanFolderUsage(
    String path, {
    int depth = 2,
    int maxEntries = 20,
  }) {
    return _provider.scanFolderUsage(
      path,
      depth: depth,
      maxEntries: maxEntries,
    );
  }
}
