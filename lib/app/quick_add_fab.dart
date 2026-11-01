import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';

/// The persistent global add action with a brief press-scale response.
class QuickAddFab extends StatefulWidget {
  const QuickAddFab({
    super.key,
    required this.size,
    required this.tooltip,
    required this.onPressed,
  });

  final double size;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<QuickAddFab> createState() => _QuickAddFabState();
}

class _QuickAddFabState extends State<QuickAddFab> {
  static const _pressedScale = 0.96;
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (_pressed == pressed || !mounted) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Listener(
        onPointerDown: (_) => _setPressed(true),
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed ? _pressedScale : 1,
          duration: PlanActMotion.duration(context, PlanActMotion.short),
          curve: PlanActMotion.curve,
          child: FloatingActionButton(
            key: const ValueKey('shell-quick-add'),
            tooltip: widget.tooltip,
            onPressed: widget.onPressed,
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}
