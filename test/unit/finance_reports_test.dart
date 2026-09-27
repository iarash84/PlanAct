import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/finance_reports.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';

void main() {
  final account = FinancialAccount(
    id: StableId.generate(timestamp: DateTime.utc(2026, 1, 1)),
    name: 'بانک',
    currency: 'IRR',
    type: FinancialAccountType.bank,
  );

  AccountEntry entry(AccountEntryType type, int amount, {String? category}) =>
      AccountEntry(
        id: StableId.generate(timestamp: DateTime.utc(2026, 1, amount)),
        accountId: account.id,
        type: type,
        amount: Money(minorUnits: amount, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 1, amount),
        category: category,
      );

  test('cash flow totals preserve integer monetary precision', () {
    final result = cashFlowSummary([
      entry(AccountEntryType.income, 1001),
      entry(AccountEntryType.expense, 300, category: 'خوراک'),
    ], 'IRR');
    expect(result.incoming, 1001);
    expect(result.outgoing, 300);
    expect(result.net, 701);
  });

  test('filters by account, category and direction', () {
    final items = [
      entry(AccountEntryType.expense, 100, category: 'خوراک'),
      entry(AccountEntryType.income, 200, category: 'حقوق'),
    ];
    expect(
      filterEntries(items, const FinanceFilter(category: 'خوراک')),
      hasLength(1),
    );
    expect(
      filterEntries(items, const FinanceFilter(type: AccountEntryType.income)),
      hasLength(1),
    );
  });

  test('planned actual reports settled and outstanding amounts', () {
    final now = DateTime.utc(2026, 2, 1);
    final incoming = FinancialExpectation(
      id: StableId.generate(timestamp: now),
      occurrenceId: StableId.generate(
        timestamp: now.add(const Duration(seconds: 1)),
      ),
      direction: FinancialExpectationDirection.incoming,
      amount: 1000,
      currency: 'IRR',
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now,
    );
    final result = plannedActualSummary([
      FinancialExpectationSettlement(
        expectation: incoming,
        allocatedAmount: const Money(minorUnits: 400, currency: 'IRR'),
      ),
    ], now: now);
    expect(result.expectedIncoming, 1000);
    expect(result.receivedIncoming, 400);
    expect(result.outstandingCount, 1);
    expect(result.overdueCount, 1);
  });
}
