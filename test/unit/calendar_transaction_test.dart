import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/money/currency.dart';
import 'package:planact/features/calendar/domain/calendar_transaction.dart';
import 'package:planact/features/calendar/domain/calendar_visibility.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

AccountEntry calendarEntry(
  AccountEntryType type,
  DateTime date, {
  StableId? group,
  String? reference,
  String? note,
}) => AccountEntry(
  id: StableId.generate(),
  accountId: StableId.generate(),
  type: type,
  amount: Money(minorUnits: 12000, currency: CurrencyCodes.irr),
  occurredAt: date,
  transferGroupId: group,
  referenceId: reference,
  note: note,
);

void main() {
  test('actual dates, exclusive boundaries, type filters, transfer once and history', () {
    final day = LocalDate(2026, 11, 14);
    final date = DateTime(2026, 11, 14, 0, 1);
    final income = calendarEntry(AccountEntryType.income, date);
    final expense = calendarEntry(AccountEntryType.expense, date);
    final group = StableId.generate();
    final outgoing = calendarEntry(
      AccountEntryType.transferOut,
      date,
      group: group,
    );
    final incoming = calendarEntry(
      AccountEntryType.transferIn,
      date,
      group: group,
    );
    final reversal = calendarEntry(
      AccountEntryType.reversal,
      date.add(const Duration(days: 5)),
      reference: outgoing.id.value,
    );
    final entries = [
      incoming,
      income,
      expense,
      outgoing,
      reversal,
      calendarEntry(AccountEntryType.income, DateTime(2026, 11, 15)),
      calendarEntry(AccountEntryType.expense, DateTime(2026, 11, 13, 23, 59)),
      calendarEntry(AccountEntryType.openingBalance, date),
      calendarEntry(AccountEntryType.adjustment, date),
    ];
    expect(
      projectCalendarTransactions(
        entries,
        const CalendarVisibility(),
        day,
        day.addDays(1),
      ),
      isEmpty,
    );
    final all = projectCalendarTransactions(
      entries,
      const CalendarVisibility(income: true, expense: true, transfers: true),
      day,
      day.addDays(1),
    );
    expect(all, hasLength(3));
    final transfer = all.singleWhere(
      (item) => item.kind == CalendarTransactionKind.transfer,
    );
    expect(transfer.entry.id, outgoing.id);
    expect(transfer.reversed, isTrue);
    expect(transfer.date, day);
    expect(
      projectCalendarTransactions(
        entries.reversed,
        const CalendarVisibility(transfers: true),
        day,
        day.addDays(1),
      ).single.entry.id,
      outgoing.id,
    );
    expect(
      projectCalendarTransactions(
        entries,
        const CalendarVisibility(income: true),
        day,
        day.addDays(1),
      ).single.entry.id,
      income.id,
    );
    expect(
      projectCalendarTransactions(
        entries,
        const CalendarVisibility(expense: true),
        day,
        day.addDays(1),
      ).single.entry.id,
      expense.id,
    );
    expect(
      projectCalendarTransactions(
        [calendarEntry(AccountEntryType.income, date.toUtc())],
        const CalendarVisibility(income: true),
        day,
        day.addDays(1),
      ).single.date,
      day,
    );
  });
}
