import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';
import 'package:planact/features/today/application/attention_engine.dart';

// Count source visits rather than asserting machine-dependent elapsed times.
class CountingList<T> extends ListBase<T> {
  CountingList(this.values);
  final List<T> values;
  int reads = 0;

  @override
  int get length => values.length;
  @override
  set length(int value) => throw UnsupportedError('Read-only fixture');
  @override
  T operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, T value) =>
      throw UnsupportedError('Read-only fixture');
}

void main() {
  final now = DateTime(2026, 11, 8, 12);

  test('Today and Reports scan source matches a bounded number of times', () {
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب',
      currency: 'IRR',
      type: FinancialAccountType.cash,
    );
    final entries = List.generate(
      200,
      (_) => AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 100, currency: 'IRR'),
        occurredAt: now,
      ),
    );
    TransactionMatch match(AccountEntry entry, MatchStatus status) {
      final id = StableId.generate();
      return TransactionMatch(
        id: id,
        transactionId: entry.id,
        transactionAmount: entry.amount,
        createdAt: now,
        status: status,
        allocations: [
          MatchAllocation(
            id: StableId.generate(),
            matchId: id,
            occurrenceId: StableId.generate(),
            amount: const Money(minorUnits: 40, currency: 'IRR'),
          ),
        ],
      );
    }

    final active = [
      for (final entry in entries) match(entry, MatchStatus.active),
    ];
    final reviews = [
      for (var i = 0; i < entries.length; i += 2)
        RelationshipReview.project(
          transactionId: entries[i].id,
          transactionAmount: entries[i].amount,
          matches: [active[i]],
        ).append(RelationshipReviewDecision.independent, now),
    ];
    // A later inactive history record must invalidate the old independent token.
    final matches = CountingList([
      ...active.reversed,
      match(entries.first, MatchStatus.corrected),
    ]);
    final dashboard = const AttentionEngine().build(
      now: now,
      commitments: const [],
      plans: const {},
      expectations: const [],
      matches: matches,
      inboxSuggestions: const [],
      entries: entries,
      accounts: [account],
      reviewEntries: reviews,
    );
    expect(dashboard.financialSnapshot.unmatchedTransactionCount, 101);
    expect(dashboard.financialSnapshot.balances, {'IRR': -20000});
    expect(matches.reads, lessThanOrEqualTo(matches.length * 2));
    expect(dashboard.attention.map((item) => item.amountMinorUnits).toSet(), {
      60,
    });

    matches.reads = 0;
    final report = buildPersonalReport(
      ReportSnapshot(
        accounts: [account],
        entries: entries,
        matches: matches,
        reviews: reviews,
      ),
      ReportFilter(from: now, to: now),
      kind: PersonalReportKind.overview,
      now: now,
    );
    expect(report.unreviewed.length, 101);
    expect(report.unreviewed, contains(entries.first.id));
    expect(report.unreviewed, isNot(contains(entries[2].id)));
    expect(report.cashTotals['IRR']!.outgoing, 20000);
    expect(matches.reads, lessThanOrEqualTo(matches.length * 3));
  });

  test(
    'Today ledger visits do not grow with account count; refresh is fresh',
    () {
      final accounts = List.generate(
        40,
        (i) => FinancialAccount(
          id: StableId.generate(),
          name: 'حساب $i',
          currency: i.isEven ? 'IRR' : 'USD',
          type: FinancialAccountType.cash,
          status: i == 39
              ? FinancialAccountStatus.archived
              : FinancialAccountStatus.active,
        ),
      );
      final entries = CountingList([
        for (final account in accounts)
          for (final type in [
            AccountEntryType.openingBalance,
            AccountEntryType.expense,
            AccountEntryType.reversal,
            AccountEntryType.adjustment,
            AccountEntryType.transferOut,
          ])
            AccountEntry(
              id: StableId.generate(),
              accountId: account.id,
              type: type,
              amount: Money(
                minorUnits: type == AccountEntryType.adjustment ? -10 : 100,
                currency: account.currency,
              ),
              occurredAt: now,
            ),
      ]);
      TodayDashboard build() => const AttentionEngine().build(
        now: now,
        commitments: const [],
        plans: const {},
        expectations: const [],
        matches: const [],
        inboxSuggestions: const [],
        entries: entries,
        accounts: accounts,
      );
      expect(build().financialSnapshot.balances, {'IRR': -200, 'USD': -190});
      expect(entries.reads, lessThanOrEqualTo(entries.length * 3));
      entries.values.add(
        AccountEntry(
          id: StableId.generate(),
          accountId: accounts.first.id,
          type: AccountEntryType.income,
          amount: const Money(minorUnits: 50, currency: 'IRR'),
          occurredAt: now,
        ),
      );
      expect(build().financialSnapshot.balances, {'IRR': -150, 'USD': -190});
    },
  );
}
