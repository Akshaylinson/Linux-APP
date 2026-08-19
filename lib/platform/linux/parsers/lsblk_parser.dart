import 'dart:convert';

import '../../../models/disk_info.dart';
import '../../../models/filesystem_info.dart';
import '../../../models/partition_info.dart';
import '../../../models/storage_snapshot.dart';

class LsblkParser {
  StorageSnapshot parse({
    required String lsblkJson,
    required String dfOutput,
  }) {
    final decoded = jsonDecode(lsblkJson) as Map<String, dynamic>;
    final disks = <DiskInfo>[];
    final partitions = <PartitionInfo>[];

    void visit(Map<String, dynamic> node, {String? parentDevice}) {
      final children = (node['children'] as List<dynamic>? ?? const []);
      final device = (node['path'] as String?) ?? (node['name'] as String?) ?? '';
      final sizeText = (node['size'] as String?) ?? '0';
      final model = (node['model'] as String?)?.trim().isEmpty == true
          ? 'Unknown'
          : (node['model'] as String?)?.trim() ?? 'Unknown';
      final type = (node['type'] as String?) ?? 'disk';
      final tran = (node['tran'] as String?) ?? 'unknown';
      final mountpoint = (node['mountpoint'] as String?)?.trim();
      final label = (node['label'] as String?)?.trim();
      final fsType = (node['fstype'] as String?) ?? 'unknown';
      final sizeBytes = _parseHumanSize(sizeText);

      if (type == 'disk') {
        disks.add(
          DiskInfo(
            device: device,
            model: model,
            sizeBytes: sizeBytes,
            type: type,
            interfaceType: tran,
            mountPoints: [
              if (mountpoint != null && mountpoint.isNotEmpty) mountpoint,
            ],
            state: node['state'] as String?,
          ),
        );
      } else if (type == 'part') {
        partitions.add(
          PartitionInfo(
            device: device,
            name: label?.isNotEmpty == true ? label! : (mountpoint ?? device),
            sizeBytes: sizeBytes,
            mountPoint: mountpoint ?? '',
            fileSystemType: fsType,
          ),
        );
      }

      for (final child in children) {
        visit(child as Map<String, dynamic>, parentDevice: device);
      }
    }

    for (final node in decoded['blockdevices'] as List<dynamic>? ?? const []) {
      visit(node as Map<String, dynamic>);
    }

    return StorageSnapshot(
      disks: disks,
      partitions: partitions,
      filesystems: _parseDf(dfOutput),
      folderUsage: const {},
    );
  }

  List<FilesystemInfo> _parseDf(String output) {
    final lines = output.trim().split('\n');
    if (lines.length <= 1) return const [];

    final filesystems = <FilesystemInfo>[];
    for (var i = 1; i < lines.length; i++) {
      final parts = lines[i].trim().split(RegExp(r'\s+'));
      if (parts.length < 6) continue;
      final device = parts[0];
      final total = int.tryParse(parts[1]) ?? 0;
      final used = int.tryParse(parts[2]) ?? 0;
      final available = int.tryParse(parts[3]) ?? 0;
      final usage = double.tryParse(parts[4].replaceAll('%', '')) ?? 0;
      final mountPoint = parts.sublist(5).join(' ');
      if (_isPseudoFilesystem(mountPoint, device)) {
        continue;
      }
      filesystems.add(
        FilesystemInfo(
          device: device,
          mountPoint: mountPoint,
          totalBytes: total,
          usedBytes: used,
          availableBytes: available,
          usagePercent: usage,
          fileSystemType: 'unknown',
        ),
      );
    }
    return filesystems;
  }

  bool _isPseudoFilesystem(String mountPoint, String device) {
    const ignoredPrefixes = ['/proc', '/sys', '/dev', '/run'];
    if (ignoredPrefixes.any(mountPoint.startsWith)) return true;
    return device == 'tmpfs' || device == 'devtmpfs' || device == 'overlay';
  }

  int _parseHumanSize(String value) {
    final match = RegExp(r'^([\d.]+)\s*([KMGTP]?)(i?B)?$').firstMatch(value);
    if (match == null) return int.tryParse(value) ?? 0;
    final number = double.parse(match.group(1)!);
    final unit = match.group(2)!;
    const multipliers = {
      '': 1,
      'K': 1024,
      'M': 1024 * 1024,
      'G': 1024 * 1024 * 1024,
      'T': 1024 * 1024 * 1024 * 1024,
      'P': 1024 * 1024 * 1024 * 1024 * 1024,
    };
    return (number * (multipliers[unit] ?? 1)).round();
  }
}
