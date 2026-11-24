import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/data/drift_session_outcome_writer.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/sessions/application/session_outcome_accounting.dart';
import 'package:planact/features/sessions/data/drift_session_repositories.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';
import 'package:planact/features/sessions/domain/session_policy.dart';

// Test-only durable approval protocol. This is intentionally not a production
// approval format or authoring command.
String _policySnapshot(SessionPolicy p) => jsonEncode([
  p.providerCancellationConsumes,
  p.userCancellationNoticeHours,
  p.lateCancellationConsumes,
  p.noShowConsumes,
  p.freeAbsenceQuota,
  p.holidayConsumes,
  p.makeupRequired,
  p.autoExtendUntilUnitsConsumed,
  p.maxExtensionDate?.toIso8601String(),
  p.partialUnitAllowed,
]);

class _Approvals implements SessionPolicyApprovalReader {
  _Approvals(this.database);
  final AppDatabase database;

  @override
  Future<bool> isExplicitlyApproved({
    required StableId cycleId,
    required SessionPolicy policy,
  }) async =>
      (await database
              .customSelect(
                "SELECT value FROM schema_metadata WHERE key = 'test_session_approval:${cycleId.value}'",
                variables: [],
              )
              .get())
          .firstOrNull
          ?.read<String>('value') ==
      _policySnapshot(policy);
}

class _Fixture {
  _Fixture(this.database, this.occurrence, this.plan);
  final AppDatabase database;
  final Occurrence occurrence;
  final EntitlementPlan plan;

  static Future<_Fixture> create(
    AppDatabase database, {
    bool grant = true,
    bool approved = true,
    SessionPolicy policy = const SessionPolicy(makeupRequired: false),
  }) async {
    final created = await CreateCommitmentPlan(
      commitments: DriftCommitmentRepository(database),
      plans: DriftCommitmentPlanRepository(database),
    )(title: 'کلاس', startAt: DateTime(2027, 1, 2, 18));
    final occurrence = created.occurrences.single;
    final plan = EntitlementPlan.create(
      cycleId: occurrence.cycleId,
      totalUnits: 4,
      unitType: EntitlementUnitType.session,
      validFrom: DateTime.utc(2026),
    );
    await DriftEntitlementPlanRepository(database).save(plan);
    await DriftSessionPolicyRepository(database)
        .save(occurrence.cycleId, policy);
    if (grant) {
      await DriftEntitlementLedgerRepository(database).append(
        EntitlementLedgerEntry.create(
          planId: plan.id,
          type: EntitlementEntryType.grant,
          units: 4,
          occurredAt: DateTime.utc(2026),
        ),
      );
    }
    if (approved) {
      await database.writeMetadata(
        'test_session_approval:${occurrence.cycleId.value}',
        _policySnapshot(policy),
      );
    }
    return _Fixture(database, occurrence, plan);
  }

  DriftSessionOutcomeWriter get writer =>
      DriftSessionOutcomeWriter(database, approvals: _Approvals(database));

  Future<Occurrence> record([
    SessionOutcome outcome = SessionOutcome.completed,
  ]) => writer.recordSessionOutcome(
    expected: occurrence,
    outcome: outcome,
    recordedAt: DateTime.utc(2027, 1, 2, 18),
  );

  Future<List<EntitlementLedgerEntry>> get entries =>
      DriftEntitlementLedgerRepository(database).listByPlan(plan.id);
}

