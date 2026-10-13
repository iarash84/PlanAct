import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';
import 'package:planact/features/reports/application/reports_reader.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';

class DriftReportsReader implements ReportsReader, CommandGateProvider {
  DriftReportsReader(this.database);
  final db.AppDatabase database;
  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);

  @override
  Future<ReportSnapshot> read(
    ReportFilter filter, {
    required DateTime now,
    bool includePreviews = false,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      if (filter.dayCount > 366) {
        throw ArgumentError('Report range exceeds 366 days');
      }
      final commitments = await DriftCommitmentRepository(database).list();
      final finance = DriftFinanceRepository(database);
      final expectations = DriftFinancialExpectationRepository(database);
      final cycleRows = await database.select(database.commitmentCycles).get();
      final occurrenceRows = await database.select(database.occurrences).get();
      final planRows = await database.select(database.entitlementPlans).get();
      final ledgerRows = await database
          .select(database.entitlementLedgerEntries)
          .get();
      final reviewRows = await database
          .select(database.relationshipReviews)
          .get();
      final commitmentLinks = await database
          .select(database.commitmentTags)
          .get();
      final entryLinks = await database.select(database.accountEntryTags).get();
      final commitmentTags = <StableId, Set<StableId>>{};
      for (final link in commitmentLinks) {
        (commitmentTags[StableId.parse(link.commitmentId)] ??= {}).add(
          StableId.parse(link.tagId),
        );
      }
      final entryTags = <StableId, Set<StableId>>{};
      for (final link in entryLinks) {
        (entryTags[StableId.parse(link.accountEntryId)] ??= {}).add(
          StableId.parse(link.tagId),
        );
      }
      final previews = <ReportPreview>[];
      final today = LocalDate.fromDateTime(now.toLocal());
      var start = LocalDate.fromDateTime(filter.from);
      final end = LocalDate.fromDateTime(filter.endExclusive);
      if (start.compareTo(today) < 0) start = today;
      final plans = DriftCommitmentPlanRepository(database);
      while (includePreviews && start.compareTo(end) < 0) {
        final chunkEnd = start.addDays(31).compareTo(end) > 0
            ? end
            : start.addDays(31);
        final range = await plans.loadPlannedRange(start, chunkEnd, today);
        for (final entry in range.preview.entries) {
          previews.addAll(
            entry.value.map(
              (slot) => ReportPreview(StableId.parse(entry.key), slot),
            ),
          );
        }
        start = chunkEnd;
      }
      return ReportSnapshot(
        commitments: commitments,
        cycles: cycleRows
            .map(
              (r) => CommitmentCycle(
                id: StableId.parse(r.id),
                commitmentId: StableId.parse(r.commitmentId),
                cycleType: CommitmentCycleType.values[r.cycleType],
                startDate: r.startDate,
                plannedEndDate: r.plannedEndDate,
                actualEndDate: r.actualEndDate,
                targetUnits: r.targetUnits,
                consumedUnits: r.consumedUnits,
                completionRule: CompletionRule.values[r.completionRule],
                status: CommitmentCycleStatus.values[r.status],
              ),
            )
            .toList(),
        occurrences: occurrenceRows
            .map(
              (r) => Occurrence(
                id: StableId.parse(r.id),
                cycleId: StableId.parse(r.cycleId),
                scheduleDefinitionId: StableId.parse(r.scheduleDefinitionId),
                occurrenceKey: r.occurrenceKey,
                originalScheduledAt: _value(r.originalScheduledValue),
                currentScheduledAt: _value(r.currentScheduledValue),
                status: OccurrenceStatus.values[r.status],
                isManualOverride: r.isManualOverride,
              ),
            )
            .toList(),
        actuals: await DriftActualRepository(database).list(),
        accounts: await finance.listAccounts(),
        entries: await finance.listEntries(),
        expectations: await expectations.listExpectations(),
        matches: await expectations.listMatches(),
        reviews: reviewRows
            .map(
              (r) => RelationshipReviewEntry(
                id: StableId.parse(r.id),
                transactionId: StableId.parse(r.transactionId),
                revision: r.revision,
                decision: RelationshipReviewDecision.values[r.decision],
                transactionAmount: Money(
                  minorUnits: r.minorUnits,
                  currency: r.currency,
                ),
                allocationFingerprint: r.allocationFingerprint,
                allocationHistoryFingerprint: r.allocationHistoryFingerprint,
                remainderMinorUnits: r.remainderMinorUnits,
                recordedAt: r.recordedAt,
              ),
            )
            .toList(),
        entitlements: planRows
            .map(
              (r) => EntitlementPlan(
                id: StableId.parse(r.id),
                cycleId: StableId.parse(r.cycleId),
                totalUnits: r.totalUnits,
                unitType: EntitlementUnitType.values[r.unitType],
                validFrom: r.validFrom,
                plannedExpiry: r.plannedExpiry,
                autoExtend: r.autoExtend,
              ),
            )
            .toList(),
        ledger: ledgerRows
            .map(
              (r) => EntitlementLedgerEntry(
                id: StableId.parse(r.id),
                planId: StableId.parse(r.planId),
                type: EntitlementEntryType.values[r.type],
                units: r.units,
                occurredAt: r.occurredAt,
                referenceId: r.referenceId == null
                    ? null
                    : StableId.parse(r.referenceId!),
                note: r.note,
              ),
            )
            .toList(),
        tags: await DriftTagRepository(database).list(),
        commitmentTags: commitmentTags,
        entryTags: entryTags,
        previews: previews,
      );
    }),
  );

  static Object _value(String value) {
    if (value.startsWith('date:')) {
      final p = value.substring(5).split('-').map(int.parse).toList();
      return LocalDate(p[0], p[1], p[2]);
    }
    if (value.startsWith('instant:')) {
      return DateTime.parse(value.substring(8)).toUtc();
    }
    if (value.startsWith('local:')) {
      final p = value.substring(6).split('T');
      final d = p[0].split('-').map(int.parse).toList();
      final t = p[1].split(':');
      final s = t[2].split('.');
      return DateTime(
        d[0],
        d[1],
        d[2],
        int.parse(t[0]),
        int.parse(t[1]),
        int.parse(s[0]),
        int.parse(s[1]),
      );
    }
    throw const FormatException('Unknown schedule date semantics');
  }
}
