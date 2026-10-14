import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/application/commitment_use_cases.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/finance_reports.dart';
import 'package:planact/features/finance/domain/transfer_fee_policy.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/scheduling/application/edit_commitment_schedule.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  late Directory directory;
  late File file;
  late AppDatabase database;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('undo-repair-');
    file = File('${directory.path}/live.sqlite');
    database = AppDatabase.forTesting(NativeDatabase(file));
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<FinancialAccount> account(String name) async {
    final result = FinancialAccount(
      id: StableId.generate(),
      name: name,
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await FinanceUseCases(DriftFinanceRepository(database))
        .createAccount(result);
    return result;
  }

  Future<CommitmentPlan> plan({bool recurring = false}) =>
      CreateCommitmentPlan(
        commitments: DriftCommitmentRepository(database),
        plans: DriftCommitmentPlanRepository(database),
      )(
        title: 'class',
        startAt: DateTime(2027, 1, 2, 18),
        kind: recurring ? CommitmentKind.recurring : CommitmentKind.oneOff,
        frequency: recurring ? RecurrenceFrequency.weekly : null,
      );

  test('void is signed compensation, cannot repeat, and excludes both records from relationship review', () async {
    final bank = await account('bank');
    final repo = DriftFinanceRepository(database);
    final commands = FinanceUseCases(repo);
    final original = await commands.record(
      account: bank,
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 100, currency: 'IRR'),
      occurredAt: DateTime.utc(2026),
    );
    final reversal = await commands.voidEntry(
      original: original,
      account: bank,
    );
    expect(reversal.type, AccountEntryType.reversal);
    expect((await commands.balance(bank)).minorUnits, 0);
    await expectLater(
      commands.voidEntry(original: original, account: bank),
      throwsA(isA<ValidationError>()),
    );
    expect((await commands.balance(bank)).minorUnits, 0);
    final review = DriftReconciliationRepository(database);
    await expectLater(
      review.loadReview(original),
      throwsA(isA<ValidationError>()),
    );
    await expectLater(
      review.loadReview(reversal),
      throwsA(isA<ValidationError>()),
    );
    final summary = cashFlowSummary(await repo.listEntries(), 'IRR');
    expect(summary.incoming, 0);
    expect(summary.outgoing, 0);
    await database.close();
    database = AppDatabase.forTesting(NativeDatabase(file));
    await expectLater(
      FinanceUseCases(DriftFinanceRepository(database))
          .voidEntry(original: original, account: bank),
      throwsA(isA<ValidationError>()),
    );
  });

  test('income reversal uses negative units and failed correction leaves original untouched', () async {
    final bank = await account('bank');
    final commands = FinanceUseCases(DriftFinanceRepository(database));
    final original = await commands.record(
      account: bank,
      type: AccountEntryType.income,
      amount: const Money(minorUnits: 100, currency: 'IRR'),
      occurredAt: DateTime.utc(2026),
    );
    await database.customStatement(
      "CREATE TRIGGER reject_corrected BEFORE INSERT ON account_entries WHEN NEW.type = 2 BEGIN SELECT RAISE(ABORT, 'injected'); END",
    );
    await expectLater(
      commands.correctEntry(
        original: original,
        account: bank,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 50, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 2),
      ),
      throwsException,
    );
    expect((await commands.repository.listEntries()).length, 1);
    expect((await commands.balance(bank)).minorUnits, 100);
    await database.customStatement('DROP TRIGGER reject_corrected');
    final reversal = await commands.voidEntry(
      original: original,
      account: bank,
    );
    expect(reversal.amount.minorUnits, -100);
    expect((await commands.balance(bank)).minorUnits, 0);
  });

  test('transfer cancellation reverses both legs atomically and never becomes cash income or expense', () async {
    final from = await account('from');
    final to = await account('to');
    final commands = FinanceUseCases(DriftFinanceRepository(database));
    final pair = await commands.transfer(
      from: from,
      to: to,
      amount: const Money(minorUnits: 100, currency: 'IRR'),
      occurredAt: DateTime.utc(2026),
    );
    await commands.voidEntry(original: pair.$1, account: from);
    expect((await commands.balance(from)).minorUnits, 0);
    expect((await commands.balance(to)).minorUnits, 0);
    await expectLater(
      commands.voidEntry(original: pair.$2, account: to),
      throwsA(isA<ValidationError>()),
    );
    expect(
      cashFlowSummary(await commands.repository.listEntries(), 'IRR').net,
      0,
    );
  });

  test('transfer fee cancellation rolls back both legs on a middle failure and cancels the complete group on retry', () async {
    final from = await account('from');
    final to = await account('to');
    final commands = FinanceUseCases(DriftFinanceRepository(database));
    final pair = await commands.transfer(
      from: from,
      to: to,
      amount: const Money(minorUnits: 100, currency: 'IRR'),
      occurredAt: DateTime.utc(2026),
      feePolicy: const FixedTransferFeePolicy({
        TransferMethod.cardToCard: Money(minorUnits: 10, currency: 'IRR'),
      }),
    );
    expect((await commands.balance(from)).minorUnits, -110);
    await database.customStatement(
      "CREATE TRIGGER reject_transfer_reversal BEFORE INSERT ON account_entries WHEN NEW.type = 7 AND NEW.account_id = '${to.id.value}' BEGIN SELECT RAISE(ABORT, 'injected'); END",
    );
    await expectLater(
      commands.voidEntry(original: pair.$1, account: from),
      throwsException,
    );
    expect((await commands.repository.listEntries()).length, 3);
    expect((await commands.balance(from)).minorUnits, -110);
    expect((await commands.balance(to)).minorUnits, 100);
    await database.customStatement('DROP TRIGGER reject_transfer_reversal');
    await commands.voidEntry(original: pair.$1, account: from);
    expect((await commands.balance(from)).minorUnits, 0);
    expect((await commands.balance(to)).minorUnits, 0);
    final summary = cashFlowSummary(
      await commands.repository.listEntries(),
      'IRR',
    );
    expect(summary.incoming, 0);
    expect(summary.outgoing, 0);
  });

  test('schedule audit failure rolls back edits; time passage rejects Undo without modifying history', () async {
    final created = await plan();
    final plans = DriftCommitmentPlanRepository(database);
    await database.customStatement(
      "CREATE TRIGGER reject_schedule_audit BEFORE INSERT ON schema_metadata WHEN NEW.key LIKE 'undo_event_v1:%' BEGIN SELECT RAISE(ABORT, 'injected'); END",
    );
    await expectLater(
      EditCommitmentSchedule(plans)(
        commitmentId: created.commitment.id,
        expected: created.occurrences.single,
        scheduledAt: DateTime(2027, 1, 3, 19),
        scope: SeriesEditScope.onlyThis,
        now: DateTime(2026, 10, 14),
      ),
      throwsException,
    );
    expect(
      (await plans.findByCommitmentId(created.commitment.id))!
          .occurrences
          .single
          .currentScheduledAt,
      DateTime(2027, 1, 2, 18),
    );
    expect(await plans.scheduleUndo(created.commitment.id), isNull);
    await database.customStatement('DROP TRIGGER reject_schedule_audit');
    await EditCommitmentSchedule(plans)(
      commitmentId: created.commitment.id,
      expected: created.occurrences.single,
      scheduledAt: DateTime(2027, 1, 3, 19),
      scope: SeriesEditScope.onlyThis,
      now: DateTime(2026, 10, 14),
    );
    final token = (await plans.scheduleUndo(created.commitment.id))!;
    await expectLater(
      plans.undoSchedule(
        created.commitment.id,
        token,
        DateTime(2027, 1, 2, 19),
      ),
      throwsA(isA<ValidationError>()),
    );
    await expectLater(
      plans.undoSchedule(created.commitment.id, token, DateTime(2027, 2)),
      throwsA(isA<ValidationError>()),
    );
    expect(
      (await plans.findByCommitmentId(created.commitment.id))!
          .occurrences
          .single
          .currentScheduledAt,
      DateTime(2027, 1, 3, 19),
    );
  });

  test('commitment undo rejects old token, archive restores paused, and backup retains latest operation', () async {
    final created = await plan();
    final repo = DriftCommitmentRepository(database);
    await PauseCommitment(repo)(created.commitment.id);
    final pause = (await repo.statusUndo(created.commitment.id))!;
    await ArchiveCommitment(repo)(created.commitment.id);
    await expectLater(
      repo.undoStatus(created.commitment.id, pause),
      throwsA(isA<ValidationError>()),
    );
    await expectLater(
      ResumeCommitment(repo)(created.commitment.id),
      throwsA(isA<ValidationError>()),
    );
    await RestoreCommitment(repo)(created.commitment.id);
    expect(
      (await repo.findById(created.commitment.id))!.status,
      CommitmentStatus.paused,
    );
    final undo = (await repo.statusUndo(created.commitment.id))!;
    final bytes = await sqliteBackupSnapshot(
      database: database,
      target: File('${directory.path}/snapshot.sqlite'),
      redact: true,
    );
    await database.close();
    await file.writeAsBytes(bytes);
    database = AppDatabase.forTesting(NativeDatabase(file));
    final restored = DriftCommitmentRepository(database);
    await restored.undoStatus(created.commitment.id, undo);
    expect(
      (await restored.findById(created.commitment.id))!.status,
      CommitmentStatus.archived,
    );
    expect(await restored.statusUndo(created.commitment.id), isNull);
  });

  test('partial result can reopen; stale partial and ABA snapshots cannot overwrite later history', () async {
    final created = await plan();
    final repo = DriftActualRepository(database);
    final partial = await repo.recordOccurrenceActual(
      expected: created.occurrences.single,
      outcome: ActualOutcome.partial,
      recordedAt: DateTime.utc(2026),
    );
    final reopened = await repo.recordOccurrenceActual(
      expected: partial,
      outcome: ActualOutcome.reopened,
      recordedAt: DateTime.utc(2026),
    );
    expect(reopened.status, OccurrenceStatus.scheduled);
    await expectLater(
      repo.recordOccurrenceActual(
        expected: created.occurrences.single,
        outcome: ActualOutcome.completed,
        recordedAt: DateTime.utc(2026),
      ),
      throwsA(isA<ValidationError>()),
    );
    expect((await repo.list()).map((a) => a.outcome), [
      ActualOutcome.partial,
      ActualOutcome.reopened,
    ]);
    expect(await database.select(database.accountEntries).get(), isEmpty);
    expect(
      await database.select(database.entitlementLedgerEntries).get(),
      isEmpty,
    );
  });

  test('single schedule undo preserves intermediate audit and rejects superseded or resolved state', () async {
    final created = await plan();
    final plans = DriftCommitmentPlanRepository(database);
    await EditCommitmentSchedule(plans)(
      commitmentId: created.commitment.id,
      expected: created.occurrences.single,
      scheduledAt: DateTime(2027, 1, 3, 19),
      scope: SeriesEditScope.onlyThis,
      now: DateTime(2026, 10, 14),
    );
    final first = (await plans.scheduleUndo(created.commitment.id))!;
    var current = (await plans.findByCommitmentId(created.commitment.id))!;
    await EditCommitmentSchedule(plans)(
      commitmentId: created.commitment.id,
      expected: current.occurrences.single,
      scheduledAt: DateTime(2027, 1, 4, 20),
      scope: SeriesEditScope.onlyThis,
      now: DateTime(2026, 10, 14),
    );
    await expectLater(
      plans.undoSchedule(created.commitment.id, first, DateTime(2026, 10, 14)),
      throwsA(isA<ValidationError>()),
    );
    final latest = (await plans.scheduleUndo(created.commitment.id))!;
    await plans.undoSchedule(
      created.commitment.id,
      latest,
      DateTime(2026, 10, 14),
    );
    current = (await plans.findByCommitmentId(created.commitment.id))!;
    expect(
      current.occurrences.single.currentScheduledAt,
      DateTime(2027, 1, 3, 19),
    );
    expect(
      current.occurrences.single.originalScheduledAt,
      DateTime(2027, 1, 2, 18),
    );
    expect(await plans.scheduleUndo(created.commitment.id), isNull);
  });

  test('series undo creates a forward version, retaining previous definitions and occurrence identity', () async {
    final created = await plan(recurring: true);
    final plans = DriftCommitmentPlanRepository(database);
    final anchor = created.occurrences.first;
    await EditCommitmentSchedule(plans)(
      commitmentId: created.commitment.id,
      expected: anchor,
      scheduledAt: DateTime(2027, 1, 2, 19),
      scope: SeriesEditScope.thisAndFollowing,
      now: DateTime(2026, 10, 14),
    );
    final token = (await plans.scheduleUndo(created.commitment.id))!;
    await plans.undoSchedule(
      created.commitment.id,
      token,
      DateTime(2026, 10, 14),
    );
    final current = (await plans.findByCommitmentId(created.commitment.id))!;
    expect(current.schedule.version, created.schedule.version + 2);
    expect(current.schedule.localTime!.hour, 18);
    expect(
      current.occurrences.map((o) => o.id).toSet(),
      created.occurrences.map((o) => o.id).toSet(),
    );
    expect(
      (await database.select(database.scheduleDefinitions).get()).length,
      3,
    );
  });

  test('account undo is durable and rejects a token after another archive/restore pair', () async {
    final bank = await account('bank');
    var repo = DriftFinanceRepository(database);
    await FinanceUseCases(repo).archive(bank);
    final old = (await repo.accountStatusUndo(bank.id))!;
    await FinanceUseCases(repo).restore(bank);
    await FinanceUseCases(repo).archive(bank);
    await expectLater(
      repo.undoAccountStatus(bank.id, old),
      throwsA(isA<ValidationError>()),
    );
    final latest = (await repo.accountStatusUndo(bank.id))!;
    await database.close();
    database = AppDatabase.forTesting(NativeDatabase(file));
    repo = DriftFinanceRepository(database);
    await repo.undoAccountStatus(bank.id, latest);
    expect(
      (await repo.listAccounts()).single.status,
      FinancialAccountStatus.active,
    );
    expect(await repo.listEntries(), isEmpty);
  });

  test('two independent database owners cannot admit two reversals', () async {
    final bank = await account('bank');
    final first = FinanceUseCases(DriftFinanceRepository(database));
    final original = await first.record(
      account: bank,
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 100, currency: 'IRR'),
      occurredAt: DateTime.utc(2026),
    );
    final other = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final second = FinanceUseCases(DriftFinanceRepository(other));
      final outcomes = await Future.wait([
        first
            .voidEntry(original: original, account: bank)
            .then<Object>((r) => r, onError: (Object e) => e),
        second
            .voidEntry(original: original, account: bank)
            .then<Object>((r) => r, onError: (Object e) => e),
      ]);
      expect(outcomes.whereType<AccountEntry>().length, 1);
      expect((await first.balance(bank)).minorUnits, 0);
      expect((await first.repository.listEntries()).length, 2);
    } finally {
      await other.close();
    }
  });
}
