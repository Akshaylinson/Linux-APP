import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, AppSettings>((ref) {
  return SettingsController();
});

class SettingsController extends StateNotifier<AppSettings> {
  SettingsController() : super(const AppSettings()) {
    _load();
  }

  String get _directoryPath {
    final home = Platform.environment['HOME'] ?? '.';
    return '$home/.config/systemlens';
  }

  String get _filePath => '$_directoryPath/settings.json';

  Future<void> _load() async {
    try {
      final file = File(_filePath);
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      state = AppSettings.fromJson(json);
    } catch (_) {
      state = const AppSettings();
    }
  }

  Future<void> _save() async {
    try {
      final directory = Directory(_directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final file = File(_filePath);
      await file.writeAsString(jsonEncode(state.toJson()));
    } catch (_) {
      // Ignore persistence failures.
    }
  }

  void setThemeMode(ThemeModeChoice value) {
    state = state.copyWith(themeMode: value);
    _save();
  }

  void setRefreshInterval(RefreshInterval value) {
    state = state.copyWith(refreshInterval: value);
    _save();
  }

  void setTemperatureUnit(TemperatureUnit value) {
    state = state.copyWith(temperatureUnit: value);
    _save();
  }

  void setStorageScanBehavior(String value) {
    state = state.copyWith(storageScanBehavior: value);
    _save();
  }

  void setDockerMonitoringEnabled(bool value) {
    state = state.copyWith(dockerMonitoringEnabled: value);
    _save();
  }

  void setStartMinimized(bool value) {
    state = state.copyWith(startMinimized: value);
    _save();
  }
}
