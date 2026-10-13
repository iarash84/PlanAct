import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';

/// Inline empty/error feedback; callers retain ownership of commands and state.
class PlanActStateMessage extends StatelessWidget {
  const PlanActStateMessage({
    super.key,
    required this.message,
    this.isError = false,
    this.action,
  });

  final String message;
  final bool isError;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: isError,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PlanActSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: PlanActSpacing.sm),
            Text(message, style: theme.textTheme.bodyLarge),
            if (action != null) ...[
              const SizedBox(height: PlanActSpacing.sm),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
