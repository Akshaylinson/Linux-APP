import 'package:flutter/material.dart';

enum ThemeModeChoice { system, light, dark }
enum TemperatureUnit { celsius, fahrenheit }
enum RefreshInterval { one, two, five, ten, manual }

extension ThemeModeChoiceX on ThemeModeChoice {
  ThemeMode get flutterMode {
    switch (this) {
      case ThemeModeChoice.system:
        return ThemeMode.system;
      case ThemeModeChoice.light:
        return ThemeMode.light;
      case ThemeModeChoice.dark:
        return ThemeMode.dark;
    }
  }
}

extension RefreshIntervalX on RefreshInterval {
  int? get seconds {
    switch (this) {
      case RefreshInterval.one:
        return 1;
      case RefreshInterval.two:
        return 2;
      case RefreshInterval.five:
        return 5;
      case RefreshInterval.ten:
        return 10;
      case RefreshInterval.manual:
        return null;
    }
  }
}

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeModeChoice.dark,
    this.refreshInterval = RefreshInterval.two,
    this.temperatureUnit = TemperatureUnit.celsius,
    this.storageScanBehavior = 'manual',
    this.dockerMonitoringEnabled = true,
    this.startMinimized = false,
  });

  final ThemeModeChoice themeMode;
  final RefreshInterval refreshInterval;
  final TemperatureUnit temperatureUnit;
  final String storageScanBehavior;
  final bool dockerMonitoringEnabled;
  final bool startMinimized;

  AppSettings copyWith({
    ThemeModeChoice? themeMode,
    RefreshInterval? refreshInterval,
    TemperatureUnit? temperatureUnit,
    String? storageScanBehavior,
    bool? dockerMonitoringEnabled,
    bool? startMinimized,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      storageScanBehavior: storageScanBehavior ?? this.storageScanBehavior,
      dockerMonitoringEnabled:
          dockerMonitoringEnabled ?? this.dockerMonitoringEnabled,
      startMinimized: startMinimized ?? this.startMinimized,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.name,
        'refreshInterval': refreshInterval.name,
        'temperatureUnit': temperatureUnit.name,
        'storageScanBehavior': storageScanBehavior,
        'dockerMonitoringEnabled': dockerMonitoringEnabled,
        'startMinimized': startMinimized,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    ThemeModeChoice parseTheme(String? value) => ThemeModeChoice.values.firstWhere(
          (item) => item.name == value,
          orElse: () => ThemeModeChoice.dark,
        );

    RefreshInterval parseRefresh(String? value) =>
        RefreshInterval.values.firstWhere(
          (item) => item.name == value,
          orElse: () => RefreshInterval.two,
        );

    TemperatureUnit parseTemperature(String? value) =>
        TemperatureUnit.values.firstWhere(
          (item) => item.name == value,
          orElse: () => TemperatureUnit.celsius,
        );

    return AppSettings(
      themeMode: parseTheme(json['themeMode'] as String?),
      refreshInterval: parseRefresh(json['refreshInterval'] as String?),
      temperatureUnit: parseTemperature(json['temperatureUnit'] as String?),
      storageScanBehavior:
          json['storageScanBehavior'] as String? ?? 'manual',
      dockerMonitoringEnabled:
          json['dockerMonitoringEnabled'] as bool? ?? true,
      startMinimized: json['startMinimized'] as bool? ?? false,
    );
  }
}
