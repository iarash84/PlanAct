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
}

abstract final class PlanActMotion {
  static const short = Duration(milliseconds: 150);
  static const standard = Duration(milliseconds: 220);
  static const emphasis = Duration(milliseconds: 300);
  static const curve = Curves.easeOutCubic;
}
