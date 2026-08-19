import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/app_settings.dart';
import '../../models/dashboard_snapshot.dart';
import '../../models/filesystem_info.dart';
import '../../models/network_info.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/charts/sparkline_chart.dart';
import '../../widgets/common/metric_card.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/usage_bar.dart';
import '../docker/docker_screen.dart';
import '../network/network_screen.dart';
import '../settings/settings_screen.dart';
import '../storage/storage_screen.dart';
import '../system/system_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsControllerProvider);
    final pages = <Widget>[
      const DashboardOverviewPage(),
      const StorageScreen(),
      const DockerScreen(),
      const SystemScreen(),
      const NetworkScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.of(context).size.width > 1400,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              backgroundColor: scheme.surface,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(Icons.monitor_heart, color: scheme.primary),
                    ),
                    const SizedBox(height: 12),
                    if (settings.startMinimized) const SizedBox.shrink(),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard),
                  label: Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.storage_outlined),
                  selectedIcon: Icon(Icons.storage),
                  label: Text('Storage'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.dns_outlined),
                  selectedIcon: Icon(Icons.dns),
                  label: Text('Docker'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.memory_outlined),
                  selectedIcon: Icon(Icons.memory),
                  label: Text('System'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.wifi_outlined),
                  selectedIcon: Icon(Icons.wifi),
                  label: Text('Network'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    onRefresh: _refreshAll,
                    title: AppConstants.fullAppName,
                    subtitle: _subtitleForIndex(_selectedIndex),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedIndex,
                      children: pages,
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

  String _subtitleForIndex(int index) {
    switch (index) {
      case 1:
        return 'Physical disks, partitions, and filesystem usage';
      case 2:
        return 'Docker containers, images, and disk usage';
      case 3:
        return 'CPU, memory, sensors, GPU, and processes';
      case 4:
        return 'Network activity and interface telemetry';
      case 5:
        return 'Appearance and refresh preferences';
      default:
        return 'Linux system dashboard';
    }
  }

  void _refreshAll() {
    ref.read(dashboardControllerProvider.notifier).refresh();
    ref.read(storageSnapshotProvider.notifier).refresh();
    ref.read(systemSnapshotProvider.notifier).refresh();
    ref.read(networkSnapshotProvider.notifier).refresh();
    ref.read(dockerSnapshotProvider.notifier).refresh();
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onRefresh,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onRefresh;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }
}

