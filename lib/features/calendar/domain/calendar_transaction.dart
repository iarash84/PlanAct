import 'package:planact/features/calendar/domain/calendar_visibility.dart';
import 'package:planact/features/classification/domain/tag.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

enum CalendarTransactionKind { income, expense, transfer }

final class CalendarTransaction {
  const CalendarTransaction({
    required this.entry,
    required this.kind,
    required this.reversed,
    this.accounts = const [],
    this.tags = const [],
  });
  final List<FinancialAccount> accounts;
  final List<Tag> tags;
  final AccountEntry entry;
  final CalendarTransactionKind kind;
  final bool reversed;
  DateTime get localTime => entry.occurredAt.toLocal();
  LocalDate get date => LocalDate.fromDateTime(localTime);
}

/// Only durable ledger entries enter this projection, never Inbox drafts.
/// Reversal evidence is inspected across the full ledger, not just the range.
List<CalendarTransaction> projectCalendarTransactions(
  Iterable<AccountEntry> entries,
  CalendarVisibility visibility,
  LocalDate start,
  LocalDate endExclusive,
) {
  final all = entries.toList();
  final reversed = <String>{
    for (final entry in all)
      if (entry.type == AccountEntryType.reversal ||
          (entry.referenceId != null &&
              (entry.note == 'حذف امن تراکنش ${entry.referenceId}' ||
                  entry.note == 'اصلاح تراکنش ${entry.referenceId}')))
        if (entry.referenceId != null) entry.referenceId!,
  };
  final reversedGroups = <String>{
    for (final entry in all)
      if (entry.transferGroupId != null && reversed.contains(entry.id.value))
        entry.transferGroupId!.value,
  };
  final transfers = <String, AccountEntry>{};
  // Prefer the outgoing leg irrespective of repository iteration order.
  for (final entry in all) {
    if (entry.type != AccountEntryType.transferIn &&
        entry.type != AccountEntryType.transferOut) {
      continue;
    }
    final key = entry.transferGroupId?.value ?? entry.id.value;
    final previous = transfers[key];
    if (previous == null ||
        (previous.type != AccountEntryType.transferOut &&
            entry.type == AccountEntryType.transferOut) ||
        (previous.type == entry.type &&
            entry.id.value.compareTo(previous.id.value) < 0)) {
      transfers[key] = entry;
    }
  }
  final result = <CalendarTransaction>[];
  for (final entry in all) {
    // Known legacy compensations are history evidence, not a second payment.
    if (entry.referenceId != null &&
        (entry.note == 'حذف امن تراکنش ${entry.referenceId}' ||
            entry.note == 'اصلاح تراکنش ${entry.referenceId}')) {
      continue;
    }
    final kind = switch (entry.type) {
      AccountEntryType.income when visibility.income =>
        CalendarTransactionKind.income,
      AccountEntryType.expense when visibility.expense =>
        CalendarTransactionKind.expense,
      AccountEntryType.transferIn || AccountEntryType.transferOut
          when visibility.transfers =>
        CalendarTransactionKind.transfer,
      _ => null,
    };
    if (kind == null) continue;
    if (kind == CalendarTransactionKind.transfer &&
        transfers[entry.transferGroupId?.value ?? entry.id.value] != entry) {
      continue;
    }
    final isReversed =
        reversed.contains(entry.id.value) ||
        (entry.transferGroupId != null &&
            reversedGroups.contains(entry.transferGroupId!.value));
    final item = CalendarTransaction(
      entry: entry,
      kind: kind,
      reversed: isReversed,
    );
    if (item.date.compareTo(start) >= 0 &&
        item.date.compareTo(endExclusive) < 0) {
      result.add(item);
    }
  }
  result.sort((a, b) {
    final time = a.entry.occurredAt.compareTo(b.entry.occurredAt);
    return time != 0 ? time : a.entry.id.value.compareTo(b.entry.id.value);
  });
  return result;
}
