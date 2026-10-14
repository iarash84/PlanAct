import 'package:planact/core/localization/persian_copy.g.dart';

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_correction.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/sessions/data/drift_session_repositories.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';

class DriftCommitmentCorrectionRepository
    implements CommitmentCorrectionRepository, CommandGateProvider {
  DriftCommitmentCorrectionRepository(this.database);
  final db.AppDatabase database;
  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);

  @override
  Future<CommitmentCorrectionPreview> preview(
    CommitmentCorrectionRequest request,
    DateTime now,
  ) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      await _lock();
      return (await _prepare(request, now)).preview;
    }),
  );

  @override
  Future<List<CommitmentCorrectionRecord>> history(StableId commitmentId) =>
      CommandGate.runFor(this, () async {
        final rows = await (database.select(
          database.schemaMetadata,
        )..where((t) => t.key.like('commitment_correction_v1:%'))).get();
        final records = <CommitmentCorrectionRecord>[];
        for (final row in rows) {
          final value = jsonDecode(row.value) as Map<String, dynamic>;
          if (value['commitmentId'] != commitmentId.value) continue;
          records.add(
            CommitmentCorrectionRecord(
              reason: value['reason'] as String,
              at: DateTime.parse(value['at'] as String),
              beforeCount: value['beforeCount'] as int?,
              afterCount: value['afterCount'] as int?,
              beforeRemaining: value['beforeRemaining'] as int?,
              afterRemaining: value['afterRemaining'] as int?,
            ),
          );
        }
        records.sort((a, b) => b.at.compareTo(a.at));
        return records;
      });

  Future<void> _lock() => database.customStatement(
    'UPDATE schema_metadata SET value = value WHERE key = ?',
    ['schema_version'],
  );

  @override
  Future<void> confirm(
    CommitmentCorrectionPreview expected,
    DateTime now,
  ) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      await _lock();
      final prepared = await _prepare(expected.request, now);
      if (prepared.preview.fingerprint != expected.fingerprint) {
        throw const ValidationError(
          PersianCopy.driftCommitmentCorrectionRepositoryConfirmMessage,
        );
      }
      final auditId = StableId.generate();
      if (expected.request.scheduleCount != null) {
        final repository = DriftCommitmentPlanRepository(database);
        await repository.save(
          CommitmentPlan(
            commitment: prepared.plan.commitment,
            cycle: prepared.plan.cycle,
            schedule: prepared.schedule!,
            occurrences: const [],
            reminders: const [],
          ),
        );
        for (final occurrence in prepared.cancelled) {
          await repository.saveOccurrence(
            occurrence.withStatus(OccurrenceStatus.cancelled),
          );
          await (database.update(database.reminderInstances)..where(
                (t) =>
                    t.occurrenceId.equals(occurrence.id.value) &
                    (t.status.equals(ReminderInstanceStatus.scheduled.index) |
                        t.status.equals(ReminderInstanceStatus.snoozed.index)),
              ))
              .write(
                db.ReminderInstancesCompanion(
                  status: Value(ReminderInstanceStatus.cancelled.index),
                ),
              );
        }
        // Generate reminder/financial intent with additions in this same
        // transaction, using the new version's persisted generation templates.
        await repository.extendRecurringSchedules(
          LocalDate.fromDateTime(now),
          cycleId: prepared.plan.cycle.id,
          scheduleId: prepared.schedule!.id,
        );
      }
      if (expected.request.creditDelta case final delta?) {
        await DriftEntitlementLedgerRepository(database).append(
          EntitlementLedgerEntry.create(
            planId: prepared.entitlement!.id,
            type: EntitlementEntryType.adjustment,
            units: delta,
            occurredAt: now,
            referenceId: auditId,
            note: expected.request.reason.trim(),
          ),
        );
      }
      // Versioned append-only logical audit rides the existing personal
      // backup metadata table, without a parallel mutable counter.
      await database
          .into(database.schemaMetadata)
          .insert(
            db.SchemaMetadataCompanion.insert(
              key: 'commitment_correction_v1:${auditId.value}',
              value: jsonEncode({
                'commitmentId': expected.request.commitmentId.value,
                'cycleId': prepared.plan.cycle.id.value,
                'at': now.toUtc().toIso8601String(),
                'reason': expected.request.reason.trim(),
                'scope': expected.request.scheduleCount != null
                    ? 'future-count-preserve-anchor'
                    : 'independent-credit-adjustment',
                'beforeCount': expected.beforeCount,
                'afterCount': expected.afterCount,
                'beforeRemaining': expected.remainingBefore,
                'afterRemaining': expected.remainingAfter,
                'scheduleId': prepared.schedule?.id.value,
                'cancelledIds': prepared.cancelled
                    .map((o) => o.id.value)
                    .toList(),
              }),
            ),
          );
    }),
  );

  Future<_PreparedCorrection> _prepare(
    CommitmentCorrectionRequest request,
    DateTime now,
  ) async {
    if (request.reason.trim().isEmpty ||
        (request.scheduleCount == null) == (request.creditDelta == null)) {
      throw const ValidationError(
        PersianCopy.driftCommitmentCorrectionRepositoryPrepareMessage,
      );
    }
    final plan = await DriftCommitmentPlanRepository(database)
        .findByCommitmentId(request.commitmentId);
    if (plan == null ||
        plan.commitment.status != CommitmentStatus.active ||
        plan.cycle.status != CommitmentCycleStatus.active) {
      throw const ValidationError(
        PersianCopy.driftCommitmentCorrectionRepositoryPrepareMessage2,
      );
    }
    final today = LocalDate.fromDateTime(now);
    final effective = today.addDays(1);
    final entitlementPlans = await DriftEntitlementPlanRepository(database)
        .listByCycle(plan.cycle.id);
    final entitlement = entitlementPlans.length == 1
        ? entitlementPlans.single
        : null;
    final entries = entitlement == null
        ? <EntitlementLedgerEntry>[]
        : await DriftEntitlementLedgerRepository(database)
              .listByPlan(entitlement.id);
    final remaining = entitlement == null
        ? null
        : const EntitlementLedger().remaining(entries);
    if (request.creditDelta case final delta?) {
      if (entitlement == null || delta == 0 || remaining! + delta < 0) {
        throw const ValidationError(
          PersianCopy.driftCommitmentCorrectionRepositoryPrepareMessage3,
        );
      }
    }
    final protectedIds = <String>{};
    for (final table in ['actuals', 'match_allocations']) {
      final rows = await database
          .customSelect('SELECT occurrence_id FROM $table')
          .get();
      protectedIds.addAll(rows.map((r) => r.read<String>('occurrence_id')));
    }
    protectedIds.addAll(
      entries
          .where((e) => e.referenceId != null)
          .map((e) => e.referenceId!.value),
    );
    var hasHistory =
        entries.any((e) => e.type != EntitlementEntryType.grant) ||
        plan.occurrences.any(
          (o) =>
              _date(o.originalScheduledAt).compareTo(today) <= 0 ||
              o.isManualOverride ||
              o.status != OccurrenceStatus.scheduled ||
              protectedIds.contains(o.id.value),
        );
    final cancelled = <Occurrence>[];
    final added = <Occurrence>[];
    ScheduleDefinition? next;
    if (request.scheduleCount case final count?) {
      final old = plan.schedule;
      if (old.mode != ScheduleMode.fixedCount ||
          count < 1 ||
          count > 1000 ||
          count == old.occurrenceCount ||
          effective.compareTo(old.effectiveFrom) <= 0) {
        throw const ValidationError(
          PersianCopy.driftCommitmentCorrectionRepositoryPrepareMessage4,
        );
      }
      next = ScheduleDefinition(
        id: StableId.generate(),
        cycleId: old.cycleId,
        mode: old.mode,
        timeSemantics: old.timeSemantics,
        startDate: old.startDate,
        localTime: old.localTime,
        timeZoneId: old.timeZoneId,
        recurrenceRule: old.recurrenceRule,
        occurrenceCount: count,
        version: old.version + 1,
        effectiveFrom: effective,
        generationHorizonDays: old.generationHorizonDays,
        generationReminderOffsets: old.generationReminderOffsets,
        generationFinancialExpectation: old.generationFinancialExpectation,
      );
      // Full logical prefix is independently bounded. Reject schedules whose
      // complete prefix cannot be represented within this correction horizon.
      final prefixSchedule = ScheduleDefinition(
        id: next.id,
        cycleId: old.cycleId,
        mode: old.mode,
        timeSemantics: old.timeSemantics,
        startDate: old.startDate,
        localTime: old.localTime,
        timeZoneId: old.timeZoneId,
        recurrenceRule: old.recurrenceRule,
        occurrenceCount: count,
        version: next.version,
        effectiveFrom: old.startDate,
        generationHorizonDays: 366000,
      );
      final prefix = const OccurrenceGenerator().generate(
        schedule: prefixSchedule,
        through: old.startDate.addDays(366000),
      );
      if (prefix.length != count) {
        throw const ValidationError(
          PersianCopy.driftCommitmentCorrectionRepositoryPrepareMessage5,
        );
      }
      final wanted = prefix.map((o) => _date(o.originalScheduledAt)).toSet();
      final occupied = plan.occurrences
          .map((o) => _date(o.originalScheduledAt))
          .toSet();
      for (final o in plan.occurrences) {
        final date = _date(o.originalScheduledAt);
        final protected =
            date.compareTo(today) <= 0 ||
            o.isManualOverride ||
            o.status != OccurrenceStatus.scheduled ||
            protectedIds.contains(o.id.value);
        if (protected) hasHistory = true;
        if (!wanted.contains(date) && o.status != OccurrenceStatus.cancelled) {
          if (protected) {
            throw const ValidationError(
              PersianCopy.driftCommitmentCorrectionRepositoryPrepareMessage6,
            );
          }
          cancelled.add(o);
        }
        if (wanted.contains(date) &&
            o.status == OccurrenceStatus.cancelled &&
            date.compareTo(today) > 0 &&
            count > old.occurrenceCount!) {
          throw const ValidationError(
            PersianCopy.driftCommitmentCorrectionRepositoryPrepareMessage7,
          );
        }
      }
      final generated = const OccurrenceGenerator().generate(
        schedule: next,
        through: today.addDays(old.generationHorizonDays),
        windowStart: today,
      );
      added.addAll(
        generated.where(
          (o) => !occupied.contains(_date(o.originalScheduledAt)),
        ),
      );
    }
    // Fingerprint all affected durable rows, including reminder/payment history.
    final state = <String, Object?>{};
    for (final table in [
      'commitments',
      'commitment_cycles',
      'schedule_definitions',
      'occurrences',
      'entitlement_plans',
      'entitlement_ledger_entries',
      'actuals',
      'match_allocations',
      'financial_expectations',
      'reminder_rules',
      'reminder_instances',
      'schema_metadata',
    ]) {
      state[table] =
          (await database.customSelect('SELECT * FROM $table ORDER BY 1').get())
              .map((r) => r.data)
              .toList();
    }
    return _PreparedCorrection(
      plan: plan,
      entitlement: entitlement,
      schedule: next,
      added: added,
      cancelled: cancelled,
      preview: CommitmentCorrectionPreview(
        request: request,
        fingerprint: jsonEncode({
          'date': '${today.year}-${today.month}-${today.day}',
          'state': state,
        }),
        beforeCount: plan.schedule.occurrenceCount,
        afterCount: request.scheduleCount ?? plan.schedule.occurrenceCount,
        futureAdded: added.length,
        futureCancelled: cancelled.length,
        remainingBefore: remaining,
        remainingAfter: remaining == null
            ? null
            : remaining + (request.creditDelta ?? 0),
        hasHistory: hasHistory,
      ),
    );
  }

  static LocalDate _date(Object value) =>
      value is LocalDate ? value : LocalDate.fromDateTime(value as DateTime);
}

class _PreparedCorrection {
  const _PreparedCorrection({
    required this.plan,
    required this.entitlement,
    required this.schedule,
    required this.added,
    required this.cancelled,
    required this.preview,
  });
  final CommitmentPlan plan;
  final EntitlementPlan? entitlement;
  final ScheduleDefinition? schedule;
  final List<Occurrence> added;
  final List<Occurrence> cancelled;
  final CommitmentCorrectionPreview preview;
}
