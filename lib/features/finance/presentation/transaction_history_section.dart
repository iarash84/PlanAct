import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/features/finance/domain/transaction_history.dart';
import 'package:planact/features/finance/presentation/transaction_direction.dart';

/// System evidence is deliberately separate from the user's description.
class TransactionHistorySection extends StatelessWidget {
  const TransactionHistorySection({super.key, required this.history});
  final TransactionHistory history;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: PlanActSpacing.xs,
    children: [
      TransactionRoleLabel(role: history.role),
      if (history.chain.isNotEmpty)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            icon: const Icon(Icons.account_tree_outlined),
            label: Text(planActL10n(context).transactionHistoryOpen),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (context) => PlanActFormSheet(
                title: planActL10n(context).transactionHistoryTitle,
                secondaryLabel: planActL10n(context).commonClose,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: PlanActSpacing.lg,
                  children: [
                    for (final item in history.chain)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: PlanActSpacing.xs,
                        children: [
                          TransactionRoleLabel(
                            role: item.role,
                            showOriginal: true,
                          ),
                          Text(
                            '${transactionLabel(item.entry)} · ${PersianMoneyText.amount(item.entry.amount.minorUnits, item.entry.amount.currency, unit: MoneyUnitScope.of(context))}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            PersianDateFormatter.date(
                              JalaliDate.fromDateTime(
                                item.entry.occurredAt.toLocal(),
                              ),
                            ),
                          ),
                          if (item.entry.note?.isNotEmpty ?? false)
                            Text(item.entry.note!),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class TransactionRoleLabel extends StatelessWidget {
  const TransactionRoleLabel({
    super.key,
    required this.role,
    this.showOriginal = false,
  });
  final TransactionHistoryRole role;
  final bool showOriginal;

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final labels = <String>[
      if (role.replacement) l10n.transactionReplacement,
      if (role.corrected) l10n.transactionCorrected,
      if (role.reversed) l10n.transactionReversedHistory,
      if (role.reversalPurpose != null)
        switch (role.reversalPurpose!) {
          ReversalPurpose.correction => l10n.transactionCorrectionReversal,
          ReversalPurpose.cancellation => l10n.transactionCancellationReversal,
          ReversalPurpose.unknown => l10n.transactionUnknownReversal,
        },
    ];
    if (labels.isEmpty && !showOriginal) return const SizedBox.shrink();
    if (labels.isEmpty) labels.add(l10n.transactionHistoryOriginal);
    final help = switch (role.reversalPurpose) {
      ReversalPurpose.correction => l10n.transactionCorrectionReversalHelp,
      ReversalPurpose.cancellation => l10n.transactionCancellationReversalHelp,
      _ =>
        role.replacement && !role.reversed
            ? l10n.transactionReplacementHelp
            : null,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          role.reversalPurpose != null
              ? Icons.undo
              : Icons.history_edu_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: PlanActSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final label in labels)
                Text(label, style: Theme.of(context).textTheme.labelLarge),
              if (help != null)
                Text(help, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
