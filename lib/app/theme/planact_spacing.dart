import 'package:flutter/material.dart';

abstract final class PlanActSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const page = 20.0;
  static const touchTarget = 48.0;
  // Keeps single-column task and financial content readable on wide windows.
  static const contentWidth = 840.0;
}

abstract final class PlanActMotion {
  static const short = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 220);
  static const emphasis = Duration(milliseconds: 300);
  static const curve = Curves.easeOutCubic;

  static Duration duration(BuildContext context, [Duration value = standard]) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}
