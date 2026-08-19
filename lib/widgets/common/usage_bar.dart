import 'package:flutter/material.dart';

class UsageBar extends StatelessWidget {
  const UsageBar({
    super.key,
    required this.value,
    this.height = 10,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value.clamp(0, 1),
          backgroundColor: backgroundColor ?? scheme.surfaceContainerHighest,
          color: foregroundColor ?? scheme.primary,
        ),
      ),
    );
  }
}
