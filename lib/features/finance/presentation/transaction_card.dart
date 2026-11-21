import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/transaction_direction.dart';
import 'package:planact/features/finance/presentation/transaction_history_section.dart';

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
          padding: const EdgeInsets.all(PlanActSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: PlanActSpacing.xs,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final direction = Directionality.of(context);
                  double textWidth(String text, TextStyle? style) {
                    final painter = TextPainter(
                      text: TextSpan(text: text, style: style),
                      textDirection: direction,
                      textScaler: MediaQuery.textScalerOf(context),
                      locale: Localizations.maybeLocaleOf(context),
                    )..layout();
                    final width = painter.width;
                    painter.dispose();
                    return width;
                  }

                  // Measure the actual localized/scaled strings, not a device
                  // breakpoint. Unbounded text always has a full-width fallback.
                  final trailing =
                      operations ??
                      (onTap == null
                          ? null
                          : Icon(
                              Icons.chevron_right,
                              color: theme.colorScheme.onSurfaceVariant,
                            ));
                  final available =
                      constraints.maxWidth -
                      40 -
                      PlanActSpacing.md -
                      (trailing == null
                          ? 0
                          : PlanActSpacing.touchTarget + PlanActSpacing.sm);
                  final amountWidth = textWidth(
                    amount,
                    theme.textTheme.titleLarge,
                  );
                  final labelWidth = textWidth(
                    label,
                    theme.textTheme.titleMedium,
                  );
                  final grouped = amountWidth <= available;
                  final inline =
                      grouped &&
                      amountWidth + labelWidth + PlanActSpacing.md <= available;
                  final title = Text(label, style: theme.textTheme.titleMedium);
                  final value = Text(amount, style: theme.textTheme.titleLarge);
                  final header = Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      TransactionDirectionIcon(entry: entry),
                      const SizedBox(width: PlanActSpacing.md),
                      Expanded(
                        child: !grouped
                            ? title
                            : inline
                            ? Row(
                                children: [
                                  title,
                                  const SizedBox(width: PlanActSpacing.md),
                                  Expanded(child: value),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [title, value],
                              ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: PlanActSpacing.sm),
                        trailing,
                      ],
                    ],
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: PlanActSpacing.xs,
                    children: [header, if (!grouped) value],
                  );
                },
              ),
              if (entry.history case final history?)
                if (history.chain.isNotEmpty ||
                    history.role.replacement ||
                    history.role.corrected ||
                    history.role.reversed ||
                    history.role.reversalPurpose != null)
                  TransactionHistorySection(history: history),
              if (children.isNotEmpty) ...[
                const Divider(height: PlanActSpacing.xs),
                DefaultTextStyle.merge(
                  style: secondary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: PlanActSpacing.xs,
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
