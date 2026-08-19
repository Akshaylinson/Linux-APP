import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/process_info.dart';
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
      data: (data) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                title: 'System Information',
                child: Wrap(
                  spacing: 24,
                  runSpacing: 18,
                  children: [
                    _InfoBlock(label: 'OS', value: data.system.osPrettyName),
                    _InfoBlock(label: 'Kernel', value: data.system.kernelVersion),
                    _InfoBlock(label: 'Architecture', value: data.system.architecture),
                    _InfoBlock(label: 'Hostname', value: data.system.hostname),
                    _InfoBlock(label: 'Desktop', value: data.system.desktopEnvironment),
                    _InfoBlock(label: 'Uptime', value: data.system.uptime),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 1200 ? 2 : 1;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: columns == 1 ? 1.2 : 1.4,
                    children: [
                      SectionCard(
                        title: 'CPU',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.cpu.model, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text('${data.cpu.coreCount} cores, ${data.cpu.threadCount} threads'),
                            const SizedBox(height: 8),
                            UsageBar(value: data.cpu.usagePercent / 100),
                            const SizedBox(height: 8),
                            Text(formatPercent(data.cpu.usagePercent)),
                          ],
                        ),
                      ),
                      SectionCard(
                        title: 'Memory',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${formatBytes(data.memory.usedBytes)} / ${formatBytes(data.memory.totalBytes)}'),
                            const SizedBox(height: 8),
                            Text('Available ${formatBytes(data.memory.availableBytes)}'),
                            const SizedBox(height: 8),
                            UsageBar(value: data.memory.usagePercent / 100),
                            const SizedBox(height: 8),
                            Text(formatPercent(data.memory.usagePercent)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Sensors',
                child: data.temperatures.isEmpty
                    ? const Text('No temperature sensors detected.')
                    : Column(
                        children: data.temperatures
                            .map(
                              (temp) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(temp.label),
                                subtitle: Text(temp.source ?? 'sensor'),
                                trailing: Text(
                                  temp.temperatureC == null ? 'N/A' : formatTemperature(temp.temperatureC),
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 1200 ? 2 : 1;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: columns == 1 ? 1.1 : 1.3,
                    children: [
                      SectionCard(
                        title: 'GPU',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.gpu.vendor, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(data.gpu.model),
                            const SizedBox(height: 8),
                            Text(data.gpu.status),
                          ],
                        ),
                      ),
                      SectionCard(
                        title: 'Battery',
                        child: data.battery.present
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Charge ${data.battery.percentage?.toStringAsFixed(0) ?? '--'}%'),
                                  const SizedBox(height: 8),
                                  Text('Status ${data.battery.status ?? 'Unknown'}'),
                                  const SizedBox(height: 8),
                                  Text('Health ${data.battery.health ?? 'Unknown'}'),
                                ],
                              )
                            : const Text('No battery detected.'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Top Processes',
                child: data.processes.isEmpty
                    ? const Text('No process data available.')
                    : _ProcessTable(processes: data.processes),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

class _ProcessTable extends StatelessWidget {
  const _ProcessTable({required this.processes});

  final List<ProcessInfo> processes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(flex: 3, child: Text('Process')),
            Expanded(child: Text('CPU')),
            Expanded(child: Text('RAM')),
          ],
        ),
        const SizedBox(height: 8),
        ...processes.map(
          (process) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(process.name)),
                Expanded(child: Text('${process.cpuPercent.toStringAsFixed(1)}%')),
                Expanded(child: Text(formatBytes(process.memoryBytes))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
