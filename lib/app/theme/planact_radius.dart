import 'package:flutter/material.dart';

abstract final class PlanActRadius {
  static const chip = BorderRadius.all(Radius.circular(8));
  static const input = BorderRadius.all(Radius.circular(12));
  static const card = BorderRadius.all(Radius.circular(16));
  static const sheet = BorderRadius.vertical(top: Radius.circular(24));
}
