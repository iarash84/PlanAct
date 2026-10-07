import 'package:flutter/material.dart';

/// Business meaning is independent of Material brand hierarchy.
@immutable
class PlanActStatusColors extends ThemeExtension<PlanActStatusColors> {
  const PlanActStatusColors({
    required this.success,
    required this.successContainer,
    required this.attention,
    required this.attentionContainer,
    required this.danger,
    required this.dangerContainer,
    required this.info,
    required this.infoContainer,
    required this.holiday,
    required this.holidayContainer,
    required this.inactive,
    required this.inactiveContainer,
  });

  final Color success;
  final Color successContainer;
  final Color attention;
  final Color attentionContainer;
  final Color danger;
  final Color dangerContainer;
  final Color info;
  final Color infoContainer;
  final Color holiday;
  final Color holidayContainer;
  final Color inactive;
  final Color inactiveContainer;

  static const light = PlanActStatusColors(
    success: Color(0xff17633f),
    successContainer: Color(0xffd9f3e4),
    attention: Color(0xff744900),
    attentionContainer: Color(0xffffedc2),
    danger: Color(0xffa32129),
    dangerContainer: Color(0xffffe3e3),
    info: Color(0xff205d96),
    infoContainer: Color(0xffdfedff),
    holiday: Color(0xffa32129),
    holidayContainer: Color(0xffffe3e3),
    inactive: Color(0xff495b63),
    inactiveContainer: Color(0xffe6edef),
  );
  static const dark = PlanActStatusColors(
    success: Color(0xff9cddb6),
    successContainer: Color(0xff173b29),
    attention: Color(0xffffd58c),
    attentionContainer: Color(0xff493510),
    danger: Color(0xffffb3b6),
    dangerContainer: Color(0xff502329),
    info: Color(0xffaacfff),
    infoContainer: Color(0xff1b354e),
    holiday: Color(0xffffb3b6),
    holidayContainer: Color(0xff502329),
    inactive: Color(0xffbecbd1),
    inactiveContainer: Color(0xff2b3b42),
  );

  static PlanActStatusColors of(BuildContext context) =>
      Theme.of(context).extension<PlanActStatusColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  PlanActStatusColors copyWith({
    Color? success,
    Color? successContainer,
    Color? attention,
    Color? attentionContainer,
    Color? danger,
    Color? dangerContainer,
    Color? info,
    Color? infoContainer,
    Color? holiday,
    Color? holidayContainer,
    Color? inactive,
    Color? inactiveContainer,
  }) => PlanActStatusColors(
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    attention: attention ?? this.attention,
    attentionContainer: attentionContainer ?? this.attentionContainer,
    danger: danger ?? this.danger,
    dangerContainer: dangerContainer ?? this.dangerContainer,
    info: info ?? this.info,
    infoContainer: infoContainer ?? this.infoContainer,
    holiday: holiday ?? this.holiday,
    holidayContainer: holidayContainer ?? this.holidayContainer,
    inactive: inactive ?? this.inactive,
    inactiveContainer: inactiveContainer ?? this.inactiveContainer,
  );

  @override
  PlanActStatusColors lerp(covariant PlanActStatusColors? other, double t) {
    if (other == null) return this;
    return PlanActStatusColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      attention: Color.lerp(attention, other.attention, t)!,
      attentionContainer: Color.lerp(
        attentionContainer,
        other.attentionContainer,
        t,
      )!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      holiday: Color.lerp(holiday, other.holiday, t)!,
      holidayContainer: Color.lerp(
        holidayContainer,
        other.holidayContainer,
        t,
      )!,
      inactive: Color.lerp(inactive, other.inactive, t)!,
      inactiveContainer: Color.lerp(
        inactiveContainer,
        other.inactiveContainer,
        t,
      )!,
    );
  }
}
