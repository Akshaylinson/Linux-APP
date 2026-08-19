import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/docker_info.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/usage_bar.dart';

class DockerScreen extends ConsumerWidget {
  const DockerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dockerSnapshotProvider);
    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Docker load failed: $error')),
      data: (docker) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                title: 'Docker Overview',
                trailing: StatusChip(
                  label: docker.state,
                  color: docker.permissionDenied
                      ? Theme.of(context).colorScheme.error
                      : docker.installed
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                ),
                child: Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  children: [
                    _MiniStat(label: 'Containers', value: docker.containersTotal.toString()),
                    _MiniStat(label: 'Running', value: docker.containersRunning.toString()),
                    _MiniStat(label: 'Images', value: docker.imagesTotal.toString()),
                    _MiniStat(label: 'Volumes', value: docker.volumesTotal.toString()),
                    _MiniStat(label: 'Disk Usage', value: formatBytes(docker.diskUsageBytes)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Running Containers',
                child: docker.containers.isEmpty
                    ? const Text('No running containers detected.')
                    : Column(
                        children: docker.containers
                            .map(
                              (container) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ContainerRow(container: container),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Safe Cleanup',
                child: const _CleanupPreview(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _ContainerRow extends StatelessWidget {
  const _ContainerRow({required this.container});

  final DockerContainerInfo container;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(container.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(container.image),
              const SizedBox(height: 4),
              Text(container.status, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: UsageBar(value: container.cpuPercent / 100),
        ),
        const SizedBox(width: 12),
        Text(container.memoryUsage),
        const SizedBox(width: 12),
        Text(container.ports),
      ],
    );
  }
}

class _CleanupPreview extends StatefulWidget {
  const _CleanupPreview();

  @override
  State<_CleanupPreview> createState() => _CleanupPreviewState();
}

class _CleanupPreviewState extends State<_CleanupPreview> {
  bool _stoppedContainers = true;
  bool _unusedImages = false;
  bool _unusedVolumes = false;
  bool _buildCache = true;

  @override
  Widget build(BuildContext context) {
    final actions = <String>[
      if (_stoppedContainers) 'Remove stopped containers',
      if (_unusedImages) 'Remove unused images',
      if (_unusedVolumes) 'Remove unused volumes',
      if (_buildCache) 'Reclaim build cache',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          value: _stoppedContainers,
          onChanged: (value) => setState(() => _stoppedContainers = value),
          title: const Text('Remove stopped containers'),
        ),
        SwitchListTile(
          value: _unusedImages,
          onChanged: (value) => setState(() => _unusedImages = value),
          title: const Text('Remove unused images'),
        ),
        SwitchListTile(
          value: _unusedVolumes,
          onChanged: (value) => setState(() => _unusedVolumes = value),
          title: const Text('Remove unused volumes'),
        ),
        SwitchListTile(
          value: _buildCache,
          onChanged: (value) => setState(() => _buildCache = value),
          title: const Text('Reclaim build cache'),
        ),
        const SizedBox(height: 12),
        Text('This is a preview-only panel in the current build.'),
        const SizedBox(height: 8),
        if (actions.isNotEmpty)
          Text('Would affect: ${actions.join(', ')}'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cleanup preview prepared. Destructive execution is intentionally disabled.')),
            );
          },
          child: const Text('Review cleanup'),
        ),
      ],
    );
  }
}
