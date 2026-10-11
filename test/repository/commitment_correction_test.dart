import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/commitments/application/commitment_correction.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_correction_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/sessions/data/drift_session_repositories.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';

void main() {
  for (final consumed in [false, true]) {
    test(
      'independent increases/decreases and durable history consumed=$consumed',
      () async {
        final directory = await Directory.systemTemp.createTemp('correction');
        addTearDown(() => directory.delete(recursive: true));
        final file = File('${directory.path}/state.sqlite');
        var database = AppDatabase.forTesting(NativeDatabase(file));
        final fixture = await seed(database, consumed: consumed);
        final repository = DriftCommitmentCorrectionRepository(database);
        for (final delta in [2, -1]) {
          final preview = await repository.preview(
            CommitmentCorrectionRequest(
              commitmentId: fixture.commitment.id,
              reason: 'credit correction',
              creditDelta: delta,
            ),
            now,
          );
          expect(preview.afterCount, 4);
          await repository.confirm(preview, now);
        }
        final preview = await repository.preview(
          CommitmentCorrectionRequest(
            commitmentId: fixture.commitment.id,
            reason: 'count correction',
            scheduleCount: 6,
          ),
          now,
        );
        expect(preview.remainingBefore, consumed ? 4 : 5);
        expect(preview.futureAdded, 2);
        await repository.confirm(preview, now);
        final decrease = await repository.preview(
          CommitmentCorrectionRequest(
            commitmentId: fixture.commitment.id,
            reason: 'count decrease',
            scheduleCount: 3,
          ),
          now.add(const Duration(days: 1)),
        );
        await repository.confirm(decrease, now.add(const Duration(days: 1)));
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        addTearDown(database.close);
        final restored = await DriftCommitmentPlanRepository(database)
            .findByCommitmentId(fixture.commitment.id);
        final history = await DriftCommitmentCorrectionRepository(database)
            .history(fixture.commitment.id);
        expect(history.length, 4);
        expect(history.first.reason, 'count decrease');
        expect(history.first.beforeCount, 6);
        expect(history.first.afterCount, 3);
        expect(history.first.beforeRemaining, consumed ? 4 : 5);
        expect(restored!.schedule.occurrenceCount, 3);
        expect(restored.schedule.startDate, fixture.schedule.startDate);
        expect(restored.schedule.version, 3);
        expect(restored.occurrences.length, 6);
        expect(
          restored.occurrences
              .where((o) => o.status == OccurrenceStatus.cancelled)
              .length,
          3,
        );
        final entries = await DriftEntitlementLedgerRepository(database)
            .listByPlan(fixture.entitlement.id);
        expect(const EntitlementLedger().remaining(entries), consumed ? 4 : 5);
        expect(
          const EntitlementLedger().fold(entries).consumed,
          consumed ? 1 : 0,
        );
        expect(
          entries
              .where((e) => e.type == EntitlementEntryType.adjustment)
              .map((e) => e.units),
          [2, -1],
        );
        expect(
          (await database.select(database.schemaMetadata).get())
              .where((r) => r.key.startsWith('commitment_correction_v1:'))
              .length,
          4,
        );
        expect(
          (await DriftEntitlementPlanRepository(database)
                  .findById(fixture.entitlement.id))!
              .totalUnits,
          4,
        );
      },
    );
  }

  test(
    'incompatible credit/count and stale preview reject without mutation',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await seed(database, consumed: true);
      final repository = DriftCommitmentCorrectionRepository(database);
      await expectLater(
        repository.preview(
          CommitmentCorrectionRequest(
            commitmentId: fixture.commitment.id,
            reason: 'too much',
            creditDelta: -4,
          ),
          now,
        ),
        throwsA(isA<ValidationError>()),
      );
      final planRepo = DriftCommitmentPlanRepository(database);
      await planRepo.saveOccurrence(
        fixture.occurrences.last.reschedule(DateTime(2026, 10, 20, 18)),
      );
      await expectLater(
        repository.preview(
          CommitmentCorrectionRequest(
            commitmentId: fixture.commitment.id,
            reason: 'protected',
            scheduleCount: 2,
          ),
          now,
        ),
        throwsA(isA<ValidationError>()),
      );
      final preview = await repository.preview(
        CommitmentCorrectionRequest(
          commitmentId: fixture.commitment.id,
          reason: 'credit',
          creditDelta: 1,
        ),
        now,
      );
      await database.writeMetadata('concurrent', 'change');
      await expectLater(
        repository.confirm(preview, now),
        throwsA(isA<ValidationError>()),
      );
      expect(
        (await DriftEntitlementLedgerRepository(database)
                .listByPlan(fixture.entitlement.id))
            .length,
        2,
      );
    },
  );

  test(
    'audit insert failure atomically rolls back schedule and ledger',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await seed(database, consumed: true);
      final repository = DriftCommitmentCorrectionRepository(database);
      await database.customStatement(
        "CREATE TRIGGER reject_correction BEFORE INSERT ON schema_metadata WHEN NEW.key LIKE 'commitment_correction_v1:%' BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      for (final request in [
        CommitmentCorrectionRequest(
          commitmentId: fixture.commitment.id,
          reason: 'test',
          scheduleCount: 6,
        ),
        CommitmentCorrectionRequest(
          commitmentId: fixture.commitment.id,
          reason: 'test',
          creditDelta: -1,
        ),
      ]) {
        final preview = await repository.preview(request, now);
        await expectLater(repository.confirm(preview, now), throwsA(anything));
      }
      expect(
        (await database.select(database.scheduleDefinitions).get()).length,
        1,
      );
      expect((await database.select(database.occurrences).get()).length, 4);
      expect(
        (await database.select(database.entitlementLedgerEntries).get()).length,
        2,
      );
    },
  );
}

