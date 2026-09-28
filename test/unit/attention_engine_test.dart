import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
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
