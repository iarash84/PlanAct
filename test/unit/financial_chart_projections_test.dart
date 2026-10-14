import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reports/domain/financial_chart_projections.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  final account = StableId.generate();
  AccountEntry entry(
    int amount,
    DateTime date, {
    AccountEntryType type = AccountEntryType.income,
    String category = 'کار',
    String currency = 'IRR',
    StableId? id,
  }) => AccountEntry(
    id: StableId.generate(),
    accountId: id ?? account,
    type: type,
    amount: Money(minorUnits: amount, currency: currency),
    occurredAt: date,
    category: category,
  );

  test('full-ledger end-day balance includes transfers, negative adjustment and end day; ignores tag filter', () {
    final f = ReportFilter(
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 3),
      tags: {StableId.generate()},
    );
    final snapshot = ReportSnapshot(
      entries: [
        entry(100, DateTime(2026, 9, 30)),
        entry(40, DateTime(2026, 10, 1), type: AccountEntryType.transferOut),
        entry(-20, DateTime(2026, 10, 2), type: AccountEntryType.adjustment),
        entry(10, DateTime(2026, 10, 3, 23, 59)),
        entry(900, DateTime(2026, 10, 4)),
        entry(800, DateTime(2026, 10, 2), id: StableId.generate()),
      ],
    );
    expect(accountBalanceSeries(snapshot, account, f).map((p) => p.amount), [
      60,
      40,
      50,
    ]);
  });

  test('monthly cash uses Jalali boundaries, includes empty months and excludes transfers', () {
    final before = entry(100, DateTime(2026, 3, 20));
    final after = entry(
      40,
      DateTime(2026, 3, 21),
      type: AccountEntryType.expense,
    );
    final transfer = entry(
      999,
      DateTime(2026, 4, 22),
      type: AccountEntryType.transferIn,
    );
    final f = ReportFilter(
      from: DateTime(2026, 3, 20),
      to: DateTime(2026, 4, 25),
    );
    final months = monthlyCashTotals(
      [
        ReportMovement(before, 100, before.type),
        ReportMovement(after, 40, after.type),
        ReportMovement(transfer, 999, transfer.type),
      ],
      'IRR',
      f,
    );
    expect(months.keys, ['1404-12', '1405-01', '1405-02']);
    expect(months['1404-12']!.incoming, 100);
    expect(months['1405-01']!.outgoing, 40);
    expect(months['1405-02']!.net, 0);
  });

  test(
    'preceding inclusive civil-day range retains financial and tag dimensions',
    () {
      final f = ReportFilter(
        from: DateTime(2026, 3, 1),
        to: DateTime(2026, 3, 31),
        tags: {StableId.generate()},
        accountId: account,
        category: 'کار',
        entryType: AccountEntryType.expense,
        tagSource: ReportTagSource.relatedAllocation,
        query: 'کلاس',
      );
      final previous = precedingPeriod(f);
      expect(previous.from, DateTime(2026, 1, 29));
      expect(previous.to, DateTime(2026, 2, 28));
      expect(previous.dayCount, 31);
      expect(previous.tags, f.tags);
      expect(previous.accountId, account);
      expect(previous.category, 'کار');
      expect(previous.entryType, AccountEntryType.expense);
      expect(previous.tagSource, f.tagSource);
      expect(previous.query, 'کلاس');
    },
  );

  test('category shares preserve signed corrections and isolate currency and direction', () {
    final original = entry(
      100,
      DateTime(2026),
      type: AccountEntryType.expense,
      category: 'آموزش',
    );
    final correction = entry(
      -30,
      DateTime(2026),
      type: AccountEntryType.reversal,
      category: 'دیگر',
    );
    final movements = [
      ReportMovement(original, 100, AccountEntryType.expense),
      ReportMovement(
        correction,
        -30,
        AccountEntryType.expense,
        original: original,
      ),
      ReportMovement(
        entry(200, DateTime(2026), currency: 'USD'),
        200,
        AccountEntryType.expense,
      ),
      ReportMovement(entry(700, DateTime(2026)), 700, AccountEntryType.income),
    ];
    expect(categoryShares(movements, 'IRR', AccountEntryType.expense), {
      'آموزش': 70,
    });
  });

  test('financial overdue uses due time or civil end-day, never completed status or creation date', () {
    final owner = Commitment.create(title: 'قسط');
    final cycle = CommitmentCycle.create(
      commitmentId: owner.id,
      cycleType: CommitmentCycleType.openEnded,
      startDate: DateTime(2026),
      completionRule: CompletionRule.manual,
    );
    ReportSettlement settlement(Object due, int allocated) {
      final o = Occurrence(
        id: StableId.generate(),
        cycleId: cycle.id,
        scheduleDefinitionId: StableId.generate(),
        occurrenceKey: 'slot',
        originalScheduledAt: due,
        currentScheduledAt: due,
        status: OccurrenceStatus.completed,
      );
      return ReportSettlement(
        ReportOccurrence(owner, cycle, o, null),
        FinancialExpectation(
          id: StableId.generate(),
          occurrenceId: o.id,
          direction: FinancialExpectationDirection.outgoing,
          amount: 100,
          createdAt: DateTime(2020),
          updatedAt: DateTime(2020),
        ),
        allocated,
      );
    }

    final now = DateTime(2026, 10, 13, 12);
    expect(
      financialDueState(settlement(LocalDate(2026, 10, 13), 0), now),
      FinancialDueState.pending,
    );
    expect(
      financialDueState(settlement(LocalDate(2026, 10, 12), 20), now),
      FinancialDueState.overdue,
    );
    expect(
      financialDueState(settlement(DateTime(2026, 10, 13, 11), 20), now),
      FinancialDueState.overdue,
    );
    expect(
      financialDueState(settlement(LocalDate(2026, 10, 14), 20), now),
      FinancialDueState.partial,
    );
    expect(
      financialDueState(settlement(LocalDate(2026, 10, 12), 120), now),
      FinancialDueState.settled,
    );
  });
}
