import 'package:flutter/material.dart';

abstract final class PlanActColors {
  // Contrast-adjusted relatives of the launcher's green, navy and teal.
  // Brand hierarchy only: business meaning lives in PlanActStatusColors.
  static const primary = Color(0xff087443);
  static const primaryDark = Color(0xff004d2b);
  static const navy = Color(0xff16465b);
  static const teal = Color(0xff006b65);

  static ColorScheme scheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ColorScheme.fromSeed(
      seedColor: navy,
      brightness: brightness,
    ).copyWith(
      primary: dark ? const Color(0xff75d9a2) : primary,
      onPrimary: dark ? const Color(0xff00391e) : Colors.white,
      primaryContainer: dark
          ? const Color(0xff173b2c)
          : const Color(0xffd9f3e5),
      onPrimaryContainer: dark
          ? const Color(0xffb4f2ce)
          : const Color(0xff00391e),
      secondary: dark ? const Color(0xffaacddd) : navy,
      onSecondary: dark ? const Color(0xff062b3a) : Colors.white,
      secondaryContainer: dark
          ? const Color(0xff254452)
          : const Color(0xffdceef5),
      onSecondaryContainer: dark
          ? const Color(0xffdceef5)
          : const Color(0xff062b3a),
      tertiary: dark ? const Color(0xff72d4c8) : teal,
      onTertiary: dark ? const Color(0xff003b36) : Colors.white,
      tertiaryContainer: dark
          ? const Color(0xff164943)
          : const Color(0xffcdf4ed),
      onTertiaryContainer: dark
          ? const Color(0xffb2eee3)
          : const Color(0xff003b36),
      surface: dark ? darkBackground : lightBackground,
      surfaceContainer: dark ? darkSurface : lightSurface,
    );
  }

  static const lightBackground = Color(0xfff7fafb);
  static const darkBackground = Color(0xff101a1e);
  static const lightSurface = Color(0xffffffff);
  static const darkSurface = Color(0xff18262b);
}
