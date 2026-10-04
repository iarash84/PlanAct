import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

enum AttentionReason {
  overdueCommitment,
  overdueUnpaidExpectation,
  upcomingObligation,
  expectedIncomingMissing,
  unmatchedTransaction,
  ambiguousReconciliation,
  inboxReview,
}

enum AttentionAction {
  determineOccurrenceStatus,
  reconcilePayment,
  reviewExpectedIncoming,
  classifyTransaction,
  reviewInbox,
  resolveReconciliation,
}

extension AttentionReasonX on AttentionReason {
  AttentionAction get action => switch (this) {
    AttentionReason.overdueCommitment =>
      AttentionAction.determineOccurrenceStatus,
    AttentionReason.overdueUnpaidExpectation =>
      AttentionAction.reconcilePayment,
    AttentionReason.upcomingObligation => AttentionAction.reconcilePayment,
    AttentionReason.expectedIncomingMissing =>
      AttentionAction.reviewExpectedIncoming,
    AttentionReason.unmatchedTransaction => AttentionAction.classifyTransaction,
    AttentionReason.ambiguousReconciliation =>
      AttentionAction.resolveReconciliation,
    AttentionReason.inboxReview => AttentionAction.reviewInbox,
  };
}

extension AttentionActionX on AttentionAction {
  String get label => switch (this) {
    AttentionAction.determineOccurrenceStatus => 'تعیین وضعیت',
    AttentionAction.reconcilePayment => 'تطبیق پرداخت',
    AttentionAction.reviewExpectedIncoming => 'بررسی دریافت',
    AttentionAction.classifyTransaction => 'تعیین ارتباط',
    AttentionAction.reviewInbox => 'بازبینی تراکنش',
    AttentionAction.resolveReconciliation => 'حل مغایرت',
  };
}

class AttentionItem {
  const AttentionItem({
    required this.id,
    required this.reason,
    required this.title,
    required this.explanation,
    required this.urgency,
    this.amountMinorUnits,
    this.currency,
    this.occurredAt,
    this.accountName,
    this.description,
  });

  final String id;
  final AttentionReason reason;
  final String title;
  final String explanation;
  final int urgency;
  final int? amountMinorUnits;
  final String? currency;
  final DateTime? occurredAt;
  final String? accountName;
  final String? description;

  AttentionAction get action => reason.action;

  String get actionLabel => action.label;
}

class FinancialSnapshot {
  const FinancialSnapshot({
    required this.balances,
    required this.upcomingOutgoingMinorUnits,
    required this.expectedIncomingMinorUnits,
    required this.unmatchedTransactionCount,
    this.isEstimated = false,
  });

  final Map<String, int> balances;
  final int upcomingOutgoingMinorUnits;
  final int expectedIncomingMinorUnits;
  final int unmatchedTransactionCount;
  final bool isEstimated;

  bool get hasReliableBalances => !isEstimated && balances.isNotEmpty;
}

class TodayDashboard {
  const TodayDashboard({
    required this.attention,
    required this.today,
    required this.next,
    required this.inbox,
    required this.financialSnapshot,
  });

  final List<AttentionItem> attention;
  final List<Commitment> today;
  final List<Commitment> next;
  final List<AttentionItem> inbox;
  final FinancialSnapshot financialSnapshot;
}

enum TodayActionItemType { occurrence, financialReview, inboxReview }

class TodayActionItem {
  const TodayActionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.urgency,
    this.scheduledAt,
    this.sourceReference,
    this.attentionAction,
    this.attentionItem,
    this.commitment,
  });

  final String id;
  final TodayActionItemType type;
  final String title;
  final String subtitle;
  final int urgency;
  final DateTime? scheduledAt;
  final String? sourceReference;
  final AttentionAction? attentionAction;
  final AttentionItem? attentionItem;
  final Commitment? commitment;

  String get actionLabel => attentionAction?.label ?? 'اقدام';
}

class TodayActionCenter {
  const TodayActionCenter({
    required this.attention,
    required this.today,
    required this.upcoming,
  });

