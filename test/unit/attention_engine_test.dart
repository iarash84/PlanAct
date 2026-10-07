import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/today/application/attention_engine.dart';

void main() {
  final now = DateTime(2026, 9, 27, 12);

  Commitment commitment(String title) =>
      Commitment.create(title: title, now: now);

  Occurrence occurrence(
    DateTime at, {
    OccurrenceStatus status = OccurrenceStatus.scheduled,
  }) {
    final id = StableId.generate(timestamp: at);
    return Occurrence(
      id: id,
      cycleId: StableId.generate(timestamp: at),
      scheduleDefinitionId: StableId.generate(timestamp: at),
      occurrenceKey: id.value,
      originalScheduledAt: at,
      currentScheduledAt: at,
      status: status,
    );
  }

  test('partial remainder stays actionable until explicitly reviewed; reopening restores it', () {
    final entry = AccountEntry(
      id: StableId.generate(),
      accountId: StableId.generate(),
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 1000, currency: 'IRR'),
      occurredAt: now,
    );
    final matchId = StableId.generate();
    final match = TransactionMatch(
      id: matchId,
      transactionId: entry.id,
      transactionAmount: entry.amount,
      createdAt: now,
      allocations: [
        MatchAllocation(
          id: StableId.generate(),
          matchId: matchId,
          occurrenceId: StableId.generate(),
          amount: const Money(minorUnits: 400, currency: 'IRR'),
        ),
      ],
    );
    TodayDashboard project(
      List<RelationshipReviewEntry> history, {
      List<TransactionMatch>? allocations,
    }) => const AttentionEngine().build(
      now: now,
      commitments: const [],
      plans: const {},
      expectations: const [],
      matches: allocations ?? [match],
      inboxSuggestions: const [],
      entries: [entry],
      accounts: const [],
      reviewEntries: history,
    );
    final review = RelationshipReview.project(
      transactionId: entry.id,
      transactionAmount: entry.amount,
      matches: [match],
    );
    final independent = review.append(
      RelationshipReviewDecision.independent,
      now,
    );
    expect(project([]).attention.single.amountMinorUnits, 600);
    expect(project([]).financialSnapshot.unmatchedTransactionCount, 1);
    expect(project([independent]).attention, isEmpty);
    expect(
      project([independent]).financialSnapshot.unmatchedTransactionCount,
      0,
    );
    // A changed allocation invalidates the old decision, even without UI rules.
    expect(
      project([independent], allocations: []).attention.single.amountMinorUnits,
      1000,
    );
    final reopened = RelationshipReview.project(
      transactionId: entry.id,
      transactionAmount: entry.amount,
      matches: [match],
      latestDecision: independent,
    ).append(RelationshipReviewDecision.reopened, now);
    expect(
      project([reopened, independent]).attention.single.amountMinorUnits,
      600,
    );
    final center = const AttentionEngine().buildActionCenter(
      now: now,
      commitments: const [],
      plans: const {},
      expectations: const [],
      matches: [match],
      inboxSuggestions: const [],
      entries: [entry],
      accounts: const [],
      reviewEntries: [independent],
    );
    expect(center.attention, isEmpty);
  });

  test('transfers, reversals, reversed originals and adjustments are not relationship actions', () {
    final originalId = StableId.generate();
    final entries = [
      for (final type in AccountEntryType.values)
        AccountEntry(
          id: type == AccountEntryType.expense
              ? originalId
              : StableId.generate(),
          accountId: StableId.generate(),
          type: type,
          amount: const Money(minorUnits: 1000, currency: 'IRR'),
          occurredAt: now,
          referenceId: type == AccountEntryType.reversal
              ? originalId.value
              : null,
        ),
    ];
    final dashboard = const AttentionEngine().build(
      now: now,
      commitments: const [],
      plans: const {},
      expectations: const [],
      matches: const [],
      inboxSuggestions: const [],
      entries: entries,
      accounts: const [],
    );
    final income = entries.singleWhere(
      (e) => e.type == AccountEntryType.income,
    );
    expect(dashboard.attention.single.id, 'transaction:${income.id.value}');
    expect(dashboard.financialSnapshot.unmatchedTransactionCount, 1);
  });

  test('classifies overdue commitments and upcoming commitments', () {
    final overdue = commitment('قسط دیروز');
    final upcoming = commitment('قسط آینده');
    final overdueOccurrence = occurrence(now.subtract(const Duration(days: 1)));
    final upcomingOccurrence = occurrence(now.add(const Duration(days: 2)));

    final result = const AttentionEngine().build(
      now: now,
      commitments: [overdue, upcoming],
      plans: {
        // Stable IDs are replaced below because plans are keyed by commitment.
      },
      expectations: const [],
      matches: const [],
      inboxSuggestions: const [],
      entries: const [],
      accounts: const [],
    );

    // The empty projection above is intentional smoke coverage for no-data
    // safety; build a keyed projection for the actual classification below.
    final classified = const AttentionEngine().build(
      now: now,
      commitments: [overdue, upcoming],
      plans: {
        overdue.id: [overdueOccurrence],
        upcoming.id: [upcomingOccurrence],
      },
      expectations: const [],
      matches: const [],
      inboxSuggestions: const [],
      entries: const [],
      accounts: const [],
    );

    expect(result.attention, isEmpty);
    expect(
      classified.attention.first.reason,
      AttentionReason.overdueCommitment,
    );
    expect(classified.today, isEmpty);
    expect(classified.next, [upcoming]);
  });

  test('does not retain settled expectations as attention', () {
    final item = commitment('پرداخت');
    final planned = occurrence(
      now.subtract(const Duration(days: 1)),
      status: OccurrenceStatus.completed,
    );
    final expectation = FinancialExpectation(
      id: StableId.generate(timestamp: now),
      occurrenceId: planned.id,
      direction: FinancialExpectationDirection.outgoing,
      amount: 1000,
      currency: 'IRR',
      createdAt: now,
      updatedAt: now,
    );
    final matchId = StableId.generate(timestamp: now);
    final match = TransactionMatch(
      id: matchId,
      transactionId: StableId.generate(timestamp: now),
      transactionAmount: const Money(minorUnits: 1000, currency: 'IRR'),
      createdAt: now,
      allocations: [
        MatchAllocation(
          id: StableId.generate(timestamp: now),
          matchId: matchId,
          occurrenceId: planned.id,
          amount: const Money(minorUnits: 1000, currency: 'IRR'),
        ),
      ],
    );

    final result = const AttentionEngine().build(
      now: now,
      commitments: [item],
      plans: {
        item.id: [planned],
      },
      expectations: [expectation],
      matches: [match],
      inboxSuggestions: const [],
      entries: const [],
      accounts: const [],
    );

    expect(result.attention, isEmpty);
  });

  test('classifies all-day local-date occurrences in today and next', () {
    final commitment = Commitment.create(title: 'تاریخ مهم', now: now);
    final occurrence = Occurrence(
      id: StableId.generate(timestamp: now),
      cycleId: StableId.generate(timestamp: now),
      scheduleDefinitionId: StableId.generate(timestamp: now),
      occurrenceKey: 'all-day',
      originalScheduledAt: LocalDate(2026, 9, 28),
      currentScheduledAt: LocalDate(2026, 9, 28),
      status: OccurrenceStatus.scheduled,
    );

    final result = const AttentionEngine().build(
      now: DateTime(2026, 9, 27, 12),
      commitments: [commitment],
      plans: {
        commitment.id: [occurrence],
      },
      expectations: const [],
      matches: const [],
      inboxSuggestions: const [],
      entries: const [],
      accounts: const [],
    );

    expect(result.today, isEmpty);
    expect(result.next, contains(commitment));
    expect(result.attention, isEmpty);
  });

  test('classifies pending inbox and unmatched transaction', () {
    final account = FinancialAccount(
      id: StableId.generate(timestamp: now),
      name: 'بانک',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    final entry = AccountEntry(
      id: StableId.generate(timestamp: now),
      accountId: account.id,
      type: AccountEntryType.income,
      amount: const Money(minorUnits: 500, currency: 'IRR'),
      occurredAt: now,
    );
    final stagedId = StableId.generate(timestamp: now);
    final suggestion = InboxSuggestion(
      id: StableId.generate(timestamp: now),
      stagedImportId: stagedId,
      draft: TransactionDraft(
        id: StableId.generate(timestamp: now),
        stagedImportId: stagedId,
        amount: const Money(minorUnits: 500, currency: 'IRR'),
        occurredAt: now,
        type: 'واریز',
      ),
    );

    final result = const AttentionEngine().build(
      now: now,
      commitments: const [],
      plans: const {},
      expectations: const [],
      matches: const [],
      inboxSuggestions: [suggestion],
      entries: [entry],
      accounts: [account],
    );

    expect(result.inbox, hasLength(1));
    expect(
      result.attention.any(
        (i) => i.reason == AttentionReason.unmatchedTransaction,
      ),
      isTrue,
    );
    expect(result.financialSnapshot.balances['IRR'], 500);
  });
}
