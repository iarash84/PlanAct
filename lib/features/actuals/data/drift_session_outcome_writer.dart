import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/database/undo_journal.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/sessions/application/session_outcome_accounting.dart';
import 'package:planact/features/sessions/data/drift_session_repositories.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';
import 'package:planact/features/sessions/domain/session_outcome_accounting.dart';
import 'package:planact/features/sessions/domain/session_policy.dart';

/// Not installed on the public actual path. Durable policy approval needs a
/// separately approved implementation; stored default policies are insufficient.
class DriftSessionOutcomeWriter
    implements CommandGateProvider, SessionOutcomeWriter {
  DriftSessionOutcomeWriter(this.database, {required this.approvals});

  final db.AppDatabase database;
  final SessionPolicyApprovalReader approvals;

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);

  @override
  Future<Occurrence> recordSessionOutcome({
    required Occurrence expected,
    required SessionOutcome outcome,
    required DateTime recordedAt,
    String? note,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final journal = UndoJournal(database);
      await journal.admitWriter();
      final occurrence = await (database.select(
        database.occurrences,
      )..where((t) => t.id.equals(expected.id.value))).getSingleOrNull();
      if (occurrence == null || occurrence.cycleId != expected.cycleId.value) {
        throw const ValidationError('Occurrence changed; reload first');
      }
      final cycle = await (database.select(
        database.commitmentCycles,
      )..where((t) => t.id.equals(occurrence.cycleId))).getSingle();
      final owner = await (database.select(
        database.commitments,
      )..where((t) => t.id.equals(cycle.commitmentId))).getSingle();
      if (cycle.status != CommitmentCycleStatus.active.index ||
          owner.status != CommitmentStatus.active.index) {
        throw const ValidationError('Session owner must be active');
      }
      final policy = await DriftSessionPolicyRepository(database)
          .findByCycle(expected.cycleId);
      if (policy == null ||
          !await approvals.isExplicitlyApproved(
            cycleId: expected.cycleId,
            policy: policy,
          )) {
        throw const ValidationError(
          'Explicit durable session policy approval required',
        );
      }
      const accounting = SessionOutcomeAccounting();
      final resolution = accounting.resolve(policy, outcome);
      final plans = await DriftEntitlementPlanRepository(database)
          .listByCycle(expected.cycleId);
      if (plans.length != 1) {
        throw const ValidationError('Exactly one entitlement plan is required');
      }
      final plan = plans.single;
      if (plan.unitType != EntitlementUnitType.session ||
          plan.autoExtend ||
          plan.plannedExpiry != null ||
          recordedAt.toUtc().isBefore(plan.validFrom)) {
        throw const ValidationError('Unsupported entitlement validity or unit');
      }
      final ledger = DriftEntitlementLedgerRepository(database);
      final entries = await ledger.listByPlan(plan.id);
      if (!entries.any((e) => e.type == EntitlementEntryType.grant)) {
        throw const ValidationError(
          'Missing Grant history; no automatic backfill',
        );
      }
      final history = await (database.select(
        database.actuals,
      )..where((t) => t.occurrenceId.equals(expected.id.value))).get();
      final replacements = await (database.select(
        database.replacementOccurrences,
      )..where((t) => t.originalOccurrenceId.equals(expected.id.value))).get();
      if (history.isNotEmpty ||
          replacements.isNotEmpty ||
          entries.any((e) => e.referenceId == expected.id)) {
        throw const ValidationError(
          'Session correction and makeup are not enabled',
        );
      }
      if (resolution.consumesEntitlement &&
          const EntitlementLedger().remaining(entries) < 1) {
        throw const ValidationError('Insufficient granted session credit');
      }
      final updated = await DriftActualRepository(database)
          .recordOccurrenceActual(
            expected: expected,
            outcome: accounting.actualOutcome(outcome),
            recordedAt: recordedAt,
            note: note,
          );
      EntitlementLedgerEntry? consume;
      if (resolution.consumesEntitlement) {
        consume = EntitlementLedgerEntry.create(
          planId: plan.id,
          type: EntitlementEntryType.consume,
          units: 1,
          occurredAt: recordedAt,
          referenceId: expected.id,
        );
        await ledger.append(consume);
      }
      await journal.append(
        owner: 'session_outcome:${expected.id.value}',
        before: {'resultRevision': expected.resultRevision},
        after: {
          'version': 1,
          'planId': plan.id.value,
          'sessionOutcome': outcome.name,
          'consumeId': consume?.id.value,
          'resultRevision': updated.resultRevision,
          'policy': {
            'providerCancellationConsumes': policy.providerCancellationConsumes,
            'userCancellationNoticeHours': policy.userCancellationNoticeHours,
            'lateCancellationConsumes': policy.lateCancellationConsumes,
            'noShowConsumes': policy.noShowConsumes,
            'freeAbsenceQuota': policy.freeAbsenceQuota,
            'holidayConsumes': policy.holidayConsumes,
            'makeupRequired': policy.makeupRequired,
            'autoExtendUntilUnitsConsumed': policy.autoExtendUntilUnitsConsumed,
            'maxExtensionDate': policy.maxExtensionDate?.toIso8601String(),
            'partialUnitAllowed': policy.partialUnitAllowed,
          },
        },
      );
      return updated;
    }),
  );
}
