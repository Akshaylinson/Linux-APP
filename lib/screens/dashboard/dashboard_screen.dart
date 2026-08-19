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

  static const _navItems = [
    (icon: Icons.space_dashboard_outlined, selectedIcon: Icons.space_dashboard, label: 'Dashboard'),
    (icon: Icons.storage_outlined, selectedIcon: Icons.storage, label: 'Storage'),
    (icon: Icons.dns_outlined, selectedIcon: Icons.dns, label: 'Docker'),
    (icon: Icons.memory_outlined, selectedIcon: Icons.memory, label: 'System'),
    (icon: Icons.wifi_outlined, selectedIcon: Icons.wifi, label: 'Network'),
    (icon: Icons.tune_outlined, selectedIcon: Icons.tune, label: 'Settings'),
  ];

  static const _subtitles = [
    'Overview of your Linux system',
    'Physical disks, partitions, and filesystem usage',
    'Docker containers, images, and disk usage',
    'CPU, memory, sensors, GPU, and processes',
    'Network activity and interface telemetry',
    'Appearance and refresh preferences',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 1400;

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
            _SideNav(
              selectedIndex: _selectedIndex,
              extended: isWide,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              navItems: _navItems,
            ),
            VerticalDivider(
              width: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.25),
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    onRefresh: _refreshAll,
                    title: AppConstants.fullAppName,
                    subtitle: _subtitles[_selectedIndex],
                  ),
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

  void _refreshAll() {
    ref.read(dashboardControllerProvider.notifier).refresh();
    ref.read(storageSnapshotProvider.notifier).refresh();
    ref.read(systemSnapshotProvider.notifier).refresh();
    ref.read(networkSnapshotProvider.notifier).refresh();
    ref.read(dockerSnapshotProvider.notifier).refresh();
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.selectedIndex,
    required this.extended,
    required this.onDestinationSelected,
    required this.navItems,
  });

  final int selectedIndex;
  final bool extended;
  final ValueChanged<int> onDestinationSelected;
  final List<({IconData icon, IconData selectedIcon, String label})> navItems;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NavigationRail(
      extended: extended,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.monitor_heart, color: Colors.white, size: 20),
            ),
            if (extended) ...[
              const SizedBox(height: 8),
              Text(
                'SystemLens',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ],
        ),
      ),
      destinations: navItems
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: Text(item.label),
            ),
          )
          .toList(),
    );
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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 20, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _LiveIndicator(),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Refresh all',
            style: IconButton.styleFrom(
              minimumSize: const Size(36, 36),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatefulWidget {
  @override
  State<_LiveIndicator> createState() => _LiveIndicatorState();
}

class _LiveIndicatorState extends State<_LiveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.lerp(
                Colors.green.shade400,
                Colors.green.shade600,
                _controller.value,
              ),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          'Live',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
      ],
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
      error: (error, stack) => _ErrorState(message: error.toString()),
      data: (data) {
        final storage = _rootFilesystem(data.filesystems);
        final temperature = data.temperatures.isNotEmpty ? data.temperatures.first : null;
        final network = data.network.isNotEmpty ? data.network.first : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top metric cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 1400
                      ? 4
                      : constraints.maxWidth > 900
                          ? 2
                          : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    childAspectRatio: columns >= 4 ? 2.2 : columns == 2 ? 2.6 : 3.0,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      MetricCard(
                        title: 'CPU',
                        value: formatPercent(data.cpu.usagePercent),
                        subtitle: '${data.cpu.coreCount}c / ${data.cpu.threadCount}t  •  ${data.cpu.model.split(' ').take(3).join(' ')}',
                        icon: Icons.developer_board,
                        accent: const Color(0xFF4DA3FF),
                        progress: data.cpu.usagePercent / 100,
                      ),
                      MetricCard(
                        title: 'Memory',
                        value: formatBytes(data.memory.usedBytes),
                        subtitle: 'of ${formatBytes(data.memory.totalBytes)}  •  ${formatPercent(data.memory.usagePercent)} used',
                        icon: Icons.memory,
                        accent: const Color(0xFF3DD68C),
                        progress: data.memory.usagePercent / 100,
                      ),
                      MetricCard(
                        title: 'Storage',
                        value: storage == null ? 'N/A' : formatBytes(storage.usedBytes),
                        subtitle: storage == null
                            ? 'No filesystem data'
                            : 'of ${formatBytes(storage.totalBytes)}  •  ${formatPercent(storage.usagePercent)} used',
                        icon: Icons.storage,
                        accent: const Color(0xFFFF9F43),
                        progress: storage == null ? null : storage.usagePercent / 100,
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
                        accent: const Color(0xFFFF6B6B),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Charts row
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 1000 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 2 ? 2.6 : 2.0,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      SectionCard(
                        title: 'CPU History',
                        accentColor: const Color(0xFF4DA3FF),
                        child: SparklineChart(
                          values: data.cpuHistory,
                          color: const Color(0xFF4DA3FF),
                          height: 72,
                        ),
                      ),
                      SectionCard(
                        title: 'Memory History',
                        accentColor: const Color(0xFF3DD68C),
                        child: SparklineChart(
                          values: data.memoryHistory,
                          color: const Color(0xFF3DD68C),
                          height: 72,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Detail cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth > 1100 ? 2 : 1;
                  return GridView.count(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: columns == 2 ? 1.55 : 1.2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      SectionCard(
                        title: 'Storage',
                        accentColor: const Color(0xFFFF9F43),
                        trailing: storage == null
                            ? null
                            : StatusChip(
                                label: formatPercent(storage.usagePercent),
                                color: storage.usagePercent > 80
                                    ? Theme.of(context).colorScheme.error
                                    : const Color(0xFFFF9F43),
                              ),
                        child: _FilesystemSummary(filesystems: data.filesystems),
                      ),
                      SectionCard(
                        title: 'Docker',
                        accentColor: const Color(0xFF4DA3FF),
                        trailing: StatusChip(
                          label: data.docker.state,
                          color: data.docker.permissionDenied
                              ? Theme.of(context).colorScheme.error
                              : data.docker.installed
                                  ? const Color(0xFF4DA3FF)
                                  : Theme.of(context).colorScheme.outline,
                        ),
                        child: _DockerSummary(snapshot: data),
                      ),
                      SectionCard(
                        title: 'System',
                        accentColor: const Color(0xFF3DD68C),
                        child: _SystemSummary(snapshot: data),
                      ),
                      SectionCard(
                        title: 'Network',
                        accentColor: const Color(0xFFA78BFA),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: scheme.error),
          const SizedBox(height: 12),
          Text('Failed to load dashboard', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _FilesystemSummary extends StatelessWidget {
  const _FilesystemSummary({required this.filesystems});
  final List<FilesystemInfo> filesystems;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (filesystems.isEmpty) {
      return const Text('No mounted filesystem data available.');
    }
    return Column(
      children: filesystems.take(4).map((item) {
        final pct = item.usagePercent;
        final barColor = pct > 90
            ? scheme.error
            : pct > 75
                ? Colors.orange.shade400
                : const Color(0xFFFF9F43);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.mountPoint,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Text(
                    formatPercent(pct),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: barColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              UsageBar(value: pct / 100, foregroundColor: barColor),
              const SizedBox(height: 5),
              Text(
                '${formatBytes(item.usedBytes)} used  •  ${formatBytes(item.availableBytes)} free',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DockerSummary extends StatelessWidget {
  const _DockerSummary({required this.snapshot});
  final DashboardSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final docker = snapshot.docker;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _KpiTile(label: 'Containers', value: docker.containersTotal.toString()),
            _KpiTile(label: 'Running', value: docker.containersRunning.toString(), valueColor: Colors.green.shade400),
            _KpiTile(label: 'Images', value: docker.imagesTotal.toString()),
            _KpiTile(label: 'Disk', value: formatBytes(docker.diskUsageBytes)),
          ],
        ),
        const SizedBox(height: 14),
        if (docker.containers.isNotEmpty) ...[
          Text(
            'Running containers',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...docker.containers.take(3).map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF3DD68C),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          c.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        c.image,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
        ] else
          Text(
            docker.installed ? 'No running containers.' : 'Docker not available.',
            style: Theme.of(context).textTheme.bodySmall,
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
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          system.osPrettyName,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 10),
        _SysRow(icon: Icons.memory_outlined, label: 'Kernel', value: system.kernelVersion),
        _SysRow(icon: Icons.computer_outlined, label: 'Host', value: system.hostname),
        _SysRow(icon: Icons.desktop_windows_outlined, label: 'Desktop', value: system.desktopEnvironment),
        _SysRow(icon: Icons.timer_outlined, label: 'Uptime', value: system.uptime),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            StatusChip(
              label: snapshot.gpu.vendor,
              color: scheme.primary,
              icon: Icons.videocam_outlined,
            ),
            if (snapshot.battery.present)
              StatusChip(
                label: '${snapshot.battery.percentage?.toStringAsFixed(0) ?? '--'}%',
                color: const Color(0xFF3DD68C),
                icon: Icons.battery_charging_full_outlined,
              ),
          ],
        ),
      ],
    );
  }
}

class _SysRow extends StatelessWidget {
  const _SysRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            '$label  ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _NetworkSummary extends StatelessWidget {
  const _NetworkSummary({required this.network});
  final NetworkInfo? network;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (network == null) {
      return const Text('No active network interface detected.');
    }
    final n = network!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              n.state == 'up' ? Icons.wifi : Icons.wifi_off,
              size: 16,
              color: n.state == 'up' ? const Color(0xFF3DD68C) : scheme.error,
            ),
            const SizedBox(width: 6),
            Text(
              n.interfaceName,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(width: 8),
            StatusChip(
              label: n.state,
              color: n.state == 'up' ? const Color(0xFF3DD68C) : scheme.error,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _NetStat(
              icon: Icons.arrow_downward,
              color: const Color(0xFF4DA3FF),
              label: 'Download',
              value: '${formatBytes(n.rxBytesPerSecond)}/s',
            ),
            const SizedBox(width: 24),
            _NetStat(
              icon: Icons.arrow_upward,
              color: const Color(0xFFA78BFA),
              label: 'Upload',
              value: '${formatBytes(n.txBytesPerSecond)}/s',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Total  RX ${formatBytes(n.rxTotalBytes)}  •  TX ${formatBytes(n.txTotalBytes)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _NetStat extends StatelessWidget {
  const _NetStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
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
