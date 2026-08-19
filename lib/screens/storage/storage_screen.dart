import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/disk_info.dart';
import '../../models/filesystem_info.dart';
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

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(storageSnapshotProvider);
    final settings = ref.watch(settingsControllerProvider);
    return snapshot.when(
      loading: () => const Center(child: Text('Scanning...')),
      error: (error, stack) => Center(child: Text('Storage load failed: $error')),
      data: (data) {
        final scanResults = data.folderUsage[_selectedPath] ?? const [];
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                title: 'Physical Disks',
                child: _DiskList(disks: data.disks),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Partitions',
                child: _PartitionList(partitions: data.partitions),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Filesystem Usage',
                child: _FilesystemList(filesystems: data.filesystems),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Storage Explorer',
                trailing: IconButton(
                  onPressed: () => ref.read(storageSnapshotProvider.notifier).scanFolders(_selectedPath),
                  icon: const Icon(Icons.search),
                  tooltip: 'Scan selected path',
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PathChip(label: '/', selected: _selectedPath == '/', onTap: () => setState(() => _selectedPath = '/')),
                        _PathChip(label: '/home', selected: _selectedPath == '/home', onTap: () => setState(() => _selectedPath = '/home')),
                        _PathChip(label: '~/Downloads', selected: _selectedPath == '~/Downloads', onTap: () => setState(() => _selectedPath = '~/Downloads')),
                        _PathChip(label: '~/Documents', selected: _selectedPath == '~/Documents', onTap: () => setState(() => _selectedPath = '~/Documents')),
                        _PathChip(label: '~/Projects', selected: _selectedPath == '~/Projects', onTap: () => setState(() => _selectedPath = '~/Projects')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (data.folderUsage.containsKey(_selectedPath) == false &&
                        settings.storageScanBehavior == 'manual')
                      const Text('Press scan to analyze this directory.')
                    else if (scanResults.isEmpty)
                      const Text('No directory usage results yet.')
                    else
                      Column(
                        children: scanResults
                            .take(10)
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(item.displayName)),
                                    Text(formatBytes(item.sizeBytes)),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
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

class _PathChip extends StatelessWidget {
  const _PathChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _DiskList extends StatelessWidget {
  const _DiskList({required this.disks});

  final List<DiskInfo> disks;

  @override
  Widget build(BuildContext context) {
    if (disks.isEmpty) return const Text('No block device data available.');
    return Column(
      children: disks
          .map(
            (disk) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(disk.model),
              subtitle: Text('${disk.device} • ${formatBytes(disk.sizeBytes)} • ${disk.interfaceType}'),
              trailing: disk.state == null
                  ? null
                  : StatusChip(label: disk.state!, color: Theme.of(context).colorScheme.primary),
            ),
          )
          .toList(),
    );
  }
}

class _PartitionList extends StatelessWidget {
  const _PartitionList({required this.partitions});

  final List<PartitionInfo> partitions;

  @override
  Widget build(BuildContext context) {
    if (partitions.isEmpty) return const Text('No partitions available.');
    return Column(
      children: partitions
          .map(
            (partition) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(partition.mountPoint.isEmpty ? partition.device : partition.mountPoint),
              subtitle: Text('${partition.device} • ${formatBytes(partition.sizeBytes)} • ${partition.fileSystemType}'),
            ),
          )
          .toList(),
    );
  }
}

class _FilesystemList extends StatelessWidget {
  const _FilesystemList({required this.filesystems});

  final List<FilesystemInfo> filesystems;

  @override
  Widget build(BuildContext context) {
    if (filesystems.isEmpty) return const Text('No filesystem data available.');
    return Column(
      children: filesystems
          .map(
            (fs) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(fs.mountPoint)),
                      Text(formatPercent(fs.usagePercent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  UsageBar(value: fs.usagePercent / 100),
                  const SizedBox(height: 4),
                  Text('${formatBytes(fs.usedBytes)} used of ${formatBytes(fs.totalBytes)}'),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
