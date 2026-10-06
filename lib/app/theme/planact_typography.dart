import 'package:flutter/material.dart';

abstract final class PlanActTypography {
  static TextTheme textTheme(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    ).textTheme.apply(fontFamily: 'sans', bodyColor: scheme.onSurface);
    return base.copyWith(
      bodyLarge: base.bodyLarge?.copyWith(height: 1.6),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.6),
      bodySmall: base.bodySmall?.copyWith(height: 1.5),
      labelSmall: base.labelSmall?.copyWith(height: 1.4),
      displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w700),
      headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
