import 'dart:convert';
import 'dart:io';

import '../../core/errors/app_exception.dart';
import '../../core/utils/file_utils.dart';
import '../../models/folder_usage.dart';
import '../../models/storage_snapshot.dart';
import 'linux_command_runner.dart';
import 'parsers/lsblk_parser.dart';

class LinuxStorageProvider {
  LinuxStorageProvider(this._runner);

  final LinuxCommandRunner _runner;
  final LsblkParser _parser = LsblkParser();
  final Map<String, _FolderCache> _folderCache = {};

  Future<StorageSnapshot> readStorageSnapshot() async {
    try {
      final lsblk = await _runner.run(
        'lsblk',
        const [
          '--json',
          '-o',
          'NAME,PATH,MODEL,SIZE,TYPE,FSTYPE,MOUNTPOINT,LABEL,TRAN,STATE',
        ],
        timeout: const Duration(seconds: 4),
      );
      final df = await _runner.run(
        'df',
        const ['-B1', '-P', '-x', 'tmpfs', '-x', 'devtmpfs', '-x', 'overlay'],
        timeout: const Duration(seconds: 4),
      );
      if (lsblk.success && df.success) {
        return _parser.parse(lsblkJson: lsblk.stdout, dfOutput: df.stdout);
      }
    } catch (_) {
      // Fall through to mock data.
    }

    return StorageSnapshot(
      disks: const [],
      partitions: const [],
      filesystems: const [],
      folderUsage: const {},
    );
  }

  Future<List<FolderUsage>> scanFolderUsage(
    String rootPath, {
    int depth = 2,
    int maxEntries = 20,
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    final now = DateTime.now();
    final cached = _folderCache[rootPath];
    if (cached != null && now.difference(cached.timestamp) < cacheDuration) {
      return cached.items;
    }

    final target = Directory(_expandHome(rootPath));
    if (!await target.exists()) {
      return const [];
    }

    final items = <FolderUsage>[];
    try {
      await for (final entity in target.list(followLinks: false)) {
        try {
          final stat = await entity.stat();
          if (entity is Directory) {
            final size = await _measureDirectory(entity, maxDepth: depth);
            items.add(
              FolderUsage(
                path: entity.path,
                displayName: _basename(entity.path),
                sizeBytes: size,
              ),
            );
          } else if (entity is File) {
            items.add(
              FolderUsage(
                path: entity.path,
                displayName: _basename(entity.path),
                sizeBytes: stat.size,
              ),
            );
          }
        } catch (error) {
          items.add(
            FolderUsage(
              path: entity.path,
              displayName: _basename(entity.path),
              sizeBytes: 0,
              error: error.toString(),
            ),
          );
        }
      }
    } catch (error) {
      throw AppException('Directory scan failed', details: error);
    }

    items.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    final truncated = items.take(maxEntries).toList(growable: false);
    _folderCache[rootPath] = _FolderCache(now, truncated);
    return truncated;
  }

  Future<int> _measureDirectory(Directory directory, {required int maxDepth}) async {
    var total = 0;
    try {
      await for (final entity in directory.list(followLinks: false)) {
        try {
          final stat = await entity.stat();
          if (entity is File) {
            total += stat.size;
            continue;
          }
          if (entity is Directory && maxDepth > 0) {
            total += await _measureDirectory(entity, maxDepth: maxDepth - 1);
          }
        } catch (_) {
          continue;
        }
      }
    } catch (_) {
      return total;
    }
    return total;
  }

  String _expandHome(String path) {
    if (!path.startsWith('~')) return path;
    final home = Platform.environment['HOME'] ?? '';
    return path.replaceFirst('~', home);
  }

  String _basename(String path) {
    final trimmed = path.replaceAll(RegExp(r'[/\\]+$'), '');
    final parts = trimmed.split(Platform.pathSeparator);
    return parts.isEmpty ? trimmed : parts.last;
  }
}

class _FolderCache {
  _FolderCache(this.timestamp, this.items);

  final DateTime timestamp;
  final List<FolderUsage> items;
}
