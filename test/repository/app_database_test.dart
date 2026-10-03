import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';

void main() {
  // Restart tests intentionally open the same SQLite file sequentially. The
  // old instance is closed before the new one; suppress only Drift's global
  // duplicate-class diagnostic in this harness.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('creates the database and records its schema version', () async {
    expect(await database.readMetadata('schema_version'), '16');
    expect(await database.select(database.transactionMatches).get(), isEmpty);
    expect(await database.select(database.matchAllocations).get(), isEmpty);
    expect(await database.select(database.financialAccounts).get(), isEmpty);
    expect(await database.select(database.accountEntries).get(), isEmpty);
    expect(await database.select(database.actuals).get(), isEmpty);
    expect(await database.select(database.evidences).get(), isEmpty);
    expect(await database.select(database.scheduleDefinitions).get(), isEmpty);
    expect(await database.select(database.occurrences).get(), isEmpty);
    expect(await database.select(database.entitlementPlans).get(), isEmpty);
    expect(
      await database.select(database.entitlementLedgerEntries).get(),
      isEmpty,
    );
    expect(await database.select(database.sessionPolicies).get(), isEmpty);
    expect(
      await database.select(database.replacementOccurrences).get(),
      isEmpty,
    );
    expect(await database.select(database.reminderRules).get(), isEmpty);
    expect(await database.select(database.reminderInstances).get(), isEmpty);
  });

  test('persists SMS retention metadata across database restart', () async {
    final directory = await Directory.systemTemp.createTemp(
      'planact-retention-',
    );
    final path = '${directory.path}${Platform.pathSeparator}planact.sqlite';
    final first = db.AppDatabase(NativeDatabase(File(path)));
    final repository = DriftInboxRepository(first);
    final importedAt = DateTime.utc(2026, 1, 1);
    final item = StagedImport(
      id: StableId.generate(timestamp: importedAt),
      rawText: 'sensitive amount 1000',
      fingerprint: 'fingerprint-retention',
      provenance: ImportProvenance(
        source: ImportSource.sms,
        sourceKey: 'restart-sms',
        importedAt: importedAt,
      ),
      retentionUntil: importedAt.add(const Duration(days: 30)),
    );
    await repository.saveImport(item);
    await first.close();

    final second = db.AppDatabase(NativeDatabase(File(path)));
    final restored = (await DriftInboxRepository(second).listImports()).single;
    expect(restored.retentionUntil, item.retentionUntil);
    expect(restored.fingerprint, item.fingerprint);
    await second.close();
    await Directory(directory.path).delete(recursive: true);
  });

  test('persists bank identity across database restart', () async {
    final directory = await Directory.systemTemp.createTemp('planact-bank-');
    final path = '${directory.path}${Platform.pathSeparator}planact.sqlite';
    final first = db.AppDatabase(NativeDatabase(File(path)));
    final account = FinancialAccount(
      id: StableId.generate(timestamp: DateTime.utc(2026, 9, 27)),
      name: 'حساب حقوق',
      currency: 'تومان',
      type: FinancialAccountType.bank,
      bank: IranianBank.mellat,
    );
    await DriftFinanceRepository(first).saveAccount(account);
    await first.close();

    final second = db.AppDatabase(NativeDatabase(File(path)));
    final restored = (await DriftFinanceRepository(
      second,
    ).listAccounts()).single;
    expect(restored.bank, IranianBank.mellat);
    expect(restored.name, account.name);
    await second.close();
    await directory.delete(recursive: true);
  });

  test('persists a newly created financial account through Drift', () async {
    final repository = DriftFinanceRepository(database);
    final account = FinancialAccount(
      id: StableId.generate(timestamp: DateTime.utc(2026, 9, 27)),
      name: 'حساب نقدی',
      currency: 'تومان',
      type: FinancialAccountType.cash,
    );

    await repository.saveAccount(account);
    final stored = await repository.listAccounts();

    expect(stored, hasLength(1));
    expect(stored.single.id, account.id);
    expect(stored.single.name, account.name);
    expect(stored.single.currency, account.currency);
    expect(stored.single.type, FinancialAccountType.cash);
    expect(stored.single.status, FinancialAccountStatus.active);
  });

  test(
    'persists and updates commitments through the Drift repository',
    () async {
      final repository = DriftCommitmentRepository(database);
      final created = Commitment.create(
        title: 'کلاس زبان',
        now: DateTime.utc(2026, 9, 20, 10),
        kind: CommitmentKind.recurring,
        priority: CommitmentPriority.high,
        description: 'جلسهٔ هفتگی',
        tags: {'آموزش', 'کلاس'},
        attachmentIds: ['file-1'],
      );

      await repository.save(created);
      expect(await repository.findById(created.id), isNotNull);

      final paused = created.pause();
      await repository.save(paused);
      final stored = await repository.findById(created.id);

      expect(stored?.title, 'کلاس زبان');
      expect(stored?.status, CommitmentStatus.paused);
      expect(stored?.kind, CommitmentKind.recurring);
      expect(stored?.priority, CommitmentPriority.high);
      expect(stored?.description, 'جلسهٔ هفتگی');
      expect(stored?.tags, containsAll(['آموزش', 'کلاس']));
      expect(stored?.attachmentIds, ['file-1']);
      expect(
        (await repository.list()).map((item) => item.id),
        contains(created.id),
      );
    },
  );
  test('round-trips a commitment plan after a database restart', () async {
    final directory = await Directory.systemTemp.createTemp('planact-restart-');
    final path = '${directory.path}${Platform.pathSeparator}planact.sqlite';
    final firstDatabase = db.AppDatabase(NativeDatabase(File(path)));
    final commitments = DriftCommitmentRepository(firstDatabase);
    final plans = DriftCommitmentPlanRepository(firstDatabase);
    final start = DateTime(2026, 9, 22, 18, 30);
    final created =
        await CreateCommitmentPlan(commitments: commitments, plans: plans).call(
          title: 'کلاس پایدار',
          startAt: start,
          kind: CommitmentKind.recurring,
          frequency: RecurrenceFrequency.weekly,
          weekdays: {2},
          occurrenceCount: 3,
        );
    await firstDatabase.close();

    final secondDatabase = db.AppDatabase(NativeDatabase(File(path)));
    final restoredCommitment = await DriftCommitmentRepository(secondDatabase)
        .findById(created.commitment.id);
    final restored = await DriftCommitmentPlanRepository(secondDatabase)
        .findByCommitmentId(created.commitment.id);

    expect(restoredCommitment?.title, created.commitment.title);
    expect(restored?.schedule.mode, ScheduleMode.fixedCount);
    expect(restored?.schedule.startDate, created.schedule.startDate);
    expect(restored?.schedule.localTime, created.schedule.localTime);
    expect(
      restored?.schedule.recurrenceRule?.frequency,
      RecurrenceFrequency.weekly,
    );
    expect(restored?.schedule.recurrenceRule?.weekdays, {2});
    expect(restored?.schedule.occurrenceCount, 3);
    final restoredByKey = {
      for (final item in restored!.occurrences) item.occurrenceKey: item,
    };
    for (final expected in created.occurrences) {
      expect(
        restoredByKey[expected.occurrenceKey]?.currentScheduledAt,
        expected.currentScheduledAt,
      );
    }

    await secondDatabase.close();
    await directory.delete(recursive: true);
  });

  test(
    'persists a commitment without a schedule and preserves archive state',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'planact-archive-',
      );
      final path = '${directory.path}${Platform.pathSeparator}planact.sqlite';
      final firstDatabase = db.AppDatabase(NativeDatabase(File(path)));
      final repository = DriftCommitmentRepository(firstDatabase);
      final created = Commitment.create(
        title: 'تعهد بدون زمان‌بندی',
        now: DateTime.utc(2026, 9, 22),
      );

      await repository.save(created);
      await repository.save(created.archive());
      await firstDatabase.close();

      final secondDatabase = db.AppDatabase(NativeDatabase(File(path)));
      final restored = await DriftCommitmentRepository(secondDatabase)
          .findById(created.id);

      expect(restored?.title, created.title);
      expect(restored?.status, CommitmentStatus.archived);
      expect(
        await secondDatabase.select(secondDatabase.scheduleDefinitions).get(),
        isEmpty,
      );

      await secondDatabase.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'round-trips reconciliation matches and allocations through Drift',
    () async {
      final finance = DriftFinanceRepository(database);
      final account = FinancialAccount(
        id: StableId.generate(timestamp: DateTime.utc(2026, 9, 19)),
        name: 'حساب تطبیق',
        currency: 'IRR',
        type: FinancialAccountType.bank,
      );
      await finance.saveAccount(account);
      final transactionId = StableId.generate(
        timestamp: DateTime.utc(2026, 9, 20),
      );
      await finance.saveEntry(
        AccountEntry(
          id: transactionId,
          accountId: account.id,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 1000, currency: 'IRR'),
          occurredAt: DateTime.utc(2026, 9, 20),
        ),
      );
      final commitment = Commitment.create(
        title: 'تعهد تطبیق',
        now: DateTime.utc(2026, 9, 18),
      );
      await DriftCommitmentRepository(database).save(commitment);
      final cycle = await database
          .into(database.commitmentCycles)
          .insertReturning(
            db.CommitmentCyclesCompanion.insert(
              id: StableId.generate(timestamp: DateTime.utc(2026, 9, 18)).value,
              commitmentId: commitment.id.value,
              cycleType: 0,
              startDate: DateTime.utc(2026, 9, 18),
              consumedUnits: 0,
              completionRule: 0,
              status: 0,
            ),
          );
      final schedule = await database
          .into(database.scheduleDefinitions)
          .insertReturning(
            db.ScheduleDefinitionsCompanion.insert(
              id: StableId.generate(timestamp: DateTime.utc(2026, 9, 18, 1))
                  .value,
              cycleId: cycle.id,
              mode: 0,
              timeSemantics: 2,
              startDate: '2026-09-18',
              version: 1,
              effectiveFrom: '2026-09-18',
              generationHorizonDays: 90,
            ),
          );
      final occurrenceId = StableId.generate(
        timestamp: DateTime.utc(2026, 9, 18, 2),
      );
      await database
          .into(database.occurrences)
          .insert(
            db.OccurrencesCompanion.insert(
              id: occurrenceId.value,
              cycleId: cycle.id,
              scheduleDefinitionId: schedule.id,
              occurrenceKey: 'test-occurrence',
              timeSemantics: 2,
              originalScheduledValue: 'instant:2026-09-18T00:00:00.000Z',
              currentScheduledValue: 'instant:2026-09-18T00:00:00.000Z',
              status: 0,
              isManualOverride: false,
            ),
          );
      final repository = DriftReconciliationRepository(database);
      final matchId = StableId.generate(timestamp: DateTime.utc(2026, 9, 21));
      final correctedMatchId = StableId.generate(
        timestamp: DateTime.utc(2026, 9, 22),
      );
      final occurrenceA = occurrenceId;
      final occurrenceB = occurrenceId;

      final match = TransactionMatch(
        id: matchId,
        transactionId: transactionId,
        transactionAmount: const Money(minorUnits: 1000, currency: 'IRR'),
        createdAt: DateTime.utc(2026, 9, 21),
        status: MatchStatus.corrected,
        correctedMatchId: correctedMatchId,
        allocations: [
          MatchAllocation(
            id: StableId.generate(timestamp: DateTime.utc(2026, 9, 25)),
            matchId: matchId,
            occurrenceId: occurrenceA,
            amount: const Money(minorUnits: 400, currency: 'IRR'),
          ),
          MatchAllocation(
            id: StableId.generate(timestamp: DateTime.utc(2026, 9, 26)),
            matchId: matchId,
            occurrenceId: occurrenceB,
            amount: const Money(minorUnits: 300, currency: 'IRR'),
            type: AllocationType.correction,
          ),
        ],
      );

      await repository.save(match);
      final stored = await repository.list();

      expect(stored, hasLength(1));
      expect(stored.single.id, matchId);
      expect(stored.single.transactionId, transactionId);
      expect(stored.single.status, MatchStatus.corrected);
      expect(stored.single.correctedMatchId, correctedMatchId);
      expect(
        stored.single.remaining,
        const Money(minorUnits: 300, currency: 'IRR'),
      );
      expect(stored.single.allocations, hasLength(2));
      expect(stored.single.allocations.last.occurrenceId, occurrenceB);
      expect(stored.single.allocations.last.type, AllocationType.correction);
    },
  );

  test('round-trips staged imports and suggestions through Drift', () async {
    final repository = DriftInboxRepository(database);
    final staged = StagedImport(
      id: StableId.generate(timestamp: DateTime.utc(2026, 9, 20)),
      rawText: 'amount 2500 2026-09-20',
      fingerprint: 'fingerprint-1',
      provenance: ImportProvenance(
        source: ImportSource.sms,
        sourceKey: 'sms-1',
        importedAt: DateTime.utc(2026, 9, 20),
      ),
    );
    final suggestion = InboxSuggestion(
      id: StableId.generate(timestamp: DateTime.utc(2026, 9, 21)),
      stagedImportId: staged.id,
      draft: TransactionDraft(
        id: StableId.generate(timestamp: DateTime.utc(2026, 9, 22)),
        stagedImportId: staged.id,
        amount: const Money(minorUnits: 2500, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 9, 20),
        type: 'expense',
        merchant: 'فروشگاه',
      ),
    );

    await repository.saveImport(staged);
    await repository.saveSuggestion(suggestion);

    final imports = await repository.listImports();
    final suggestions = await repository.listSuggestions();
    expect(imports.single.fingerprint, 'fingerprint-1');
    expect(imports.single.provenance.source, ImportSource.sms);
    expect(
      suggestions.single.draft.amount,
      const Money(minorUnits: 2500, currency: 'IRR'),
    );
    expect(suggestions.single.draft.merchant, 'فروشگاه');
  });
}
