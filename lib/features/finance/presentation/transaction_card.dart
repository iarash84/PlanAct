import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/transaction_direction.dart';

/// Presentation only: consumers retain their own amount and history semantics.
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.entry,
    required this.label,
    required this.amount,
    required this.children,
    this.operations,
    this.onTap,
  });

  final AccountEntry entry;
  final String label;
  final String amount;
  final List<Widget> children;
  final Widget? operations;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(PlanActSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PlanActSpacing.md,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TransactionDirectionIcon(entry: entry),
                  const SizedBox(width: PlanActSpacing.md),
                  Expanded(
                    child: Text(label, style: theme.textTheme.titleMedium),
                  ),
                  if (operations != null) ...[
                    const SizedBox(width: PlanActSpacing.sm),
                    operations!,
                  ] else if (onTap != null) ...[
                    const SizedBox(width: PlanActSpacing.sm),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
              Text(amount, style: theme.textTheme.titleLarge),
              if (children.isNotEmpty) ...[
                const Divider(height: PlanActSpacing.xs),
                DefaultTextStyle.merge(
                  style: secondary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: PlanActSpacing.sm,
                    children: children,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