  final List<TodayActionItem> attention;
  final List<TodayActionItem> today;
  final List<TodayActionItem> upcoming;

  bool get isEmpty => attention.isEmpty && today.isEmpty && upcoming.isEmpty;
}

class AttentionEngine {
  const AttentionEngine({this.nextLimit = 5});

  final int nextLimit;

  TodayActionCenter buildActionCenter({
    required DateTime now,
    required Iterable<Commitment> commitments,
    required Map<StableId, List<Occurrence>> plans,
    required Iterable<FinancialExpectation> expectations,
    required Iterable<TransactionMatch> matches,
    required Iterable<InboxSuggestion> inboxSuggestions,
    required Iterable<AccountEntry> entries,
    required Iterable<FinancialAccount> accounts,
  }) {
    final dashboard = build(
      now: now,
      commitments: commitments,
      plans: plans,
      expectations: expectations,
      matches: matches,
      inboxSuggestions: inboxSuggestions,
      entries: entries,
      accounts: accounts,
    );
    final byCommitment = {for (final item in commitments) item.id: item};
    final occurrenceById = <String, Occurrence>{};
    final commitmentByOccurrence = <String, Commitment>{};
    for (final entry in plans.entries) {
      for (final occurrence in entry.value) {
        occurrenceById[occurrence.id.value] = occurrence;
        final commitment = byCommitment[entry.key];
        if (commitment != null) {
          commitmentByOccurrence[occurrence.id.value] = commitment;
        }
      }
    }

    final attention = <TodayActionItem>[];
    for (final item in dashboard.attention) {
      final source = item.id.split(':').skip(1).join(':');
      final occurrence = occurrenceById[source];
      final commitment = commitmentByOccurrence[source];
      final type = occurrence != null
          ? TodayActionItemType.occurrence
          : item.reason == AttentionReason.inboxReview
          ? TodayActionItemType.inboxReview
          : TodayActionItemType.financialReview;
      attention.add(
        TodayActionItem(
          id: item.id,
          type: type,
          title: commitment?.title ?? item.title,
          subtitle: occurrence == null
              ? item.explanation
              : 'این نوبت عقب‌افتاده است؛ وضعیت آن را ثبت کنید.',
          urgency: item.urgency,
          scheduledAt:
              _dateOf(occurrence?.currentScheduledAt) ?? item.occurredAt,
          sourceReference: source,
          attentionItem: item,
          attentionAction: item.action,
          commitment: commitment,
        ),
      );
    }

    final today = <TodayActionItem>[];
    final upcoming = <TodayActionItem>[];
    for (final entry in plans.entries) {
      final commitment = byCommitment[entry.key];
      if (commitment == null ||
          commitment.status == CommitmentStatus.archived) {
        continue;
      }
      for (final occurrence in entry.value) {
        final date = occurrence.currentScheduledAt;
        if (date is! DateTime || !_unresolved(occurrence)) continue;
        if (_sameDay(date, now)) {
          today.add(
            TodayActionItem(
              id: 'today:${occurrence.id.value}',
              type: TodayActionItemType.occurrence,
              title: commitment.title,
              subtitle: 'امروز؛ اقدام بعدی را انتخاب کنید.',
              urgency: 60,
              scheduledAt: date,
              sourceReference: occurrence.id.value,
              commitment: commitment,
            ),
          );
        } else if (date.isAfter(now) &&
            date.difference(now) <= const Duration(days: 7)) {
          upcoming.add(
            TodayActionItem(
              id: 'upcoming-occurrence:${occurrence.id.value}',
              type: TodayActionItemType.occurrence,
              title: commitment.title,
              subtitle: 'در روزهای آینده؛ برای آن آماده شوید.',
              urgency: 20,
              scheduledAt: date,
              sourceReference: occurrence.id.value,
              commitment: commitment,
            ),
          );
        }
      }
    }

    int compare(TodayActionItem a, TodayActionItem b) {
      final urgency = b.urgency.compareTo(a.urgency);
      if (urgency != 0) return urgency;
      final date = (a.scheduledAt ?? DateTime(9999, 12, 31)).compareTo(
        b.scheduledAt ?? DateTime(9999, 12, 31),
      );
      return date != 0 ? date : a.id.compareTo(b.id);
    }

    attention.sort(compare);
    today.sort(compare);
    upcoming.sort(compare);
    return TodayActionCenter(
      attention: List.unmodifiable(attention),
      today: List.unmodifiable(today),
      upcoming: List.unmodifiable(upcoming.take(nextLimit)),
    );
  }

