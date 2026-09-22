import 'package:flutter/material.dart';

abstract final class PlanActTypography {
  static TextTheme textTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
    ).textTheme.apply(fontFamily: 'sans');
  }
}