void main() {
  test(
    'final session journal failure rolls back outcome and consumption',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await _Fixture.create(database);
      await database.customStatement(
        "CREATE TRIGGER reject_session_journal BEFORE INSERT ON schema_metadata WHEN NEW.value LIKE '%sessionOutcome%' BEGIN SELECT RAISE(ABORT, 'injected journal failure'); END",
      );
      await expectLater(fixture.record(), throwsA(anything));
      expect(await DriftActualRepository(database).list(), isEmpty);
      expect((await fixture.entries).length, 1);
      final owner = (await DriftCommitmentRepository(database).list()).single;
      final plan = await DriftCommitmentPlanRepository(database)
          .findByCommitmentId(owner.id);
      expect(plan!.occurrences.single.status, OccurrenceStatus.scheduled);
      expect(
        await database
            .customSelect(
              "SELECT * FROM schema_metadata WHERE key LIKE 'undo_%'",
            )
            .get(),
        isEmpty,
      );
    },
  );

  test(
    'duplicate consuming and non-consuming outcomes cannot append twice',
    () async {
      for (final outcome in [
        SessionOutcome.completed,
        SessionOutcome.providerCancelled,
      ]) {
        final database = AppDatabase.forTesting(NativeDatabase.memory());
        try {
          final fixture = await _Fixture.create(database);
          await fixture.record(outcome);
          await expectLater(
            fixture.record(outcome),
            throwsA(isA<ValidationError>()),
          );
          expect(await DriftActualRepository(database).list(), hasLength(1));
          expect(
            (await fixture.entries).length,
            outcome == SessionOutcome.completed ? 2 : 1,
          );
        } finally {
          await database.close();
        }
      }
    },
  );

  test(
    'explicit provider, no-show and holiday policies control consumption',
    () async {
      for (final outcome in [
        SessionOutcome.providerCancelled,
        SessionOutcome.noShow,
        SessionOutcome.holiday,
      ]) {
        for (final consumes in [false, true]) {
          final database = AppDatabase.forTesting(NativeDatabase.memory());
          try {
            final fixture = await _Fixture.create(
              database,
              policy: SessionPolicy(
                makeupRequired: false,
                providerCancellationConsumes: consumes,
                noShowConsumes: consumes,
                holidayConsumes: consumes,
              ),
            );
            final result = await fixture.record(outcome);
            final entries = await fixture.entries;
            expect(
              result.status,
              outcome == SessionOutcome.noShow
                  ? OccurrenceStatus.skipped
                  : OccurrenceStatus.cancelled,
            );
            expect(
              entries.where((e) => e.type == EntitlementEntryType.consume),
              hasLength(consumes ? 1 : 0),
            );
            expect(
              const EntitlementLedger().remaining(entries),
              consumes ? 3 : 4,
            );
            expect(
              await database.select(database.accountEntries).get(),
              isEmpty,
            );
          } finally {
            await database.close();
          }
        }
      }
    },
  );

  test(
    'fresh policy changes invalidate approval; exhausted credit rejects',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await _Fixture.create(database);
      await DriftSessionPolicyRepository(database).save(
        fixture.occurrence.cycleId,
        const SessionPolicy(makeupRequired: false, noShowConsumes: false),
      );
      await expectLater(fixture.record(), throwsA(isA<ValidationError>()));
      await DriftSessionPolicyRepository(database).save(
        fixture.occurrence.cycleId,
        const SessionPolicy(makeupRequired: false),
      );
      await DriftEntitlementLedgerRepository(database).append(
        EntitlementLedgerEntry.create(
          planId: fixture.plan.id,
          type: EntitlementEntryType.consume,
          units: 4,
          occurredAt: DateTime.utc(2026, 12),
        ),
      );
      await expectLater(fixture.record(), throwsA(isA<ValidationError>()));
      expect(await DriftActualRepository(database).list(), isEmpty);
      expect((await fixture.entries).length, 2);
    },
  );

  test(
    'unsupported timing, quota and makeup outcomes make no writes',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await _Fixture.create(database);
      for (final outcome in [
        SessionOutcome.userCancelled,
        SessionOutcome.lateCancelled,
        SessionOutcome.absent,
        SessionOutcome.makeup,
      ]) {
        await expectLater(
          fixture.record(outcome),
          throwsA(isA<ValidationError>()),
        );
      }
      expect(await DriftActualRepository(database).list(), isEmpty);
      expect((await fixture.entries).length, 1);
    },
  );
  test(
    'independent SQLite writer contention and retry cannot double consume',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'session-contention-',
      );
      final file = File('${directory.path}/app.sqlite');
      final first = AppDatabase.forTesting(NativeDatabase(file));
      final second = AppDatabase.forTesting(NativeDatabase(file));
      final acquired = Completer<void>();
      final release = Completer<void>();
      Future<void>? held;
      try {
        final fixture = await _Fixture.create(first);
        await second.customSelect('SELECT * FROM schema_metadata').get();
        held = first.transaction(() async {
          await first.customStatement(
            "UPDATE schema_metadata SET value = value WHERE key = 'schema_version'",
          );
          acquired.complete();
          await release.future;
          await fixture.record();
        });
        await acquired.future;
        final contender = DriftSessionOutcomeWriter(
          second,
          approvals: _Approvals(second),
        );
        await expectLater(
          contender.recordSessionOutcome(
            expected: fixture.occurrence,
            outcome: SessionOutcome.completed,
            recordedAt: DateTime.utc(2027, 1, 2, 18),
          ),
          throwsA(anything),
        );
        release.complete();
        await held;
        await expectLater(
          contender.recordSessionOutcome(
            expected: fixture.occurrence,
            outcome: SessionOutcome.completed,
            recordedAt: DateTime.utc(2027, 1, 2, 18),
          ),
          throwsA(isA<ValidationError>()),
        );
        expect(
          (await fixture.entries).where(
            (e) => e.type == EntitlementEntryType.consume,
          ),
          hasLength(1),
        );
        expect(await DriftActualRepository(second).list(), hasLength(1));
      } finally {
        if (!release.isCompleted) release.complete();
        await held;
        await second.close();
        await first.close();
        await directory.delete(recursive: true);
      }
    },
  );
  test(
    'unapproved legacy policy and missing Grant reject without writes',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await _Fixture.create(
        database,
        grant: false,
        approved: false,
      );
      await expectLater(fixture.record(), throwsA(isA<ValidationError>()));
      await database.writeMetadata(
        'test_session_approval:${fixture.occurrence.cycleId.value}',
        _policySnapshot(const SessionPolicy(makeupRequired: false)),
      );
      await expectLater(fixture.record(), throwsA(isA<ValidationError>()));
      expect(await DriftActualRepository(database).list(), isEmpty);
      expect(await fixture.entries, isEmpty);
    },
  );

  test(
    'Consume insertion failure rolls back actual, status and journal',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await _Fixture.create(database);
      await database.customStatement(
        "CREATE TRIGGER reject_consume BEFORE INSERT ON entitlement_ledger_entries WHEN NEW.type = 1 BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await expectLater(fixture.record(), throwsA(anything));
      expect(
        await database
            .customSelect(
              "SELECT * FROM schema_metadata WHERE key LIKE 'undo_%'",
            )
            .get(),
        isEmpty,
      );
      expect(await DriftActualRepository(database).list(), isEmpty);
      expect((await fixture.entries).length, 1);
      final restored = await DriftCommitmentPlanRepository(database)
          .findByCommitmentId(
            (await DriftCommitmentRepository(database).list()).single.id,
          );
      expect(restored!.occurrences.single.status, OccurrenceStatus.scheduled);
    },
  );

  test(
    'completed consumption survives cold reopen; reopening never restores',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'session-accounting-',
      );
      final file = File('${directory.path}/app.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final fixture = await _Fixture.create(database);
        final completed = await fixture.record();
        await DriftActualRepository(database).recordOccurrenceActual(
          expected: completed,
          outcome: ActualOutcome.reopened,
          recordedAt: DateTime.utc(2027, 1, 3),
        );
        await expectLater(
          fixture.writer.recordSessionOutcome(
            expected: Occurrence(
              id: fixture.occurrence.id,
              cycleId: fixture.occurrence.cycleId,
              scheduleDefinitionId: fixture.occurrence.scheduleDefinitionId,
              occurrenceKey: fixture.occurrence.occurrenceKey,
              originalScheduledAt: fixture.occurrence.originalScheduledAt,
              currentScheduledAt: fixture.occurrence.currentScheduledAt,
              status: OccurrenceStatus.scheduled,
              resultRevision: 2,
            ),
            outcome: SessionOutcome.completed,
            recordedAt: DateTime.utc(2027, 1, 3),
          ),
          throwsA(isA<ValidationError>()),
        );
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        final entries = await DriftEntitlementLedgerRepository(database)
            .listByPlan(fixture.plan.id);
        expect(entries.map((e) => e.type), [
          EntitlementEntryType.grant,
          EntitlementEntryType.consume,
        ]);
        expect(const EntitlementLedger().remaining(entries), 3);
        expect((await DriftActualRepository(database).list()).length, 2);
      } finally {
        await database.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'provider cancellation does not consume under explicit no-consume policy',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await _Fixture.create(database);
      final cancelled = await fixture.record(SessionOutcome.providerCancelled);
      expect(cancelled.status, OccurrenceStatus.cancelled);
      expect((await fixture.entries).length, 1);
      final journal = await database
          .customSelect(
            "SELECT value FROM schema_metadata WHERE value LIKE '%providerCancelled%'",
          )
          .get();
      expect(journal, isNotEmpty);
    },
  );

  test(
    'unsupported policy requirements reject rather than losing obligations',
    () async {
      for (final policy in [
        const SessionPolicy(),
        const SessionPolicy(
          makeupRequired: false,
          autoExtendUntilUnitsConsumed: true,
        ),
        const SessionPolicy(makeupRequired: false, partialUnitAllowed: true),
      ]) {
        final database = AppDatabase.forTesting(NativeDatabase.memory());
        try {
          final fixture = await _Fixture.create(database, policy: policy);
          await expectLater(
            fixture.record(SessionOutcome.providerCancelled),
            throwsA(isA<ValidationError>()),
          );
          expect(await DriftActualRepository(database).list(), isEmpty);
        } finally {
          await database.close();
        }
      }
    },
  );

  test(
    'ordinary legacy outcome path does not consume configured package defaults',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await _Fixture.create(database);
      await DriftActualRepository(database).recordOccurrenceActual(
        expected: fixture.occurrence,
        outcome: ActualOutcome.completed,
        recordedAt: DateTime.utc(2027),
      );
      expect((await fixture.entries).length, 1);
    },
  );
}
