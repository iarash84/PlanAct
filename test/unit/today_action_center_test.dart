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

  Occurrence occurrence(DateTime date) {
    final id = StableId.generate(timestamp: date);
    return Occurrence(
      id: id,
      cycleId: StableId.generate(
        timestamp: date.add(const Duration(seconds: 1)),
      ),
      scheduleDefinitionId: StableId.generate(
        timestamp: date.add(const Duration(seconds: 2)),
      ),
      occurrenceKey: id.value,
      originalScheduledAt: date,
      currentScheduledAt: date,
      status: OccurrenceStatus.scheduled,
    );
  }

  TodayActionCenter buildCenter({
    Iterable<Commitment> commitments = const [],
    Map<StableId, List<Occurrence>> plans = const {},
    Iterable<FinancialExpectation> expectations = const [],
    Iterable<TransactionMatch> matches = const [],
    Iterable<InboxSuggestion> inboxSuggestions = const [],
    Iterable<AccountEntry> entries = const [],
    Iterable<FinancialAccount> accounts = const [],
  }) => const AttentionEngine().buildActionCenter(
    now: now,
    commitments: commitments,
    plans: plans,
    expectations: expectations,
    matches: matches,
    inboxSuggestions: inboxSuggestions,
    entries: entries,
    accounts: accounts,
  );

  test(
    'projects unresolved today and overdue occurrences deterministically',
    () {
      final overdue = commitment('قدیمی');
      final today = commitment('امروز');
      final oldOccurrence = occurrence(now.subtract(const Duration(days: 2)));
      final todayOccurrence = occurrence(
        now.subtract(const Duration(hours: 2)),
      );

      final center = buildCenter(
        commitments: [today, overdue],
        plans: {
          overdue.id: [oldOccurrence],
          today.id: [todayOccurrence],
        },
      );

      expect(center.attention.single.commitment, overdue);
      expect(center.today.single.commitment, today);
      expect(center.attention.single.type, TodayActionItemType.occurrence);
      expect(
        center.attention.single.attentionAction,
        AttentionAction.determineOccurrenceStatus,
      );
      expect(center.attention.single.actionLabel, 'تعیین وضعیت');
    },
  );

  test('keeps financial and Inbox review items identifiable', () {
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
      id: StableId.generate(timestamp: now.add(const Duration(seconds: 1))),
      stagedImportId: stagedId,
      draft: TransactionDraft(
        id: StableId.generate(timestamp: now.add(const Duration(seconds: 2))),
        stagedImportId: stagedId,
        amount: const Money(minorUnits: 500, currency: 'IRR'),
        occurredAt: now,
        type: 'واریز',
      ),
    );

    final center = buildCenter(
      inboxSuggestions: [suggestion],
      entries: [entry],
      accounts: [account],
    );

    expect(
      center.attention.map((item) => item.type),
      contains(TodayActionItemType.inboxReview),
    );
    expect(
      center.attention.map((item) => item.type),
      contains(TodayActionItemType.financialReview),
    );
    expect(
      center.attention.every((item) => item.attentionItem != null),
      isTrue,
    );
    expect(
      center.attention
          .where((item) => item.type == TodayActionItemType.inboxReview)
          .single
          .actionLabel,
      'بازبینی تراکنش',
    );
  });

  test('returns an empty projection when there are no actionable sources', () {
    expect(buildCenter().isEmpty, isTrue);
  });
}
