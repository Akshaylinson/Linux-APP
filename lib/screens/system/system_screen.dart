import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/process_info.dart';
import '../../models/system_snapshot.dart';
import '../../models/temperature_info.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/usage_bar.dart';

class SystemScreen extends ConsumerWidget {
  const SystemScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(systemSnapshotProvider);
    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('System load failed: $error')),
      data: (data) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionCard(
              title: 'System Information',
              accentColor: const Color(0xFF3DD68C),
              child: Wrap(
                spacing: 0,
                runSpacing: 0,
                children: [
                  _InfoBlock(label: 'OS', value: data.system.osPrettyName, icon: Icons.computer_outlined),
                  _InfoBlock(label: 'Kernel', value: data.system.kernelVersion, icon: Icons.memory_outlined),
                  _InfoBlock(label: 'Architecture', value: data.system.architecture, icon: Icons.settings_input_component_outlined),
                  _InfoBlock(label: 'Hostname', value: data.system.hostname, icon: Icons.dns_outlined),
                  _InfoBlock(label: 'Desktop', value: data.system.desktopEnvironment, icon: Icons.desktop_windows_outlined),
                  _InfoBlock(label: 'Uptime', value: data.system.uptime, icon: Icons.timer_outlined),
                ],
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 1100 ? 2 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 2.2 : 2.4,
                  children: [
                    SectionCard(
                      title: 'CPU',
                      accentColor: const Color(0xFF4DA3FF),
                      child: _CpuCard(data: data),
                    ),
                    SectionCard(
                      title: 'Memory',
                      accentColor: const Color(0xFF3DD68C),
                      child: _MemoryCard(data: data),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            SectionCard(
              title: 'Temperature Sensors',
              accentColor: const Color(0xFFFF6B6B),
              child: data.temperatures.isEmpty
                  ? const _EmptyState(message: 'No temperature sensors detected.')
                  : Column(
                      children: data.temperatures
                          .map((temp) => _SensorRow(temp: temp))
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 1100 ? 2 : 1;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 1 ? 2.0 : 2.2,
                  children: [
                    SectionCard(
                      title: 'GPU',
                      accentColor: const Color(0xFFA78BFA),
                      child: _GpuCard(data: data),
                    ),
                    SectionCard(
                      title: 'Battery',
                      accentColor: const Color(0xFFFF9F43),
                      child: _BatteryCard(data: data),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            SectionCard(
              title: 'Top Processes',
              accentColor: const Color(0xFF4DA3FF),
              child: data.processes.isEmpty
                  ? const _EmptyState(message: 'No process data available.')
                  : _ProcessTable(processes: data.processes),
            ),
          ],
        ),
      ),
    );
  }
}

class _CpuCard extends StatelessWidget {
  const _CpuCard({required this.data});
  final SystemSnapshot data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data.cpu.model, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          '${data.cpu.coreCount} cores  •  ${data.cpu.threadCount} threads',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: UsageBar(value: data.cpu.usagePercent / 100)),
            const SizedBox(width: 10),
            Text(
              formatPercent(data.cpu.usagePercent),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        if (data.cpu.loadAverage?.isNotEmpty == true) ...[
          const SizedBox(height: 8),
          Text(
            'Load avg  ${data.cpu.loadAverage!.map((v) => v.toStringAsFixed(2)).join('  ')}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.data});
  final SystemSnapshot data;

  @override
  Widget build(BuildContext context) {
    final mem = data.memory;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              formatBytes(mem.usedBytes),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              ' / ${formatBytes(mem.totalBytes)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: UsageBar(value: mem.usagePercent / 100, foregroundColor: const Color(0xFF3DD68C))),
            const SizedBox(width: 10),
            Text(
              formatPercent(mem.usagePercent),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF3DD68C),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _MemStat(label: 'Available', value: formatBytes(mem.availableBytes)),
            const SizedBox(width: 20),
            _MemStat(label: 'Cached', value: formatBytes(mem.cachedBytes)),
            if (mem.swapTotalBytes > 0) ...[
              const SizedBox(width: 20),
              _MemStat(label: 'Swap', value: '${formatBytes(mem.swapUsedBytes)} / ${formatBytes(mem.swapTotalBytes)}'),
            ],
          ],
        ),
      ],
    );
  }
}

class _MemStat extends StatelessWidget {
  const _MemStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}

class _SensorRow extends StatelessWidget {
  const _SensorRow({required this.temp});
  final TemperatureInfo temp;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final value = temp.temperatureC;
    final Color color = value == null
        ? scheme.onSurfaceVariant
        : value > (temp.criticalC ?? 90)
            ? scheme.error
            : value > (temp.highC ?? 75)
                ? Colors.orange.shade400
                : const Color(0xFF3DD68C);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.thermostat_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(temp.label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            temp.source ?? 'sensor',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value == null ? 'N/A' : formatTemperature(value),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpuCard extends StatelessWidget {
  const _GpuCard({required this.data});
  final SystemSnapshot data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFA78BFA).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                data.gpu.vendor,                style: const TextStyle(
                  color: Color(0xFFA78BFA),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                data.gpu.status,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(data.gpu.model, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _BatteryCard extends StatelessWidget {
  const _BatteryCard({required this.data});
  final SystemSnapshot data;

  @override
  Widget build(BuildContext context) {
    if (!data.battery.present) {
      return const _EmptyState(message: 'No battery detected.');
    }
    final pct = data.battery.percentage ?? 0.0;
    final color = pct < 20
        ? Theme.of(context).colorScheme.error
        : pct < 40
            ? Colors.orange.shade400
            : const Color(0xFF3DD68C);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 10),
            Text(data.battery.status ?? 'Unknown', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 10),
        UsageBar(value: pct / 100, foregroundColor: color),
        if (data.battery.health != null) ...[
          const SizedBox(height: 8),
          Text('Health  ${data.battery.health}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 240,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14, right: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: scheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessTable extends StatelessWidget {
  const _ProcessTable({required this.processes});
  final List<ProcessInfo> processes;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text('Process', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0.8)),
              ),
              Expanded(
                child: Text('CPU', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0.8)),
              ),
              Expanded(
                child: Text('RAM', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant, letterSpacing: 0.8)),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.3)),
        const SizedBox(height: 8),
        ...processes.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: p.cpuPercent > 20
                              ? scheme.error
                              : p.cpuPercent > 10
                                  ? Colors.orange.shade400
                                  : scheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    '${p.cpuPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: p.cpuPercent > 20 ? scheme.error : scheme.onSurface,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    formatBytes(p.memoryBytes),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(message, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
