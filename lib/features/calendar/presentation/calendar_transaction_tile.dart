import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/features/calendar/domain/calendar_transaction.dart';

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

class CalendarTransactionTile extends StatelessWidget {
  const CalendarTransactionTile({super.key, required this.item, this.onTap});
  final CalendarTransaction item;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final time = item.localTime;
    return Card(
      child: ListTile(
        key: ValueKey('calendar-transaction-${item.entry.id.value}'),
        leading: Icon(
          item.reversed
              ? Icons.undo
              : switch (item.kind) {
                  CalendarTransactionKind.income => Icons.south_west,
                  CalendarTransactionKind.expense => Icons.north_east,
                  CalendarTransactionKind.transfer => Icons.swap_horiz,
                },
        ),
        title: Text(calendarTransactionLabel(context, item)),
        subtitle: Text(
          [
            PersianMoneyText.amount(
              item.entry.amount.minorUnits,
              item.entry.amount.currency,
              unit: MoneyUnitScope.of(context),
            ),
            PersianNumbers.format(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            ),
            if (item.entry.note?.isNotEmpty ?? false) item.entry.note!,
          ].join(' · '),
        ),
        onTap: onTap,
      ),
    );
  }
}
