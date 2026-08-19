import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../models/network_info.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/common/section_card.dart';
import '../../widgets/common/usage_bar.dart';

class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(networkSnapshotProvider);
    return snapshot.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Network load failed: $error')),
      data: (interfaces) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionCard(
                title: 'Network Interfaces',
                child: interfaces.isEmpty
                    ? const Text('No active interfaces detected.')
                    : Column(
                        children: interfaces
                            .map(
                              (iface) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _InterfaceRow(interface: iface),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InterfaceRow extends StatelessWidget {
  const _InterfaceRow({required this.interface});

  final NetworkInfo interface;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(interface.interfaceName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(interface.state),
                ],
              ),
            ),
            Text('↓ ${formatBytes(interface.rxBytesPerSecond)}/s'),
            const SizedBox(width: 14),
            Text('↑ ${formatBytes(interface.txBytesPerSecond)}/s'),
          ],
        ),
        const SizedBox(height: 8),
        UsageBar(value: (interface.rxBytesPerSecond + interface.txBytesPerSecond) / 1024),
        const SizedBox(height: 8),
        Text('Total RX ${formatBytes(interface.rxTotalBytes)}  •  Total TX ${formatBytes(interface.txTotalBytes)}'),
      ],
    );
  }
}
