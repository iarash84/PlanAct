import 'package:flutter/material.dart';

/// The same physical RTL month gesture in Calendar and modal date pickers.
/// Only a deliberate horizontal drag navigates; taps and vertical scrolls do not.
class PlanActMonthSwipe extends StatefulWidget {
  const PlanActMonthSwipe({
    super.key,
    required this.onMonthStep,
    required this.child,
  });

  final ValueChanged<int> onMonthStep;
  final Widget child;

  @override
  State<PlanActMonthSwipe> createState() => _PlanActMonthSwipeState();
}

class _PlanActMonthSwipeState extends State<PlanActMonthSwipe> {
  double _distance = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onHorizontalDragStart: (_) => _distance = 0,
    onHorizontalDragUpdate: (details) => _distance += details.delta.dx,
    onHorizontalDragCancel: () => _distance = 0,
    onHorizontalDragEnd: (_) {
      if (_distance.abs() >= 48) widget.onMonthStep(_distance > 0 ? 1 : -1);
      _distance = 0;
    },
    child: widget.child,
  );
}
