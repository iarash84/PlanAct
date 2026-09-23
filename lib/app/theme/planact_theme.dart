import 'package:flutter/material.dart';

import 'planact_colors.dart';
import 'planact_radius.dart';
import 'planact_typography.dart';

abstract final class PlanActTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: PlanActColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: PlanActColors.primary,
          secondary: PlanActColors.info,
          tertiary: PlanActColors.success,
          error: PlanActColors.overdue,
          surface: brightness == Brightness.light
              ? PlanActColors.lightBackground
              : PlanActColors.darkBackground,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: PlanActTypography.textTheme(scheme),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: PlanActRadius.card),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: PlanActRadius.input),
        enabledBorder: OutlineInputBorder(borderRadius: PlanActRadius.input),
        focusedBorder: OutlineInputBorder(borderRadius: PlanActRadius.input),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
        ),
      ),
    );
  }
}
