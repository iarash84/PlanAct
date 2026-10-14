import 'package:flutter/material.dart';

import 'planact_spacing.dart';

/// Slides pushed pages in from the logical end and pops them back out there.
class PlanActPageTransitionsBuilder extends PageTransitionsBuilder {
  const PlanActPageTransitionsBuilder();

  @override
  Duration get transitionDuration => PlanActMotion.standard;

  @override
  Duration get reverseTransitionDuration => PlanActMotion.standard;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return ClipRect(
      child: SlideTransition(
        textDirection: Directionality.of(context),
        position: animation.drive(
          Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: PlanActMotion.curve)),
        ),
        child: child,
      ),
    );
  }
}
