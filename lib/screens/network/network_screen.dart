import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/network_info.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/charts/sparkline_chart.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/status_chip.dart';
import '../../widgets/common/usage_bar.dart';

class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(networkSnapshotProvider);
    final dashSnapshot = ref.watch(dashboardControllerProvider);

    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Network load failed: $error')),
      data: (interfaces) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (interfaces.isEmpty)
              const SectionCard(
                title: 'Network Interfaces',
                accentColor: Color(0xFFA78BFA),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No active interfaces detected.'),
                ),
              )
            else ...[
              // Traffic chart from dashboard history
              dashSnapshot.whenOrNull(
                data: (dash) => SectionCard(
                  title: 'Network Traffic',
                  accentColor: const Color(0xFFA78BFA),
                  child: SparklineChart(
                    values: dash.networkHistory,
                    color: const Color(0xFFA78BFA),
                    height: 80,
                  ),
                ),
              ) ?? const SizedBox.shrink(),              const SizedBox(height: 14),
              ...interfaces.map(
                (iface) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _InterfaceCard(interface: iface),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InterfaceCard extends StatelessWidget {
  const _InterfaceCard({required this.interface});
  final NetworkInfo interface;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isUp = interface.state == 'up';
    final stateColor = isUp ? const Color(0xFF3DD68C) : scheme.error;

    return SectionCard(
      accentColor: stateColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isUp ? Icons.wifi : Icons.wifi_off,
                  color: stateColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interface.interfaceName,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    if (interface.ipAddress != null)
                      Text(interface.ipAddress!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              StatusChip(label: interface.state, color: stateColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TrafficStat(
                  icon: Icons.arrow_downward,
                  color: const Color(0xFF4DA3FF),
                  label: 'Download',
                  rate: '${formatBytes(interface.rxBytesPerSecond)}/s',
                  total: formatBytes(interface.rxTotalBytes),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _TrafficStat(
                  icon: Icons.arrow_upward,
                  color: const Color(0xFFA78BFA),
                  label: 'Upload',
                  rate: '${formatBytes(interface.txBytesPerSecond)}/s',
                  total: formatBytes(interface.txTotalBytes),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          UsageBar(
            value: ((interface.rxBytesPerSecond + interface.txBytesPerSecond) / (100 * 1024 * 1024))
                .clamp(0.0, 1.0),
            foregroundColor: const Color(0xFFA78BFA),
            height: 5,
          ),
        ],
      ),
    );
  }
}

class _TrafficStat extends StatelessWidget {
  const _TrafficStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.rate,
    required this.total,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String rate;
  final String total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            Text(
              rate,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Text(
              'Total $total',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}
