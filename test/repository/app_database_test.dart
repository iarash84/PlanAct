import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';

void main() {
  late db.AppDatabase database;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('creates the database and records its schema version', () async {
    expect(await database.readMetadata('schema_version'), '10');
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
  test(
    'round-trips reconciliation matches and allocations through Drift',
    () async {
      final repository = DriftReconciliationRepository(database);
      final matchId = StableId.generate(timestamp: DateTime.utc(2026, 9, 21));
      final correctedMatchId = StableId.generate(
        timestamp: DateTime.utc(2026, 9, 22),
      );
      final transactionId = StableId.generate(
        timestamp: DateTime.utc(2026, 9, 20),
      );
      final occurrenceA = StableId.generate(
        timestamp: DateTime.utc(2026, 9, 23),
      );
      final occurrenceB = StableId.generate(
        timestamp: DateTime.utc(2026, 9, 24),
      );

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
