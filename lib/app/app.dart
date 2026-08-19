import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import 'theme/app_theme.dart';
import '../screens/dashboard/dashboard_screen.dart';

class SystemLensApp extends ConsumerWidget {
  const SystemLensApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SystemLens',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode.flutterMode,
      home: const DashboardScreen(),
    );
  }
}