class DashboardOverviewPage extends ConsumerWidget {
  const DashboardOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(dashboardControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Failed to load dashboard: $error')),
      data: (data) {
        final storage = _rootFilesystem(data.filesystems);
        final temperature = data.temperatures.isNotEmpty ? data.temperatures.first : null;
        final network = data.network.isNotEmpty ? data.network.first : null;
        final memoryUsage = data.memory.usagePercent;
        final storageUsage = storage?.usagePercent ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 1500
                      ? 4
                      : constraints.maxWidth > 1100
                          ? 2
                          : 1;
                  final cards = [
                    MetricCard(
                      title: 'CPU',
                      value: formatPercent(data.cpu.usagePercent),
                      subtitle: '${data.cpu.coreCount} cores, ${data.cpu.threadCount} threads',
                      icon: Icons.developer_board,
                      accent: Colors.cyanAccent.shade100,
                    ),
                    MetricCard(
                      title: 'RAM',
                      value: '${formatBytes(data.memory.usedBytes)} / ${formatBytes(data.memory.totalBytes)}',
                      subtitle: 'Used ${formatPercent(memoryUsage)}',
                      icon: Icons.memory,
                      accent: Colors.tealAccent.shade100,
                    ),
                    MetricCard(
                      title: 'Storage',
                      value: storage == null
                          ? 'N/A'
                          : '${formatBytes(storage.usedBytes)} / ${formatBytes(storage.totalBytes)}',
                      subtitle: storage == null ? 'No filesystem data' : formatPercent(storageUsage),
                      icon: Icons.storage,
                      accent: Colors.orangeAccent.shade100,
                    ),
                    MetricCard(
                      title: 'Temperature',
                      value: temperature?.temperatureC == null
                          ? 'N/A'
                          : formatTemperature(
                              temperature!.temperatureC,
                              fahrenheit: settings.temperatureUnit == TemperatureUnit.fahrenheit,
                            ),
                      subtitle: temperature?.label ?? 'No sensors detected',
                      icon: Icons.thermostat,
                      accent: Colors.redAccent.shade100,
                    ),
                  ];
                  return GridView.count(
                    crossAxisCount: columns,
                    childAspectRatio: columns == 1 ? 2.4 : 3.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: cards,
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 1250 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: columns == 1 ? 1.3 : 1.7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      SectionCard(
                        title: 'CPU History',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SparklineChart(
                              values: data.cpuHistory,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            const Text('Overall CPU usage over the last refreshes.'),
                          ],
                        ),
                      ),
                      SectionCard(
                        title: 'Memory History',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SparklineChart(
                              values: data.memoryHistory,
                              color: Colors.tealAccent.shade400,
                            ),
                            const SizedBox(height: 12),
                            const Text('RAM pressure and cache movement.'),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 1200 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: columns == 1 ? 1.2 : 1.4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      SectionCard(
                        title: 'Storage Overview',
                        trailing: storage == null
                            ? const SizedBox.shrink()
                            : StatusChip(
                                label: formatPercent(storage.usagePercent),
                                color: storage.usagePercent > 80
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                              ),
                        child: _FilesystemSummary(filesystems: data.filesystems),
                      ),
                      SectionCard(
                        title: 'Docker Overview',
                        trailing: StatusChip(
                          label: data.docker.state,
                          color: data.docker.permissionDenied
                              ? Theme.of(context).colorScheme.error
                              : data.docker.installed
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                        ),
                        child: _DockerSummary(snapshot: data),
                      ),
                      SectionCard(
                        title: 'System Information',
                        child: _SystemSummary(snapshot: data),
                      ),
                      SectionCard(
                        title: 'Network Activity',
                        child: _NetworkSummary(network: network),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  FilesystemInfo? _rootFilesystem(List<FilesystemInfo> filesystems) {
    if (filesystems.isEmpty) return null;
    return filesystems.firstWhere(
      (item) => item.mountPoint == '/',
      orElse: () => filesystems.first,
    );
  }
}

class _FilesystemSummary extends StatelessWidget {
  const _FilesystemSummary({required this.filesystems});

  final List<FilesystemInfo> filesystems;

  @override
  Widget build(BuildContext context) {
    if (filesystems.isEmpty) {
      return const Text('No mounted filesystem data available.');
    }
    return Column(
      children: filesystems
          .take(4)
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.mountPoint,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Text(formatPercent(item.usagePercent)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  UsageBar(value: item.usagePercent / 100),
                  const SizedBox(height: 6),
                  Text(
                    '${formatBytes(item.usedBytes)} used of ${formatBytes(item.totalBytes)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DockerSummary extends StatelessWidget {
  const _DockerSummary({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final docker = snapshot.docker;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Kpi(label: 'Containers', value: docker.containersTotal.toString()),
            const SizedBox(width: 16),
            _Kpi(label: 'Running', value: docker.containersRunning.toString()),
            const SizedBox(width: 16),
            _Kpi(label: 'Images', value: docker.imagesTotal.toString()),
          ],
        ),
        const SizedBox(height: 16),
        Text('Running containers', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 10),
        if (docker.containers.isEmpty)
          const Text('No running container data available.')
        else
          ...docker.containers.take(4).map(
                (container) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(container.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(container.image, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      Text(container.cpuPercent.toStringAsFixed(1)),
                      const SizedBox(width: 14),
                      Text(container.memoryUsage),
                    ],
                  ),
                ),
              ),
      ],
    );
  }
}

class _SystemSummary extends StatelessWidget {
  const _SystemSummary({required this.snapshot});

  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final system = snapshot.system;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(system.osPrettyName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text('Kernel ${system.kernelVersion}'),
        const SizedBox(height: 6),
        Text('${system.hostname}  •  ${system.desktopEnvironment}'),
        const SizedBox(height: 6),
        Text('Uptime ${system.uptime}'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StatusChip(label: snapshot.gpu.vendor, color: Theme.of(context).colorScheme.primary),
            StatusChip(
              label: snapshot.battery.present
                  ? 'Battery ${snapshot.battery.percentage?.toStringAsFixed(0) ?? '--'}%'
                  : 'No battery detected',
              color: snapshot.battery.present
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ],
    );
  }
}

class _NetworkSummary extends StatelessWidget {
  const _NetworkSummary({required this.network});

  final NetworkInfo? network;

  @override
  Widget build(BuildContext context) {
    if (network == null) {
      return const Text('No active network interface detected.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(network!.interfaceName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text('State: ${network!.state}'),
        const SizedBox(height: 6),
        Text('Download ${formatBytes(network!.rxBytesPerSecond)}/s'),
        const SizedBox(height: 6),
        Text('Upload ${formatBytes(network!.txBytesPerSecond)}/s'),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
