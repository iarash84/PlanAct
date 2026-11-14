import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/features/calendar/domain/calendar_transaction.dart';
import 'package:planact/features/classification/presentation/tag_badge.dart';
import 'package:planact/features/finance/presentation/account_identity_icon.dart';
import 'package:planact/features/finance/presentation/transaction_card.dart';

String calendarTransactionLabel(
  BuildContext context,
  CalendarTransaction item,
) {
  final l10n = planActL10n(context);
  final kind = switch (item.kind) {
    CalendarTransactionKind.income => l10n.calendarTransactionIncome,
    CalendarTransactionKind.expense => l10n.calendarTransactionExpense,
    CalendarTransactionKind.transfer => l10n.calendarTransactionTransfer,
  };
  return item.reversed ? '$kind · ${l10n.calendarTransactionReversed}' : kind;
}

/// The same wrapping card and item clearance in Month and both Week layouts.
class CalendarTransactionTile extends StatelessWidget {
  const CalendarTransactionTile({super.key, required this.item, this.onTap});
  final CalendarTransaction item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = item.localTime;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: PlanActSpacing.sm),
      child: TransactionCard(
        key: ValueKey('calendar-transaction-${item.entry.id.value}'),
        entry: item.entry,
        label: calendarTransactionLabel(context, item),
        amount: PersianMoneyText.amount(
          item.entry.amount.minorUnits,
          item.entry.amount.currency,
          unit: MoneyUnitScope.of(context),
        ),
        onTap: onTap,
        children: [
          Text(
            PersianNumbers.format(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            ),
            style: theme.textTheme.bodyMedium,
          ),
          if (item.entry.note?.isNotEmpty ?? false)
            Text(item.entry.note!, style: theme.textTheme.bodyMedium),
          for (final account in item.accounts)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccountIdentityIcon(account: account),
                const SizedBox(width: PlanActSpacing.sm),
                Expanded(
                  child: Text(
                    [
                      account.name,
                      if (account.bank != null)
                        iranianBankLabel(context, account.bank!),
                    ].join(' · '),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          if (item.tags.isNotEmpty)
            Wrap(
              spacing: PlanActSpacing.xs,
              runSpacing: PlanActSpacing.xs,
              children: [
                for (final tag in item.tags) TagBadge(label: tag.label),
              ],
            ),
        ],
      ),
    );
  }
}
