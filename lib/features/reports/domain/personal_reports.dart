import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/classification/domain/tag.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';

enum PersonalReportKind {
  overview,
  performance,
  attention,
  cashFlow,
  settlement,
  packages,
  topic,
  upcoming,
  changes,
  accounts,
}

enum ReportTagMode { any, all, untagged }

enum ReportTagSource { direct, relatedAllocation }

enum ReportSettlementState { unpaid, partial, settled, overpaid }

enum ReportGrouping { day, month, category, account }

/// Date-only filters use local civil dates, including the entire selected end day.
DateTime reportDate(Object value) {
  if (value is LocalDate) return DateTime(value.year, value.month, value.day);
  final local = (value as DateTime).toLocal();
  return DateTime(local.year, local.month, local.day);
}

class ReportFilter {
  ReportFilter({
    required Object from,
    required Object to,
    this.tags = const {},
    this.excludedTags = const {},
    this.tagMode = ReportTagMode.any,
    this.tagSource = ReportTagSource.direct,
    this.commitmentId,
    this.cycleId,
    this.commitmentKind,
    this.occurrenceStatus,
    this.accountId,
    this.category,
    this.entryType,
    this.currency,
    this.source,
    this.settlementState,
    this.query = '',
    this.originalDate = false,
  }) : from = reportDate(from),
       to = reportDate(to) {
    if (this.to.isBefore(this.from)) throw ArgumentError('Invalid date range');
  }
  final DateTime from, to;
  DateTime get endExclusive => DateTime(to.year, to.month, to.day + 1);
  int get dayCount => DateTime.utc(
    to.year,
    to.month,
    to.day + 1,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
  final Set<StableId> tags, excludedTags;
  final ReportTagMode tagMode;
  final ReportTagSource tagSource;
  final StableId? commitmentId, cycleId, accountId;
  final CommitmentKind? commitmentKind;
  final OccurrenceStatus? occurrenceStatus;
  final String? category, currency;
  final AccountEntryType? entryType;
  final AccountEntrySource? source;
  final ReportSettlementState? settlementState;
  final String query;
  final bool originalDate;

  bool dateMatches(Object value) {
    final date = reportDate(value);
    return !date.isBefore(from) && date.isBefore(endExclusive);
  }

  bool tagMatches(Set<StableId> membership) {
    if (membership.any(excludedTags.contains)) return false;
    if (tagMode == ReportTagMode.untagged) return membership.isEmpty;
    if (tags.isEmpty) return true;
    return tagMode == ReportTagMode.all
        ? tags.every(membership.contains)
        : tags.any(membership.contains);
  }

  bool textMatches(String text) =>
      text.toLowerCase().contains(query.trim().toLowerCase());
}

class ReportPreview {
  const ReportPreview(this.commitmentId, this.slot);
  final StableId commitmentId;
  final PlannedOccurrenceSlot slot;
}

/// One coherent, read-only durable snapshot. Memberships are keyed by stable ID.
class ReportSnapshot {
  const ReportSnapshot({
    this.commitments = const [],
    this.cycles = const [],
    this.occurrences = const [],
    this.actuals = const [],
    this.accounts = const [],
    this.entries = const [],
    this.expectations = const [],
    this.matches = const [],
    this.reviews = const [],
    this.entitlements = const [],
    this.ledger = const [],
    this.tags = const [],
    this.commitmentTags = const {},
    this.entryTags = const {},
    this.previews = const [],
  });
  final List<Commitment> commitments;
  final List<CommitmentCycle> cycles;
  final List<Occurrence> occurrences;
  final List<Actual> actuals;
  final List<FinancialAccount> accounts;
  final List<AccountEntry> entries;
  final List<FinancialExpectation> expectations;
  final List<TransactionMatch> matches;
  final List<RelationshipReviewEntry> reviews;
  final List<EntitlementPlan> entitlements;
  final List<EntitlementLedgerEntry> ledger;
  final List<Tag> tags;
  final Map<StableId, Set<StableId>> commitmentTags, entryTags;
  final List<ReportPreview> previews;
}

class ReportOccurrence {
  const ReportOccurrence(
    this.commitment,
    this.cycle,
    this.occurrence,
    this.actual,
  );
  final Commitment commitment;
  final CommitmentCycle cycle;
  final Occurrence occurrence;
  final Actual? actual;
  bool get resolved => {
    OccurrenceStatus.completed,
    OccurrenceStatus.cancelled,
    OccurrenceStatus.skipped,
    OccurrenceStatus.deferred,
  }.contains(occurrence.status);
}

class ReportMovement {
  const ReportMovement(
    this.entry,
    this.minorUnits,
    this.cashType, {
    this.original,
  });
  final AccountEntry entry;
  final AccountEntry? original;
  String? get category => (original ?? entry).category;

