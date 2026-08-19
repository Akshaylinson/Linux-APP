import 'package:flutter/material.dart';

class UsageBar extends StatelessWidget {
  const UsageBar({
    super.key,
    required this.value,
    this.height = 6,
    this.backgroundColor,
    this.foregroundColor,
  });

  final double value;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = value.clamp(0.0, 1.0);
    final Color barColor = foregroundColor ??
        (clamped > 0.9
            ? scheme.error
            : clamped > 0.75
                ? Colors.orange.shade400
                : scheme.primary);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: clamped),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, animatedValue, _) => LinearProgressIndicator(
            value: animatedValue,
            backgroundColor:
                backgroundColor ?? scheme.surfaceContainerHighest,
            color: barColor,
          ),
        ),
      ),
    );
  }
}
