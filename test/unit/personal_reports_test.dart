import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';

void main() {
  final account = FinancialAccount(
    id: StableId.generate(),
    name: 'نقدی',
    currency: 'IRR',
    type: FinancialAccountType.cash,
  );
  final owner = Commitment.create(title: 'ورزش', now: DateTime(2020));
  final other = Commitment.create(title: 'آموزش');
  final cycle = CommitmentCycle.create(
    commitmentId: owner.id,
    cycleType: CommitmentCycleType.openEnded,
    startDate: DateTime(2026, 1, 1),
    completionRule: CompletionRule.manual,
  ).activate();
  final otherCycle = CommitmentCycle.create(
    commitmentId: other.id,
    cycleType: CommitmentCycleType.openEnded,
    startDate: DateTime(2026, 1, 1),
    completionRule: CompletionRule.manual,
  ).activate();
  final schedule = StableId.generate();
  final tagA = StableId.generate(), tagB = StableId.generate();
  Occurrence occurrence({
    StableId? cycleId,
    Object? date,
    OccurrenceStatus status = OccurrenceStatus.scheduled,
  }) => Occurrence(
    id: StableId.generate(),
    cycleId: cycleId ?? cycle.id,
    scheduleDefinitionId: schedule,
    occurrenceKey: StableId.generate().value,
    originalScheduledAt: date ?? LocalDate(2026, 10, 2),
    currentScheduledAt: date ?? LocalDate(2026, 10, 2),
    status: status,
  );
  AccountEntry entry(
    AccountEntryType type,
    int amount, {
    DateTime? date,
    String currency = 'IRR',
    String? reference,
  }) => AccountEntry(
    id: StableId.generate(),
    accountId: account.id,
    type: type,
    amount: Money(minorUnits: amount, currency: currency),
    occurredAt: date ?? DateTime(2026, 10, 2),
    referenceId: reference,
  );
  final range = ReportFilter(
    from: DateTime(2026, 10, 1),
    to: DateTime(2026, 10, 31),
  );
  PersonalReport report(
    ReportSnapshot data, {
    ReportFilter? filter,
    PersonalReportKind kind = PersonalReportKind.overview,
  }) => buildPersonalReport(
    data,
    filter ?? range,
    kind: kind,
    now: DateTime(2026, 10, 13),
  );

  test('inclusive local dates include late end day and date-only occurrences, not creation date', () {
    final saved = occurrence(date: LocalDate(2026, 10, 31));
    final data = ReportSnapshot(
      commitments: [owner],
      cycles: [cycle],
      occurrences: [
        saved,
        occurrence(date: LocalDate(2026, 11, 1)),
      ],
      entries: [
        entry(
          AccountEntryType.income,
          10,
          date: DateTime(2026, 10, 31, 23, 59, 59),
        ),
        entry(AccountEntryType.income, 99, date: DateTime(2026, 11, 1)),
      ],
    );
    expect(report(data).occurrences.single.occurrence.id, saved.id);
    expect(report(data).cashTotals['IRR']!.incoming, 10);
    expect(
      () => ReportFilter(from: DateTime(2026, 11), to: DateTime(2026, 10)),
      throwsArgumentError,
    );
  });
  test(
    'stable multi-tag any/all/exclusion/untagged never duplicates a payment',
    () {
      final both = entry(AccountEntryType.expense, 100),
          only = entry(AccountEntryType.expense, 40),
          none = entry(AccountEntryType.expense, 9);
      final data = ReportSnapshot(
        entries: [both, only, none],
        entryTags: {
          both.id: {tagA, tagB},
          only.id: {tagA},
        },
      );
      ReportFilter filter(
        ReportTagMode mode, {
        Set<StableId> excluded = const {},
      }) => ReportFilter(
        from: range.from,
        to: range.to,
        tags: {tagA, tagB},
        tagMode: mode,
        excludedTags: excluded,
      );
      expect(
        report(
          data,
          filter: filter(ReportTagMode.any),
        ).cashTotals['IRR']!.outgoing,
        140,
      );
      expect(
        report(
          data,
          filter: filter(ReportTagMode.all),
        ).cashTotals['IRR']!.outgoing,
        100,
      );
      expect(
        report(
          data,
          filter: filter(ReportTagMode.any, excluded: {tagB}),
        ).cashTotals['IRR']!.outgoing,
        40,
      );
      expect(
        report(
          data,
          filter: filter(ReportTagMode.untagged),
        ).cashTotals['IRR']!.outgoing,
        9,
      );
    },
  );
  test('cash keeps currencies separate, excludes transfers, and books reversal on reversal date', () {
    final payment = entry(AccountEntryType.expense, 100);
    final reversal = entry(
      AccountEntryType.reversal,
      100,
      date: DateTime(2026, 11, 2),
      reference: payment.id.value,
    );
    final data = ReportSnapshot(
      entries: [
        payment,
        reversal,
        entry(AccountEntryType.transferIn, 900),
        entry(AccountEntryType.openingBalance, 500),
        entry(AccountEntryType.income, 30, currency: 'USD'),
      ],
    );
    expect(report(data).cashTotals['IRR']!.outgoing, 100);
    expect(report(data).cashTotals['USD']!.incoming, 30);
    final november = report(
      data,
      filter: ReportFilter(
        from: DateTime(2026, 11, 1),
        to: DateTime(2026, 11, 30),
      ),
    );
    expect(november.cashTotals['IRR']!.outgoing, -100);
    expect(november.cashTotals['IRR']!.net, 100);
  });
  test('partial allocation topic counts only selected commitment share and settlement uses due date', () {
    final o = occurrence(), otherO = occurrence(cycleId: otherCycle.id);
    final payment = entry(
      AccountEntryType.expense,
      100,
      date: DateTime(2026, 9, 20),
    );
    final mid = StableId.generate();
    final match = TransactionMatch(
      id: mid,
      transactionId: payment.id,
      transactionAmount: payment.amount,
      createdAt: DateTime(2026, 10, 3),
      allocations: [
        MatchAllocation(
          id: StableId.generate(),
          matchId: mid,
          occurrenceId: o.id,
          amount: const Money(minorUnits: 40, currency: 'IRR'),
        ),
        MatchAllocation(
          id: StableId.generate(),
          matchId: mid,
          occurrenceId: otherO.id,
          amount: const Money(minorUnits: 60, currency: 'IRR'),
        ),
      ],
    );
    final expected = FinancialExpectation(
      id: StableId.generate(),
      occurrenceId: o.id,
      direction: FinancialExpectationDirection.outgoing,
      amount: 80,
      currency: 'IRR',
      createdAt: DateTime(2020),
      updatedAt: DateTime(2020),
    );
    final data = ReportSnapshot(
      commitments: [owner, other],
      cycles: [cycle, otherCycle],
      occurrences: [o, otherO],
      entries: [payment],
      matches: [match],
      expectations: [expected],
      commitmentTags: {
        owner.id: {tagA, tagB},
      },
    );
    final topic = report(
      data,
      filter: ReportFilter(
        from: DateTime(2026, 9, 1),
        to: range.to,
        tags: {tagA, tagB},
        tagSource: ReportTagSource.relatedAllocation,
      ),
    );
    expect(topic.cashTotals['IRR']!.outgoing, 40);
    final settlement = report(data).settlements.single;
    expect(settlement.allocated, 40);
    expect(settlement.remaining, 40);
    expect(settlement.state, ReportSettlementState.partial);
  });
  test('reviewed independent remainder is not attention; changed allocation invalidates decision', () {
    final payment = entry(AccountEntryType.expense, 100);
    final decision = RelationshipReview.project(
      transactionId: payment.id,
      transactionAmount: payment.amount,
      matches: [],
    ).append(RelationshipReviewDecision.independent, DateTime(2026, 10, 3));
    expect(
      report(
        ReportSnapshot(entries: [payment], reviews: [decision]),
        kind: PersonalReportKind.attention,
      ).unreviewed,
      isEmpty,
    );
    final mid = StableId.generate();
    final match = TransactionMatch(
      id: mid,
      transactionId: payment.id,
      transactionAmount: payment.amount,
      createdAt: DateTime(2026, 10, 4),
      allocations: [
        MatchAllocation(
          id: StableId.generate(),
          matchId: mid,
          occurrenceId: StableId.generate(),
          amount: const Money(minorUnits: 30, currency: 'IRR'),
        ),
      ],
    );
    expect(
      report(
        ReportSnapshot(
          entries: [payment],
          reviews: [decision],
          matches: [match],
        ),
        kind: PersonalReportKind.attention,
      ).unreviewed[payment.id]!.remainderMinorUnits,
      70,
    );
  });
  test('package balance folds historical ledger through end day; range movement remains separate', () {
    final plan = EntitlementPlan.create(
      cycleId: cycle.id,
      totalUnits: 10,
      unitType: EntitlementUnitType.session,
      validFrom: DateTime(2026, 1),
    );
    EntitlementLedgerEntry ledger(
      EntitlementEntryType type,
      int units,
      DateTime date,
    ) => EntitlementLedgerEntry.create(
      planId: plan.id,
      type: type,
      units: units,
      occurredAt: date,
    );
    final data = ReportSnapshot(
      commitments: [owner],
      cycles: [cycle],
      entitlements: [plan],
      ledger: [
        ledger(EntitlementEntryType.grant, 10, DateTime(2026, 9, 1)),
        ledger(EntitlementEntryType.consume, 3, DateTime(2026, 10, 2)),
        ledger(EntitlementEntryType.adjustment, -2, DateTime(2026, 10, 31, 23)),
        ledger(EntitlementEntryType.consume, 4, DateTime(2026, 11, 1)),
      ],
    );
    final p = report(data, kind: PersonalReportKind.packages).packages.single;
    expect(p.balance.granted, 8);
    expect(p.balance.consumed, 3);
    expect(p.balance.remaining, 5);
    expect(p.movements.length, 2);
  });
  test('unknown is distinct from missed; reopen does not double count; archive stays in history', () {
    final done = occurrence(status: OccurrenceStatus.completed),
        unknown = occurrence(),
        skipped = occurrence(status: OccurrenceStatus.skipped);
    final data = ReportSnapshot(
      commitments: [owner.archive()],
      cycles: [cycle],
      occurrences: [done, unknown, skipped],
      actuals: [
        Actual(
          id: StableId.generate(),
          occurrenceId: unknown.id,
          outcome: ActualOutcome.completed,
          recordedAt: DateTime(2026, 10, 3),
        ),
        Actual(
          id: StableId.generate(),
          occurrenceId: unknown.id,
          outcome: ActualOutcome.reopened,
          recordedAt: DateTime(2026, 10, 4),
        ),
      ],
    );
    expect(report(data).occurrences.length, 3);
    expect(report(data).occurrences.where((r) => r.resolved).length, 2);
    expect(
      report(data).occurrences
          .firstWhere((r) => r.occurrence.id == unknown.id)
          .actual!
          .outcome,
      ActualOutcome.reopened,
    );
    expect(
      report(data, kind: PersonalReportKind.attention).occurrences,
      isEmpty,
    );
  });
  test('account opening and closing use full ledger independently of tag movement filter', () {
    final opening = entry(
      AccountEntryType.openingBalance,
      500,
      date: DateTime(2026, 9, 1),
    );
    final payment = entry(AccountEntryType.expense, 100),
        income = entry(AccountEntryType.income, 30);
    final result = report(
      ReportSnapshot(
        accounts: [account],
        entries: [opening, payment, income],
        entryTags: {
          payment.id: {tagA},
        },
      ),
      filter: ReportFilter(from: range.from, to: range.to, tags: {tagA}),
      kind: PersonalReportKind.accounts,
    );
    expect(result.accounts.single.opening, 500);
    expect(result.accounts.single.movement, -70);
    expect(result.accounts.single.closing, 430);
    expect(result.movements.single.entry.id, payment.id);
  });
  test(
    'missing grant is disclosed rather than synthesized from package settings',
    () {
      final plan = EntitlementPlan.create(
        cycleId: cycle.id,
        totalUnits: 10,
        unitType: EntitlementUnitType.session,
        validFrom: DateTime(2026, 1),
      );
      final package = report(
        ReportSnapshot(
          commitments: [owner],
          cycles: [cycle],
          entitlements: [plan],
        ),
        kind: PersonalReportKind.packages,
      ).packages.single;
      expect(package.hasRecordedGrant, isFalse);
      expect(package.plan.totalUnits, 10);
      expect(package.entries, isEmpty);
    },
  );
  test('tagged reversal follows original classification without changing membership', () {
    final payment = entry(AccountEntryType.expense, 100);
    final reversal = entry(
      AccountEntryType.reversal,
      100,
      reference: payment.id.value,
    );
    final memberships = {
      payment.id: {tagA},
    };
    final result = report(
      ReportSnapshot(entries: [payment, reversal], entryTags: memberships),
      filter: ReportFilter(from: range.from, to: range.to, tags: {tagA}),
    );
    expect(result.cashTotals['IRR']!.outgoing, 0);
    expect(result.movements.length, 2);
    expect(memberships.containsKey(reversal.id), isFalse);
  });
  test('changes choose original or current date without counting intermediate events', () {
    final moved = occurrence(date: LocalDate(2026, 9, 20))
        .reschedule(LocalDate(2026, 10, 2));
    final data = ReportSnapshot(
      commitments: [owner],
      cycles: [cycle],
      occurrences: [moved],
    );
    expect(
      report(data, kind: PersonalReportKind.changes).occurrences.length,
      1,
    );
    expect(
      report(
        data,
        kind: PersonalReportKind.changes,
        filter: ReportFilter(
          from: range.from,
          to: range.to,
          originalDate: true,
        ),
      ).occurrences,
      isEmpty,
    );
  });
  test(
    'date range counts civil days, and earlier timed today needs attention',
    () {
      expect(
        ReportFilter(
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 12, 31),
        ).dayCount,
        365,
      );
      final timed = occurrence(date: DateTime(2026, 10, 12, 23));
      final todayAllDay = occurrence(date: LocalDate(2026, 10, 13));
      final data = ReportSnapshot(
        commitments: [owner],
        cycles: [cycle],
        occurrences: [timed, todayAllDay],
      );
      final result = buildPersonalReport(
        data,
        range,
        kind: PersonalReportKind.attention,
        now: DateTime(2026, 10, 13, 8),
      );
      expect(result.occurrences.single.occurrence.id, timed.id);
    },
  );
  test('upcoming previews stay separate, inactive owners excluded and no fake outcomes', () {
    final future = occurrence(date: LocalDate(2026, 10, 20));
    final preview = ReportPreview(
      owner.id,
      PlannedOccurrenceSlot(
        scheduleId: schedule,
        cycleId: cycle.id,
        date: LocalDate(2026, 10, 21),
        scheduledAt: LocalDate(2026, 10, 21),
        scheduleFingerprint: 'preview',
      ),
    );
    final data = ReportSnapshot(
      commitments: [owner],
      cycles: [cycle],
      occurrences: [future],
      previews: [preview],
    );
    expect(
      report(data, kind: PersonalReportKind.upcoming).occurrences.length,
      1,
    );
    expect(report(data, kind: PersonalReportKind.upcoming).previews.length, 1);
    expect(
      report(
        ReportSnapshot(
          commitments: [owner.pause()],
          cycles: [cycle],
          previews: [preview],
        ),
        kind: PersonalReportKind.upcoming,
      ).previews,
      isEmpty,
    );
  });
}