final now = DateTime(2026, 10, 11, 12);
Future<Fixture> seed(AppDatabase database, {required bool consumed}) async {
  final commitment = Commitment.create(
    title: 'class',
    kind: CommitmentKind.recurring,
  );
  await DriftCommitmentRepository(database).save(commitment);
  final cycle = CommitmentCycle.create(
    commitmentId: commitment.id,
    cycleType: CommitmentCycleType.fixedCount,
    startDate: DateTime.utc(2026, 10, 10),
    completionRule: CompletionRule.manual,
  ).activate();
  final schedule = ScheduleDefinition.create(
    cycleId: cycle.id,
    mode: ScheduleMode.fixedCount,
    timeSemantics: TimeSemantics.allDayLocalDate,
    startDate: LocalDate(2026, 10, 10),
    occurrenceCount: 4,
    recurrenceRule: RecurrenceRule(frequency: RecurrenceFrequency.daily),
  );
  final occurrences = const OccurrenceGenerator().generate(
    schedule: schedule,
    through: LocalDate(2026, 11, 1),
  );
  if (consumed) {
    occurrences[0] = occurrences[0].withStatus(OccurrenceStatus.completed);
  }
  await DriftCommitmentPlanRepository(database).save(
    CommitmentPlan(
      commitment: commitment,
      cycle: cycle,
      schedule: schedule,
      occurrences: occurrences,
      reminders: const [],
    ),
  );
  final entitlement = EntitlementPlan.create(
    cycleId: cycle.id,
    totalUnits: 4,
    unitType: EntitlementUnitType.session,
    validFrom: DateTime.utc(2026, 10, 10),
  );
  await DriftEntitlementPlanRepository(database).save(entitlement);
  final ledger = DriftEntitlementLedgerRepository(database);
  await ledger.append(
    EntitlementLedgerEntry.create(
      planId: entitlement.id,
      type: EntitlementEntryType.grant,
      units: 4,
    ),
  );
  if (consumed) {
    await ledger.append(
      EntitlementLedgerEntry.create(
        planId: entitlement.id,
        type: EntitlementEntryType.consume,
        units: 1,
        referenceId: occurrences.first.id,
      ),
    );
  }
  return Fixture(commitment, schedule, occurrences, entitlement);
}

class Fixture {
  Fixture(this.commitment, this.schedule, this.occurrences, this.entitlement);
  final Commitment commitment;
  final ScheduleDefinition schedule;
  final List<Occurrence> occurrences;
  final EntitlementPlan entitlement;
}
