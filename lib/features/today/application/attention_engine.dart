import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

/// The reason an item is actionable. No score is exposed: ordering is based on
/// deterministic urgency, while the explanation remains understandable.
enum AttentionReason {
  overdueCommitment,
  overdueUnpaidExpectation,
  upcomingObligation,
  expectedIncomingMissing,
  unmatchedTransaction,
  ambiguousReconciliation,
  inboxReview,
}

class AttentionItem {
  const AttentionItem({
    required this.id,
    required this.reason,
    required this.title,
    required this.explanation,
    required this.urgency,
  });

  final String id;
  final AttentionReason reason;
  final String title;
  final String explanation;
  final int urgency;
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

/// Application-layer projection for the operational Today screen.
///
/// This service only classifies information that is present in the supplied
/// domain data. It never invents urgency, balances, dates, or settlement.
class AttentionEngine {
  const AttentionEngine({this.nextLimit = 5});

  final int nextLimit;

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
        if (_sameDay(date, now)) {
          if (!today.contains(commitment)) today.add(commitment);
        } else if (date.isAfter(now) &&
            occurrence.status != OccurrenceStatus.completed &&
            occurrence.status != OccurrenceStatus.cancelled) {
          future.add(_FutureCommitment(commitment, date));
        } else if (date.isBefore(now) &&
            occurrence.status != OccurrenceStatus.completed &&
            occurrence.status != OccurrenceStatus.cancelled &&
            occurrence.status != OccurrenceStatus.skipped) {
          attention.add(
            AttentionItem(
              id: 'commitment:${occurrence.id.value}',
              reason: AttentionReason.overdueCommitment,
              title: commitment.title,
              explanation: 'این تعهد سررسید شده و هنوز تکمیل نشده است.',
              urgency: 100,
            ),
          );
        }
      }
    }

    final activeMatches = matches.where((m) => m.status == MatchStatus.active);
    final allocatedByOccurrence = <StableId, int>{};
    final matchedTransactionIds = <StableId>{};
    for (final match in activeMatches) {
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
      if (expectation.direction == FinancialExpectationDirection.outgoing) {
        if (!date.isAfter(now)) {
          attention.add(
            AttentionItem(
              id: 'expectation:${expectation.id.value}',
              reason: AttentionReason.overdueUnpaidExpectation,
              title: 'پرداخت مورد انتظار',
              explanation: date.isBefore(now)
                  ? 'پرداخت مورد انتظار سررسید شده و هنوز کامل تطبیق داده نشده است.'
                  : 'پرداخت مورد انتظار امروز سررسید می‌شود و هنوز کامل تطبیق داده نشده است.',
              urgency: date.isBefore(now) ? 95 : 80,
            ),
          );
        } else if (date.difference(now).inDays <= 7) {
          outgoing += remaining;
          attention.add(
            AttentionItem(
              id: 'upcoming:${expectation.id.value}',
              reason: AttentionReason.upcomingObligation,
              title: 'پرداخت مورد انتظار',
              explanation: 'پرداخت مورد انتظار در روزهای آینده سررسید می‌شود.',
              urgency: 40,
            ),
          );
        }
      } else {
        if (!date.isAfter(now)) {
          attention.add(
            AttentionItem(
              id: 'incoming:${expectation.id.value}',
              reason: AttentionReason.expectedIncomingMissing,
              title: 'دریافت مورد انتظار',
              explanation: 'دریافت مورد انتظار سررسید شده و هنوز با تراکنش تطبیق داده نشده است.',
              urgency: 75,
            ),
          );
        } else if (date.difference(now).inDays <= 7) {
          incoming += remaining;
        }
      }
    }

    final pendingInbox = inboxSuggestions.where(
      (item) =>
          item.status == SuggestionStatus.pending ||
          item.status == SuggestionStatus.edited,
    );
    final inbox = pendingInbox
        .map(
          (item) => AttentionItem(
            id: 'inbox:${item.id.value}',
            reason: AttentionReason.inboxReview,
            title: 'تراکنش واردشده',
            explanation: 'یک تراکنش بانکی نیاز به بررسی دارد.',
            urgency: 70,
          ),
        )
        .toList();
    attention.addAll(inbox);

    final unmatched = entries.where(
      (entry) => !matchedTransactionIds.contains(entry.id),
    );
    for (final entry in unmatched) {
      attention.add(
        AttentionItem(
          id: 'transaction:${entry.id.value}',
          reason: AttentionReason.unmatchedTransaction,
          title: 'تراکنش بدون تطبیق',
          explanation: 'یک تراکنش بانکی نیاز به بررسی و تطبیق دارد.',
          urgency: 65,
        ),
      );
    }

    attention.sort((a, b) => b.urgency.compareTo(a.urgency));
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

  DateTime? _dateOf(Object value) => value is DateTime ? value : null;
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _FutureCommitment {
  const _FutureCommitment(this.commitment, this.date);
  final Commitment commitment;
  final DateTime date;
}
