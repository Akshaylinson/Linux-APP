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
      data: (docker) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              title: 'Docker',
              accentColor: const Color(0xFF4DA3FF),
              trailing: StatusChip(
                label: docker.state,
                color: docker.permissionDenied
                    ? Theme.of(context).colorScheme.error
                    : docker.installed
                        ? const Color(0xFF3DD68C)
                        : Theme.of(context).colorScheme.outline,
                icon: docker.installed ? Icons.check_circle_outline : Icons.cancel_outlined,
              ),
              child: _DockerKpiRow(docker: docker),
            ),
            const SizedBox(height: 14),
            SectionCard(
              title: 'Running Containers',
              accentColor: const Color(0xFF3DD68C),
              child: docker.containers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        docker.installed
                            ? 'No running containers detected.'
                            : 'Docker is not available on this system.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : Column(
                      children: docker.containers
                          .map((c) => _ContainerCard(container: c))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),
            const SectionCard(
              title: 'Safe Cleanup',
              accentColor: Color(0xFFFF6B6B),
              child: _CleanupPreview(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockerKpiRow extends StatelessWidget {
  const _DockerKpiRow({required this.docker});
  final DockerInfo docker;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Kpi(label: 'Containers', value: docker.containersTotal.toString(), icon: Icons.dns_outlined),
        _Kpi(
          label: 'Running',
          value: docker.containersRunning.toString(),
          icon: Icons.play_circle_outline,
          valueColor: docker.containersRunning > 0 ? const Color(0xFF3DD68C) : null,
        ),
        _Kpi(label: 'Images', value: docker.imagesTotal.toString(), icon: Icons.layers_outlined),
        _Kpi(label: 'Volumes', value: docker.volumesTotal.toString(), icon: Icons.storage_outlined),
        _Kpi(
          label: 'Disk',
          value: formatBytes(docker.diskUsageBytes),
          icon: Icons.pie_chart_outline,
          valueColor: const Color(0xFFFF9F43),
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? scheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _ContainerCard extends StatelessWidget {
  const _ContainerCard({required this.container});
  final DockerContainerInfo container;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF3DD68C),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    container.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                StatusChip(
                  label: container.status.split(' ').first,
                  color: const Color(0xFF3DD68C),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              container.image,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _ContainerStat(
                  label: 'CPU',
                  value: '${container.cpuPercent.toStringAsFixed(1)}%',
                  color: container.cpuPercent > 50 ? scheme.error : scheme.primary,
                ),
                const SizedBox(width: 20),
                _ContainerStat(
                  label: 'Memory',
                  value: container.memoryUsage,
                  color: scheme.primary,
                ),
                if (container.ports.isNotEmpty) ...[
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      container.ports,
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (container.cpuPercent > 0) ...[
              const SizedBox(height: 8),
              UsageBar(
                value: (container.cpuPercent / 100).clamp(0.0, 1.0),
                height: 4,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContainerStat extends StatelessWidget {
  const _ContainerStat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
        ),
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
    final scheme = Theme.of(context).colorScheme;
    final actions = <String>[
      if (_stoppedContainers) 'Remove stopped containers',
      if (_unusedImages) 'Remove unused images',
      if (_unusedVolumes) 'Remove unused volumes',
      if (_buildCache) 'Reclaim build cache',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select operations to preview. No changes will be made without confirmation.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        _CleanupToggle(
          label: 'Remove stopped containers',
          value: _stoppedContainers,
          onChanged: (v) => setState(() => _stoppedContainers = v),
        ),
        _CleanupToggle(
          label: 'Remove unused images',
          value: _unusedImages,
          onChanged: (v) => setState(() => _unusedImages = v),
        ),
        _CleanupToggle(
          label: 'Remove unused volumes',
          value: _unusedVolumes,
          onChanged: (v) => setState(() => _unusedVolumes = v),
        ),
        _CleanupToggle(
          label: 'Reclaim build cache',
          value: _buildCache,
          onChanged: (v) => setState(() => _buildCache = v),
        ),
        const SizedBox(height: 14),
        if (actions.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.error.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_outlined, size: 16, color: scheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Would affect: ${actions.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton.tonal(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cleanup preview prepared. Destructive execution is intentionally disabled in this build.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Text('Review cleanup'),
        ),
      ],
    );
  }
}

class _CleanupToggle extends StatelessWidget {
  const _CleanupToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label, style: const TextStyle(fontSize: 13)),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}
