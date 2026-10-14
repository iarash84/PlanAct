import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';

class BalancePoint {
  const BalancePoint(this.date, this.amount);
  final DateTime date;
  final int amount;
}

/// Civil-day iteration avoids DST-sized duration assumptions. Always full ledger.
List<BalancePoint> accountBalanceSeries(
  ReportSnapshot snapshot,
  StableId accountId,
  ReportFilter filter,
) {
  final entries = snapshot.entries
      .where((e) => e.accountId == accountId)
      .toList();
  var balance = 0;
  final daily = <DateTime, int>{};
  for (final entry in entries) {
    final day = reportDate(entry.occurredAt);
    if (day.isBefore(filter.from)) {
      balance += entry.signedAmount.minorUnits;
    } else if (filter.dateMatches(day)) {
      daily[day] = (daily[day] ?? 0) + entry.signedAmount.minorUnits;
    }
  }
  final result = <BalancePoint>[];
  for (
    var day = filter.from;
    !day.isAfter(filter.to);
    day = DateTime(day.year, day.month, day.day + 1)
  ) {
    balance += daily[day] ?? 0;
    result.add(BalancePoint(day, balance));
  }
  return result;
}

enum FinancialDueState { settled, partial, pending, overdue }

bool isRecurringExpense(ReportSettlement item) =>
    item.row.commitment.kind == CommitmentKind.recurring &&
    item.expectation.direction == FinancialExpectationDirection.outgoing;

String jalaliReportMonth(Object date) {
  final day = JalaliDate.fromDateTime(reportDate(date));
  return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}';
}

Map<String, ReportCashTotal> monthlyCashTotals(
  List<ReportMovement> movements,
  String currency,
  ReportFilter filter,
) {
  final months = <String, ReportCashTotal>{};
  final first = JalaliDate.fromDateTime(filter.from);
  var month = JalaliDate(first.year, first.month, 1);
  while (!month.toDateTime().isAfter(filter.to)) {
    months[jalaliReportMonth(month.toDateTime())] = ReportCashTotal();
    month = month.addMonths(1);
  }
  for (final m in movements) {
    if (!filter.dateMatches(m.entry.occurredAt) ||
        m.entry.amount.currency != currency ||
        !{
          AccountEntryType.income,
          AccountEntryType.expense,
          AccountEntryType.refund,
        }.contains(m.cashType)) {
      continue;
    }
    (months[jalaliReportMonth(m.entry.occurredAt)] ??= ReportCashTotal()).add(
      m,
    );
  }
  return months;
}

Map<String, List<ReportSettlement>> recurringSettlementMonths(
  List<ReportSettlement> rows,
) {
  final months = <String, List<ReportSettlement>>{};
  for (final s in rows.where(isRecurringExpense)) {
    (months[jalaliReportMonth(s.row.occurrence.currentScheduledAt)] ??= []).add(
      s,
    );
  }
  return months;
}

FinancialDueState financialDueState(ReportSettlement item, DateTime now) {
  if (item.remaining == 0) return FinancialDueState.settled;
  final due = item.row.occurrence.currentScheduledAt;
  final overdue = due is DateTime
      ? due.isBefore(now)
      : reportDate(due).isBefore(reportDate(now));
  if (overdue) return FinancialDueState.overdue;
  return item.allocated > 0
      ? FinancialDueState.partial
      : FinancialDueState.pending;
}

Map<String, int> categoryShares(
  List<ReportMovement> movements,
  String currency,
  AccountEntryType type,
) {
  final totals = <String, int>{};
  for (final m in movements) {
    if (m.entry.amount.currency != currency || m.cashType != type) continue;
    final key = m.category ?? PersianCopy.financeReportsKeyMessage;
    totals[key] = (totals[key] ?? 0) + m.minorUnits;
  }
  return totals;
}

ReportFilter precedingPeriod(ReportFilter f) {
  final end = DateTime(f.from.year, f.from.month, f.from.day - 1);
  final start = DateTime(end.year, end.month, end.day - f.dayCount + 1);
  return ReportFilter(
    from: start,
    to: end,
    tags: f.tags,
    excludedTags: f.excludedTags,
    tagMode: f.tagMode,
    tagSource: f.tagSource,
    commitmentId: f.commitmentId,
    cycleId: f.cycleId,
    commitmentKind: f.commitmentKind,
    occurrenceStatus: f.occurrenceStatus,
    accountId: f.accountId,
    category: f.category,
    entryType: f.entryType,
    currency: f.currency,
    source: f.source,
    settlementState: f.settlementState,
    query: f.query,
    originalDate: f.originalDate,
  );
}
