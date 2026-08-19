import 'package:flutter/material.dart';

class AppTheme {
  static const _darkSurface = Color(0xFF0D1117);
  static const _darkCard = Color(0xFF161B22);
  static const _darkCardHighest = Color(0xFF1C2128);

  static ThemeData get dark {
    const seed = Color(0xFF4DA3FF);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
      surface: _darkSurface,
      surfaceContainerLowest: _darkSurface,
      surfaceContainer: _darkCard,
      surfaceContainerHighest: _darkCardHighest,
    );
    return _build(scheme);
  }

  static ThemeData get light {
    const seed = Color(0xFF0F6FFF);
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      surface: const Color(0xFFF0F4FA),
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainer: const Color(0xFFFFFFFF),
      surfaceContainerHighest: const Color(0xFFE8EDF5),
    );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark
                ? scheme.outlineVariant.withValues(alpha: 0.18)
                : scheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? const Color(0xFF0D1117) : const Color(0xFFFFFFFF),
        selectedIconTheme: IconThemeData(color: scheme.primary, size: 22),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
        ),
        indicatorColor: scheme.primary.withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      textTheme: _textTheme(scheme),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = scheme.brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    return base.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
      fontFamily: 'Inter',
    ).copyWith(
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
        color: scheme.onSurfaceVariant,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
