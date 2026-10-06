import 'package:flutter/material.dart';

import 'planact_colors.dart';
import 'planact_radius.dart';
import 'planact_spacing.dart';
import 'planact_typography.dart';
import 'planact_status_colors.dart';

abstract final class PlanActTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: PlanActColors.primary,
          brightness: brightness,
        ).copyWith(
          primary: brightness == Brightness.light
              ? PlanActColors.primary
              : const Color(0xff8bd0e7),
          onPrimary: brightness == Brightness.light
              ? Colors.white
              : const Color(0xff003544),
          surface: brightness == Brightness.light
              ? PlanActColors.lightBackground
              : PlanActColors.darkBackground,
          surfaceContainer: brightness == Brightness.light
              ? PlanActColors.lightSurface
              : PlanActColors.darkSurface,
        );
    final outline = scheme.outlineVariant;
    return ThemeData(
      useMaterial3: true,
      extensions: [
        brightness == Brightness.light
            ? PlanActStatusColors.light
            : PlanActStatusColors.dark,
      ],
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: PlanActTypography.textTheme(scheme),
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        backgroundColor: scheme.surface,
        titleTextStyle: PlanActTypography.textTheme(scheme).titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: PlanActRadius.card),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: PlanActSpacing.sm,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PlanActSpacing.lg,
        ),
        shape: const RoundedRectangleBorder(borderRadius: PlanActRadius.card),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: OutlineInputBorder(
          borderRadius: PlanActRadius.input,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: PlanActRadius.input,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: PlanActRadius.input,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: PlanActSpacing.lg,
          vertical: PlanActSpacing.md,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: PlanActRadius.chip),
        side: BorderSide(color: outline),
        padding: const EdgeInsets.symmetric(horizontal: PlanActSpacing.sm),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, PlanActSpacing.touchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: PlanActRadius.input,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, PlanActSpacing.touchTarget),
          shape: const RoundedRectangleBorder(
            borderRadius: PlanActRadius.input,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, PlanActSpacing.touchTarget),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(PlanActSpacing.touchTarget),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: PlanActRadius.card),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),
      dividerTheme: DividerThemeData(color: outline, space: PlanActSpacing.lg),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainer,
        shape: const RoundedRectangleBorder(borderRadius: PlanActRadius.card),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(0, PlanActSpacing.touchTarget),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        constraints: const BoxConstraints(maxWidth: 640),
        backgroundColor: scheme.surfaceContainer,
        showDragHandle: true,
        shape: RoundedRectangleBorder(borderRadius: PlanActRadius.sheet),
        clipBehavior: Clip.antiAlias,
      ),
      dialogTheme: DialogThemeData(
        shape: const RoundedRectangleBorder(borderRadius: PlanActRadius.card),
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: PlanActRadius.input),
        contentTextStyle: PlanActTypography.textTheme(scheme).bodyMedium
            ?.copyWith(color: scheme.onInverseSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(
          PlanActTypography.textTheme(scheme).labelMedium,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