  /// Related mode contains only confirmed allocations, never the whole payment.
  final int minorUnits;
  final AccountEntryType cashType;
}

class ReportSettlement {
  const ReportSettlement(this.row, this.expectation, this.allocated);
  final ReportOccurrence row;
  final FinancialExpectation expectation;
  final int allocated;
  int get remaining =>
      (expectation.amount - allocated).clamp(0, expectation.amount);
  int get excess => (allocated - expectation.amount).clamp(0, allocated);
  ReportSettlementState get state => allocated > expectation.amount
      ? ReportSettlementState.overpaid
      : allocated == expectation.amount
      ? ReportSettlementState.settled
      : allocated > 0
      ? ReportSettlementState.partial
      : ReportSettlementState.unpaid;
}

class ReportPackage {
  const ReportPackage(
    this.commitment,
    this.cycle,
    this.plan,
    this.entries,
    this.movements,
  );
  final Commitment commitment;
  final CommitmentCycle cycle;
  final EntitlementPlan plan;
  final List<EntitlementLedgerEntry> entries, movements;
  EntitlementBalance get balance => const EntitlementLedger().fold(entries);
  bool get hasRecordedGrant =>
      entries.any((e) => e.type == EntitlementEntryType.grant);
}

class ReportAccount {
  const ReportAccount(this.account, this.opening, this.movement, this.closing);
  final FinancialAccount account;
  final int opening, movement, closing;
}

class ReportCashTotal {
  int incoming = 0, outgoing = 0;
  int get net => incoming - outgoing;
  void add(ReportMovement movement) {
    if (movement.cashType == AccountEntryType.income ||
        movement.cashType == AccountEntryType.refund) {
      incoming += movement.minorUnits;
    } else if (movement.cashType == AccountEntryType.expense) {
      outgoing += movement.minorUnits;
    }
  }
}

class PersonalReport {
  const PersonalReport({
    required this.occurrences,
    required this.movements,
    required this.settlements,
    required this.packages,
    required this.accounts,
    required this.previews,
    required this.unreviewed,
    required this.cashTotals,
  });
  final List<ReportOccurrence> occurrences;
  final List<ReportMovement> movements;
  final List<ReportSettlement> settlements;
  final List<ReportPackage> packages;
  final List<ReportAccount> accounts;
  final List<ReportPreview> previews;
  final Map<StableId, RelationshipReview> unreviewed;
  final Map<String, ReportCashTotal> cashTotals;
}

/// No clock, database, notification, financial or entitlement mutation.
PersonalReport buildPersonalReport(
  ReportSnapshot data,
  ReportFilter filter, {
  required PersonalReportKind kind,
  required DateTime now,
}) {
  final owners = {for (final c in data.commitments) c.id: c};
  final cycles = {for (final c in data.cycles) c.id: c};
  final entriesById = {for (final e in data.entries) e.id.value: e};
  final latestActual = <StableId, Actual>{};
  // Append order breaks ties, rather than treating a reopening as a second result.
  for (final a in data.actuals) {
    final previous = latestActual[a.occurrenceId];
    if (previous == null || !a.recordedAt.isBefore(previous.recordedAt)) {
      latestActual[a.occurrenceId] = a;
    }
  }
  bool ownerMatches(
    Commitment owner,
    StableId cycleId, {
    bool withTags = true,
  }) =>
      (filter.commitmentId == null || filter.commitmentId == owner.id) &&
      (filter.cycleId == null || filter.cycleId == cycleId) &&
      (filter.commitmentKind == null || filter.commitmentKind == owner.kind) &&
      (!withTags || filter.tagMatches(data.commitmentTags[owner.id] ?? {})) &&
      filter.textMatches('${owner.title} ${owner.description ?? ''}');
  final allRows = <StableId, ReportOccurrence>{};
  for (final o in data.occurrences) {
    final cycle = cycles[o.cycleId];
    final owner = owners[cycle?.commitmentId];
    if (owner != null && cycle != null) {
      allRows[o.id] = ReportOccurrence(owner, cycle, o, latestActual[o.id]);
    }
  }
  bool rowMatches(ReportOccurrence r) =>
      ownerMatches(r.commitment, r.cycle.id) &&
      (filter.occurrenceStatus == null ||
          r.occurrence.status == filter.occurrenceStatus) &&
      filter.dateMatches(
        filter.originalDate
            ? r.occurrence.originalScheduledAt
            : r.occurrence.currentScheduledAt,
      );
  final today = reportDate(now);
  bool pastDue(Object value) => value is DateTime
      ? value.isBefore(now)
      : reportDate(value).isBefore(today);
  final rows =
      allRows.values.where((r) {
        if (!rowMatches(r)) return false;
        if (kind == PersonalReportKind.upcoming) {
          return r.commitment.status == CommitmentStatus.active &&
              r.cycle.status == CommitmentCycleStatus.active &&
              !r.resolved &&
              !pastDue(r.occurrence.currentScheduledAt);
        }
        if (kind == PersonalReportKind.attention) {
          return r.commitment.status == CommitmentStatus.active &&
              !r.resolved &&
              pastDue(r.occurrence.currentScheduledAt);
        }
        if (kind == PersonalReportKind.changes) {
          return r.occurrence.isManualOverride ||
              r.occurrence.status == OccurrenceStatus.cancelled ||
              r.occurrence.originalScheduledAt !=
                  r.occurrence.currentScheduledAt;
        }
        return true;
      }).toList()..sort(
        (a, b) =>
            reportDate(a.occurrence.currentScheduledAt)
                .compareTo(reportDate(b.occurrence.currentScheduledAt)),
      );

  final reversedIds = data.entries
      .where((e) => e.type == AccountEntryType.reversal)
      .map((e) => e.referenceId)
      .toSet();
  final latestReview = <StableId, RelationshipReviewEntry>{};
  for (final review in data.reviews) {
    if (review.revision > (latestReview[review.transactionId]?.revision ?? 0)) {
      latestReview[review.transactionId] = review;
    }
  }
  final unreviewed = <StableId, RelationshipReview>{};
  final movements = <ReportMovement>[];
  for (final e in data.entries) {
    final original = e.type == AccountEntryType.reversal
        ? entriesById[e.referenceId]
        : null;
    final classification = original ?? e;
    if (!filter.dateMatches(e.occurredAt) ||
        (filter.accountId != null && filter.accountId != e.accountId) ||
        (filter.category != null &&
            filter.category != classification.category) ||
        (filter.currency != null && filter.currency != e.amount.currency) ||
        (filter.source != null && filter.source != classification.source) ||
        !filter.textMatches(
          '${classification.note ?? ''} ${classification.category ?? ''}',
        )) {
      continue;
    }
    final cashType = original?.type ?? e.type;
    if (filter.entryType != null && filter.entryType != cashType) continue;
    var amount = e.type == AccountEntryType.reversal && original != null
        ? -e.amount.minorUnits.abs()
        : e.amount.minorUnits;
    final related =
        filter.tagSource == ReportTagSource.relatedAllocation ||
        filter.commitmentId != null ||
        filter.cycleId != null ||
        filter.commitmentKind != null ||
        filter.occurrenceStatus != null;
    if (related) {
      var allocated = 0;
      for (final m in data.matches.where(
        (m) => m.status == MatchStatus.active && m.transactionId == e.id,
      )) {
        for (final a in m.allocations) {
          final r = allRows[a.occurrenceId];
          if (r != null &&
              (filter.occurrenceStatus == null ||
                  filter.occurrenceStatus == r.occurrence.status) &&
              ownerMatches(
                r.commitment,
                r.cycle.id,
                withTags: filter.tagSource == ReportTagSource.relatedAllocation,
              ) &&
              a.amount.currency == e.amount.currency) {
            allocated += a.amount.minorUnits;
          }
        }
      }
      // Active allocation amounts cannot attribute more real cash than was paid.
      amount = allocated.clamp(0, e.amount.minorUnits.abs());
      if (amount == 0 || reversedIds.contains(e.id.value)) continue;
    }
    if (filter.tagSource == ReportTagSource.direct &&
        !filter.tagMatches(data.entryTags[classification.id] ?? {})) {
      continue;
    }
    if ((e.type == AccountEntryType.income ||
            e.type == AccountEntryType.expense) &&
        !reversedIds.contains(e.id.value)) {
      final review = RelationshipReview.project(
        transactionId: e.id,
        transactionAmount: e.amount,
        matches: data.matches,
        latestDecision: latestReview[e.id],
      );
      if (review.remainderMinorUnits > 0 && !review.isIndependent) {
        unreviewed[e.id] = review;
      }
    }
    if (kind == PersonalReportKind.attention && !unreviewed.containsKey(e.id)) {
      continue;
    }
    movements.add(ReportMovement(e, amount, cashType, original: original));
  }
  movements.sort((a, b) => b.entry.occurredAt.compareTo(a.entry.occurredAt));
  final cashTotals = <String, ReportCashTotal>{};
  for (final m in movements) {
    if (![
      AccountEntryType.income,
      AccountEntryType.expense,
      AccountEntryType.refund,
    ].contains(m.cashType)) {
      continue;
    }
    (cashTotals[m.entry.amount.currency] ??= ReportCashTotal()).add(m);
  }

  final allocatedByOccurrence = <StableId, Map<String, int>>{};
  for (final match in data.matches) {
    if (match.status != MatchStatus.active ||
        reversedIds.contains(match.transactionId.value)) {
      continue;
    }
    final transaction = entriesById[match.transactionId.value];
    if (transaction == null ||
        ![
          AccountEntryType.income,
          AccountEntryType.expense,
        ].contains(transaction.type)) {
      continue;
    }
    for (final a in match.allocations) {
      final key = '${a.amount.currency}:${transaction.type.name}';
      final amounts = allocatedByOccurrence[a.occurrenceId] ??= {};
      amounts[key] = (amounts[key] ?? 0) + a.amount.minorUnits;
    }
  }
  final settlements = <ReportSettlement>[];
  for (final expectation in data.expectations) {
    final r = allRows[expectation.occurrenceId];
    if (r == null ||
        !rowMatches(r) ||
        expectation.status != FinancialExpectationStatus.active ||
        (filter.accountId != null &&
            expectation.accountId != filter.accountId) ||
        (filter.currency != null && expectation.currency != filter.currency)) {
      continue;
    }
    final direction =
        expectation.direction == FinancialExpectationDirection.incoming
        ? AccountEntryType.income
        : AccountEntryType.expense;
    if (filter.entryType != null && direction != filter.entryType) continue;
    final allocated =
        allocatedByOccurrence[expectation
            .occurrenceId]?['${expectation.currency}:${direction.name}'] ??
        0;
    final item = ReportSettlement(r, expectation, allocated);
    if (filter.settlementState != null &&
        filter.settlementState != item.state) {
      continue;
    }
    if (kind == PersonalReportKind.attention &&
        (item.remaining == 0 ||
            r.commitment.status != CommitmentStatus.active ||
            !pastDue(r.occurrence.currentScheduledAt))) {
      continue;
    }
    if (kind == PersonalReportKind.upcoming &&
        (r.commitment.status != CommitmentStatus.active ||
            r.cycle.status != CommitmentCycleStatus.active ||
            pastDue(r.occurrence.currentScheduledAt))) {
      continue;
    }
    settlements.add(item);
  }
  final packages = <ReportPackage>[];
  for (final plan in data.entitlements) {
    final cycle = cycles[plan.cycleId];
    final owner = owners[cycle?.commitmentId];
    if (cycle == null ||
        owner == null ||
        !ownerMatches(owner, cycle.id) ||
        reportDate(plan.validFrom).isAfter(filter.to)) {
      continue;
    }
    final ledger = data.ledger
        .where(
          (e) =>
              e.planId == plan.id &&
              reportDate(e.occurredAt).isBefore(filter.endExclusive),
        )
        .toList();
    packages.add(
      ReportPackage(
        owner,
        cycle,
        plan,
        ledger,
        ledger.where((e) => filter.dateMatches(e.occurredAt)).toList(),
      ),
    );
  }
  final accounts = <ReportAccount>[];
  for (final account in data.accounts) {
    if ((filter.accountId != null && filter.accountId != account.id) ||
        (filter.currency != null && filter.currency != account.currency)) {
      continue;
    }
    var opening = 0, movement = 0;
    for (final e in data.entries.where((e) => e.accountId == account.id)) {
      final date = reportDate(e.occurredAt);
      if (date.isBefore(filter.from)) {
        opening += e.signedAmount.minorUnits;
      } else if (date.isBefore(filter.endExclusive)) {
        movement += e.signedAmount.minorUnits;
      }
    }
    accounts.add(ReportAccount(account, opening, movement, opening + movement));
  }
  final previews = data.previews.where((p) {
    final owner = owners[p.commitmentId];
    return owner != null &&
        owner.status == CommitmentStatus.active &&
        cycles[p.slot.cycleId]?.status == CommitmentCycleStatus.active &&
        ownerMatches(owner, p.slot.cycleId) &&
        filter.occurrenceStatus == null &&
        filter.dateMatches(p.slot.date) &&
        !reportDate(p.slot.date).isBefore(today);
  }).toList();
  return PersonalReport(
    occurrences: rows,
    movements: movements,
    settlements: settlements,
    packages: packages,
    accounts: accounts,
    previews: previews,
    unreviewed: unreviewed,
    cashTotals: cashTotals,
  );
}