  TodayDashboard build({
    required DateTime now,
    required Iterable<Commitment> commitments,
    required Map<StableId, List<Occurrence>> plans,
    required Iterable<FinancialExpectation> expectations,
    required Iterable<TransactionMatch> matches,
    required Iterable<InboxSuggestion> inboxSuggestions,
    required Iterable<AccountEntry> entries,
    required Iterable<FinancialAccount> accounts,
  }) {
    final activeCommitments = commitments.where(
      (item) => item.status != CommitmentStatus.archived,
    );
    final today = <Commitment>[];
    final future = <_FutureCommitment>[];
    final attention = <AttentionItem>[];
    final expectedDates = <StableId, DateTime>{};

    for (final commitment in activeCommitments) {
      final occurrences = plans[commitment.id] ?? const <Occurrence>[];
      for (final occurrence in occurrences) {
        final date = _dateOf(occurrence.currentScheduledAt);
        if (date == null) continue;
        expectedDates[occurrence.id] = date;
        if (!_unresolved(occurrence)) continue;
        if (_sameDay(date, now)) {
          if (!today.contains(commitment)) today.add(commitment);
        } else if (date.isAfter(now)) {
          future.add(_FutureCommitment(commitment, date));
        } else {
          attention.add(
            AttentionItem(
              id: 'commitment:${occurrence.id.value}',
              reason: AttentionReason.overdueCommitment,
              title: commitment.title,
              explanation: 'این تعهد سررسید شده و هنوز تکمیل نشده است.',
              urgency: 100,
              occurredAt: date,
            ),
          );
        }
      }
    }

    final allocatedByOccurrence = <StableId, int>{};
    final matchedTransactionIds = <StableId>{};
    for (final match in matches.where((m) => m.status == MatchStatus.active)) {
      matchedTransactionIds.add(match.transactionId);
      for (final allocation in match.allocations) {
        allocatedByOccurrence[allocation.occurrenceId] =
            (allocatedByOccurrence[allocation.occurrenceId] ?? 0) +
            allocation.amount.minorUnits;
      }
    }

    var outgoing = 0;
    var incoming = 0;
    for (final expectation in expectations.where(
      (item) => item.status == FinancialExpectationStatus.active,
    )) {
      final date = expectedDates[expectation.occurrenceId];
      if (date == null) continue;
      final remaining =
          expectation.amount -
          (allocatedByOccurrence[expectation.occurrenceId] ?? 0);
      if (remaining <= 0) continue;
      final overdueOrToday = !date.isAfter(now);
      if (expectation.direction == FinancialExpectationDirection.outgoing) {
        if (overdueOrToday) {
          attention.add(
            AttentionItem(
              id: 'expectation:${expectation.id.value}',
              reason: AttentionReason.overdueUnpaidExpectation,
              title: 'پرداخت مورد انتظار',
              explanation: date.isBefore(now)
                  ? 'پرداخت مورد انتظار سررسید شده و هنوز کامل تطبیق داده نشده است.'
                  : 'پرداخت مورد انتظار امروز سررسید می‌شود و هنوز کامل تطبیق داده نشده است.',
              urgency: date.isBefore(now) ? 95 : 80,
              occurredAt: date,
              amountMinorUnits: remaining,
              currency: expectation.currency,
            ),
          );
        } else if (date.difference(now) <= const Duration(days: 7)) {
          outgoing += remaining;
        }
      } else if (overdueOrToday) {
        attention.add(
          AttentionItem(
            id: 'incoming:${expectation.id.value}',
            reason: AttentionReason.expectedIncomingMissing,
            title: 'دریافت مورد انتظار',
            explanation: 'دریافت مورد انتظار سررسید شده و هنوز با تراکنش تطبیق داده نشده است.',
            urgency: 75,
            occurredAt: date,
            amountMinorUnits: remaining,
            currency: expectation.currency,
          ),
        );
      } else if (date.difference(now) <= const Duration(days: 7)) {
        incoming += remaining;
      }
    }

    final inbox = inboxSuggestions
        .where(
          (item) =>
              item.status == SuggestionStatus.pending ||
              item.status == SuggestionStatus.edited,
        )
        .map(
          (item) => AttentionItem(
            id: 'inbox:${item.id.value}',
            reason: AttentionReason.inboxReview,
            title: item.draft.type.isEmpty ? 'تراکنش واردشده' : item.draft.type,
            explanation: 'یک تراکنش بانکی نیاز به بررسی دارد.',
            urgency: 70,
            amountMinorUnits: item.draft.amount.minorUnits,
            currency: item.draft.amount.currency,
            occurredAt: item.draft.occurredAt,
            description: item.draft.merchant,
          ),
        )
        .toList();
    attention.addAll(inbox);

    final unmatched = entries.where(
      (entry) => !matchedTransactionIds.contains(entry.id),
    );
    final accountNames = {
      for (final account in accounts) account.id: account.name,
    };
    for (final entry in unmatched) {
      attention.add(
        AttentionItem(
          id: 'transaction:${entry.id.value}',
          reason: AttentionReason.unmatchedTransaction,
          title: 'تراکنش نیازمند بررسی',
          explanation: 'این تراکنش هنوز به تعهد یا پرداختی مرتبط نشده است.',
          urgency: 65,
          amountMinorUnits: entry.amount.minorUnits,
          currency: entry.amount.currency,
          occurredAt: entry.occurredAt,
          accountName: accountNames[entry.accountId],
          description: entry.note ?? entry.category,
        ),
      );
    }

    attention.sort((a, b) {
      final urgency = b.urgency.compareTo(a.urgency);
      if (urgency != 0) return urgency;
      final date = (a.occurredAt ?? DateTime(9999, 12, 31)).compareTo(
        b.occurredAt ?? DateTime(9999, 12, 31),
      );
      return date != 0 ? date : a.id.compareTo(b.id);
    });
    future
      ..removeWhere((item) => today.contains(item.commitment))
      ..sort((a, b) => a.date.compareTo(b.date));
    final balances = <String, int>{};
    for (final account in accounts.where(
      (a) => a.status == FinancialAccountStatus.active,
    )) {
      balances[account.currency] =
          (balances[account.currency] ?? 0) +
          rebuildBalance(account, entries).minorUnits;
    }

    return TodayDashboard(
      attention: List.unmodifiable(attention),
      today: List.unmodifiable(today),
      next: List.unmodifiable(
        future.take(nextLimit).map((item) => item.commitment),
      ),
      inbox: List.unmodifiable(inbox),
      financialSnapshot: FinancialSnapshot(
        balances: Map.unmodifiable(balances),
        upcomingOutgoingMinorUnits: outgoing,
        expectedIncomingMinorUnits: incoming,
        unmatchedTransactionCount: unmatched.length,
      ),
    );
  }

  DateTime? _dateOf(Object? value) {
    if (value is DateTime) return value;
    if (value is LocalDate) {
      return DateTime(value.year, value.month, value.day);
    }
    return null;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _unresolved(Occurrence occurrence) =>
      occurrence.status != OccurrenceStatus.completed &&
      occurrence.status != OccurrenceStatus.cancelled &&
      occurrence.status != OccurrenceStatus.skipped;
}

class _FutureCommitment {
  const _FutureCommitment(this.commitment, this.date);
  final Commitment commitment;
  final DateTime date;
}
