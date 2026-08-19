import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/disk_info.dart';
import '../../models/filesystem_info.dart';
import '../../models/folder_usage.dart';
import '../../models/partition_info.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/usage_bar.dart';

class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  String _selectedPath = '/';

  static const _paths = ['/', '/home', '~/Downloads', '~/Documents', '~/Projects'];

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(storageSnapshotProvider);
    final settings = ref.watch(settingsControllerProvider);
    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Storage load failed: $error')),
      data: (data) {
        final List<FolderUsage> scanResults = data.folderUsage[_selectedPath] ?? const [];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                title: 'Physical Disks',
                accentColor: const Color(0xFFFF9F43),
                child: data.disks.isEmpty
                    ? const _EmptyState(message: 'No block device data available.')
                    : Column(children: data.disks.map((d) => _DiskRow(disk: d)).toList()),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Partitions',
                accentColor: const Color(0xFF4DA3FF),
                child: data.partitions.isEmpty
                    ? const _EmptyState(message: 'No partitions available.')
                    : Column(children: data.partitions.map((p) => _PartitionRow(partition: p)).toList()),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Filesystem Usage',
                accentColor: const Color(0xFF3DD68C),
                child: data.filesystems.isEmpty
                    ? const _EmptyState(message: 'No filesystem data available.')
                    : Column(children: data.filesystems.map((fs) => _FilesystemRow(fs: fs)).toList()),
              ),
              const SizedBox(height: 14),
              SectionCard(
                title: 'Storage Explorer',
                accentColor: const Color(0xFFA78BFA),
                trailing: IconButton(
                  onPressed: () => ref.read(storageSnapshotProvider.notifier).scanFolders(_selectedPath),
                  icon: const Icon(Icons.search, size: 18),
                  tooltip: 'Scan selected path',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _paths
                          .map(
                            (p) => ChoiceChip(
                              label: Text(p, style: const TextStyle(fontSize: 12)),
                              selected: _selectedPath == p,
                              onSelected: (_) => setState(() => _selectedPath = p),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    if (!data.folderUsage.containsKey(_selectedPath) &&
                        settings.storageScanBehavior == 'manual')
                      const _EmptyState(message: 'Press the scan button to analyze this directory.')
                    else if (scanResults.isEmpty)
                      const _EmptyState(message: 'No directory usage results yet.')
                    else
                      _FolderResults(results: scanResults),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DiskRow extends StatelessWidget {
  const _DiskRow({required this.disk});
  final DiskInfo disk;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9F43).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storage, color: Color(0xFFFF9F43), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(disk.model, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  '${disk.device}  •  ${formatBytes(disk.sizeBytes)}  •  ${disk.interfaceType.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (disk.state != null)
            StatusChip(label: disk.state!, color: scheme.primary),
        ],
      ),
    );
  }
}

class _PartitionRow extends StatelessWidget {
  const _PartitionRow({required this.partition});
  final PartitionInfo partition;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = partition.mountPoint.isNotEmpty ? partition.mountPoint : partition.device;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.folder_outlined, size: 16, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                Text(
                  '${partition.device}  •  ${partition.fileSystemType}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            formatBytes(partition.sizeBytes),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FilesystemRow extends StatelessWidget {
  const _FilesystemRow({required this.fs});
  final FilesystemInfo fs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = fs.usagePercent;
    final color = pct > 90
        ? scheme.error
        : pct > 75
            ? Colors.orange.shade400
            : const Color(0xFF3DD68C);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  fs.mountPoint,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Text(
                formatPercent(pct),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          UsageBar(value: pct / 100, foregroundColor: color),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                '${formatBytes(fs.usedBytes)} used',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '  •  ${formatBytes(fs.availableBytes)} free  •  ${formatBytes(fs.totalBytes)} total',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FolderResults extends StatelessWidget {
  const _FolderResults({required this.results});
  final List<FolderUsage> results;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: results.take(10).map((item) {
        final ratio = results.isEmpty ? 0.0 : item.sizeBytes / results.first.sizeBytes;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  item.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: UsageBar(
                  value: ratio.clamp(0.0, 1.0),
                  foregroundColor: scheme.primary.withValues(alpha: 0.7),
                  height: 5,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 72,
                child: Text(
                  formatBytes(item.sizeBytes),
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
