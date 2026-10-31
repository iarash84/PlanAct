import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';

/// Shared information hierarchy for Today and selected-day commitment cards.
/// Domain-specific actions and projections remain owned by each consumer.
class CommitmentCardLayout extends StatelessWidget {
  const CommitmentCardLayout({
    super.key,
    required this.leading,
    required this.title,
    required this.metadata,
    required this.actions,
    this.tags,
    this.preview,
    this.details,
    this.expanded = false,
    this.onOpen,
    this.grouped = false,
  });

  final Widget leading;
  final String title;
  final Widget metadata;
  final List<Widget> actions;
  final Widget? tags;
  final Widget? preview;
  final Widget? details;
  final bool expanded;
  final VoidCallback? onOpen;
  final bool grouped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.all(PlanActSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onOpen,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: PlanActSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leading,
                  const SizedBox(width: PlanActSpacing.md),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ],
              ),
            ),
          ),
          if (tags != null) ...[
            const SizedBox(height: PlanActSpacing.sm),
            tags!,
          ],
          const SizedBox(height: PlanActSpacing.md),
          DefaultTextStyle.merge(
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            child: metadata,
          ),
          if (preview != null) ...[
            const SizedBox(height: PlanActSpacing.md),
            const Divider(height: 1),
            preview!,
          ],
          const SizedBox(height: PlanActSpacing.sm),
          Wrap(
            spacing: PlanActSpacing.sm,
            runSpacing: PlanActSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: actions,
          ),
          AnimatedSize(
            duration: PlanActMotion.duration(context),
            curve: PlanActMotion.curve,
            alignment: AlignmentDirectional.topStart,
            child: !expanded || details == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: PlanActSpacing.md,
                        ),
                        child: Divider(height: 1),
                      ),
                      details!,
                    ],
                  ),
          ),
        ],
      ),
    );
    return grouped ? content : Card(child: content);
  }
}
