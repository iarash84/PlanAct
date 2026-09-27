import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/finance/domain/finance.dart';

class FinanceFilter {
  const FinanceFilter({
    this.accountId,
    this.from,
    this.to,
    this.type,
    this.category,
    this.matched,
  });

  final String? accountId;
  final DateTime? from;
  final DateTime? to;
  final AccountEntryType? type;
  final String? category;
  final bool? matched;
}

List<AccountEntry> filterEntries(
  Iterable<AccountEntry> entries,
  FinanceFilter filter, {
  Set<String> matchedEntryIds = const {},
}) => entries
    .where((entry) {
      if (filter.accountId != null &&
          entry.accountId.value != filter.accountId) {
        return false;
      }
      if (filter.from != null && entry.occurredAt.isBefore(filter.from!)) {
        return false;
      }
      if (filter.to != null && entry.occurredAt.isAfter(filter.to!)) {
        return false;
      }
      if (filter.type != null && entry.type != filter.type) {
        return false;
      }
      if (filter.category != null && entry.category != filter.category) {
        return false;
      }
      if (filter.matched != null &&
          matchedEntryIds.contains(entry.id.value) != filter.matched) {
        return false;
      }
      return true;
    })
    .toList(growable: false);

class CashFlowSummary {
  const CashFlowSummary({
    required this.incoming,
    required this.outgoing,
    required this.currency,
  });

  final int incoming;
  final int outgoing;
  final String currency;
  int get net => incoming - outgoing;
}

CashFlowSummary cashFlowSummary(
  Iterable<AccountEntry> entries,
  String currency,
) {
  var incoming = 0;
  var outgoing = 0;
  for (final entry in entries) {
    if (entry.amount.currency != currency) continue;
    if (entry.type == AccountEntryType.income ||
        entry.type == AccountEntryType.refund) {
      incoming += entry.amount.minorUnits;
    } else if (entry.type == AccountEntryType.expense) {
      outgoing += entry.amount.minorUnits;
    }
  }
  return CashFlowSummary(
    incoming: incoming,
    outgoing: outgoing,
    currency: currency,
  );
}

class PlannedActualSummary {
  const PlannedActualSummary({
    required this.expectedIncoming,
    required this.receivedIncoming,
    required this.expectedOutgoing,
    required this.settledOutgoing,
    required this.outstandingCount,
    required this.overdueCount,
  });

  final int expectedIncoming;
  final int receivedIncoming;
  final int expectedOutgoing;
  final int settledOutgoing;
  final int outstandingCount;
  final int overdueCount;

  int get outstandingIncoming =>
      (expectedIncoming - receivedIncoming).clamp(0, expectedIncoming);
  int get outstandingOutgoing =>
      (expectedOutgoing - settledOutgoing).clamp(0, expectedOutgoing);
}

PlannedActualSummary plannedActualSummary(
  Iterable<FinancialExpectationSettlement> settlements, {
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  var expectedIncoming = 0;
  var receivedIncoming = 0;
  var expectedOutgoing = 0;
  var settledOutgoing = 0;
  var outstandingCount = 0;
  var overdueCount = 0;
  for (final item in settlements) {
    final expectation = item.expectation;
    final allocated = item.allocatedAmount?.minorUnits ?? 0;
    if (expectation.direction == FinancialExpectationDirection.incoming) {
      expectedIncoming += expectation.amount;
      receivedIncoming += allocated.clamp(0, expectation.amount);
    } else {
      expectedOutgoing += expectation.amount;
      settledOutgoing += allocated.clamp(0, expectation.amount);
    }
    if (!item.settled) {
      outstandingCount++;
      if (expectation.createdAt.isBefore(at)) overdueCount++;
    }
  }
  return PlannedActualSummary(
    expectedIncoming: expectedIncoming,
    receivedIncoming: receivedIncoming,
    expectedOutgoing: expectedOutgoing,
    settledOutgoing: settledOutgoing,
    outstandingCount: outstandingCount,
    overdueCount: overdueCount,
  );
}

Money sumMoney(Iterable<AccountEntry> entries, String currency) {
  var total = 0;
  for (final entry in entries) {
    if (entry.amount.currency == currency) {
      total += entry.signedAmount.minorUnits;
    }
  }
  return Money(minorUnits: total, currency: currency);
}
