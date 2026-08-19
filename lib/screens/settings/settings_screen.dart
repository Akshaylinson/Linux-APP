import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common/section_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Appearance',
            child: DropdownButtonFormField<ThemeModeChoice>(
              initialValue: settings.themeMode,
              decoration: const InputDecoration(labelText: 'Theme'),
              items: const [
                DropdownMenuItem(value: ThemeModeChoice.system, child: Text('System')),
                DropdownMenuItem(value: ThemeModeChoice.light, child: Text('Light')),
                DropdownMenuItem(value: ThemeModeChoice.dark, child: Text('Dark')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsControllerProvider.notifier).setThemeMode(value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Refresh',
            child: DropdownButtonFormField<RefreshInterval>(
              initialValue: settings.refreshInterval,
              decoration: const InputDecoration(labelText: 'Refresh Interval'),
              items: const [
                DropdownMenuItem(value: RefreshInterval.one, child: Text('1 sec')),
                DropdownMenuItem(value: RefreshInterval.two, child: Text('2 sec')),
                DropdownMenuItem(value: RefreshInterval.five, child: Text('5 sec')),
                DropdownMenuItem(value: RefreshInterval.ten, child: Text('10 sec')),
                DropdownMenuItem(value: RefreshInterval.manual, child: Text('Manual')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsControllerProvider.notifier).setRefreshInterval(value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Temperature',
            child: DropdownButtonFormField<TemperatureUnit>(
              initialValue: settings.temperatureUnit,
              decoration: const InputDecoration(labelText: 'Temperature Unit'),
              items: const [
                DropdownMenuItem(value: TemperatureUnit.celsius, child: Text('Celsius')),
                DropdownMenuItem(value: TemperatureUnit.fahrenheit, child: Text('Fahrenheit')),
              ],
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsControllerProvider.notifier).setTemperatureUnit(value);
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Monitoring',
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.dockerMonitoringEnabled,
                  onChanged: (value) {
                    ref.read(settingsControllerProvider.notifier).setDockerMonitoringEnabled(value);
                  },
                  title: const Text('Docker monitoring'),
                ),
                SwitchListTile(
                  value: settings.startMinimized,
                  onChanged: (value) {
                    ref.read(settingsControllerProvider.notifier).setStartMinimized(value);
                  },
                  title: const Text('Start minimized'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Storage Scan Behavior',
            child: TextFormField(
              initialValue: settings.storageScanBehavior,
              decoration: const InputDecoration(
                labelText: 'Storage Scan Behavior',
                helperText: 'Current build keeps this simple: manual or cached.',
              ),
              onChanged: (value) {
                ref.read(settingsControllerProvider.notifier).setStorageScanBehavior(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}
