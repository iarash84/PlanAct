import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_status_colors.dart';

enum PlanActMessageKind { info, empty, success, error, warning }

/// Shared feedback; callers retain ownership of commands and state.
class PlanActStateMessage extends StatelessWidget {
  const PlanActStateMessage({
    super.key,
    required this.message,
    this.isError = false,
    this.kind = PlanActMessageKind.info,
    this.title,
    this.action,
  });

  final String message;

  /// Compatibility for existing callers. True takes precedence over [kind].
  final bool isError;
  final PlanActMessageKind kind;
  final String? title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors =
        theme.extension<PlanActStatusColors>() ??
        (theme.brightness == Brightness.dark
            ? PlanActStatusColors.dark
            : PlanActStatusColors.light);
    final effectiveKind = isError ? PlanActMessageKind.error : kind;
    final (icon, color) = switch (effectiveKind) {
      PlanActMessageKind.info => (Icons.info_outline, colors.info),
      PlanActMessageKind.empty => (
        Icons.inbox_outlined,
        theme.colorScheme.onSurfaceVariant,
      ),
      PlanActMessageKind.success => (
        Icons.check_circle_outline,
        colors.success,
      ),
      PlanActMessageKind.error => (
        Icons.error_outline,
        theme.colorScheme.error,
      ),
      PlanActMessageKind.warning => (
        Icons.warning_amber_outlined,
        colors.attention,
      ),
    };
    return Semantics(
      liveRegion:
          effectiveKind == PlanActMessageKind.error ||
          effectiveKind == PlanActMessageKind.warning ||
          effectiveKind == PlanActMessageKind.success,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: PlanActSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icon, color: color)),
            const SizedBox(height: PlanActSpacing.sm),
            if (title != null) ...[
              Semantics(
                header: true,
                child: Text(title!, style: theme.textTheme.titleMedium),
              ),
              const SizedBox(height: PlanActSpacing.sm),
            ],
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
