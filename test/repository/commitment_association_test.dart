import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/data/commitment_association_metadata.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/domain/commitment_association.dart';
import 'package:planact/features/reports/data/drift_reports_reader.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late Directory directory;
  late File file;
  late AppDatabase database;
  late DriftReconciliationRepository repository;
  late AccountEntry transaction;
  late StableId owner, historicalOwner;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'commitment-association-',
    );
    file = File('${directory.path}/state.sqlite');
    database = AppDatabase.forTesting(NativeDatabase(file));
    repository = DriftReconciliationRepository(database);
    final finance = DriftFinanceRepository(database);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    transaction = AccountEntry(
      id: StableId.generate(),
      accountId: account.id,
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 1000, currency: 'IRR'),
      occurredAt: DateTime.utc(2026, 6, 1),
    );
    await finance.saveEntry(transaction);
    owner = StableId.generate();
    historicalOwner = StableId.generate();
    for (final (id, status) in [(owner, 0), (historicalOwner, 2)]) {
      await database.customStatement(
        'INSERT INTO commitments(id,title,created_at,status) VALUES (?, ?, 0, ?)',
        [id.value, 'تعهد', status],
      );
    }
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<CommitmentAssociation> associate(
    CommitmentAssociation expected,
    StableId? target,
  ) => repository.associateCommitment(
    expected: expected,
    transactionId: transaction.id,
    commitmentId: target,
  );

  Future<Map<String, List<Map<String, Object?>>>> effects() async => {
    for (final table in [
      'account_entries',
      'financial_accounts',
      'commitments',
      'commitment_cycles',
      'occurrences',
      'transaction_matches',
      'match_allocations',
      'relationship_reviews',
      'entitlement_ledger_entries',
      'financial_expectations',
    ])
      table: [
        for (final row
            in await database.customSelect('SELECT * FROM $table').get())
          row.data,
      ],
  };

  Future<SqliteBackupStorage> storage() async {
    final probe = sqlite.sqlite3.open(file.path);
    final schema = SqliteBackupStorage.schema(probe);
    probe.close();
    return SqliteBackupStorage(
      live: file,
      schemaVersion: database.schemaVersion,
      expectedSchema: schema,
      snapshot: () => sqliteBackupSnapshot(
        database: database,
        target: File('${directory.path}/snapshot.sqlite'),
        redact: true,
      ),
      closeLive: () async {},
    );
  }

  test('create change unlink and no-op retain monotonic history and no domain effects', () async {
    final before = await effects();
    final empty = await repository.loadAssociation(transaction.id);
    expect(empty.revision, 0);
    expect(empty.commitmentId, isNull);
    final first = await associate(empty, owner);
    expect(first.revision, 1);
    final unchanged = await associate(first, owner);
    expect(unchanged.revision, 1);
    final changed = await associate(first, historicalOwner);
    final unlinked = await associate(changed, null);
    expect(unlinked.revision, 3);
    expect(unlinked.commitmentId, isNull);
    final history = await repository.associationHistory(transaction.id);
    expect(history, hasLength(3));
    expect(history[0].before.sameState(empty), true);
    expect(history[1].before.sameState(first), true);
    expect(history[2].before.sameState(changed), true);
    expect(await effects(), before);
    expect(
      (await repository.loadReview(transaction)).remainderMinorUnits,
      1000,
    );
    expect((await repository.loadReview(transaction)).isIndependent, false);
  });

  test('contextual load offers commitments without occurrences and command refreshes head', () async {
    final flow = ContextualReconciliation(
      finance: DriftFinanceRepository(database),
      commitments: DriftCommitmentRepository(database),
      plans: DriftCommitmentPlanRepository(database),
      reconciliation: ReconciliationUseCases(repository),
    );
    final initial = await flow.load(transaction.id);
    expect(initial.targets, isEmpty);
    expect(
      initial.commitments.map((c) => c.id),
      containsAll([owner, historicalOwner]),
    );
    expect(initial.association!.revision, 0);
    await flow.associateCommitment(
      expected: initial.association!,
      transactionId: transaction.id,
      commitmentId: historicalOwner,
    );
    final refreshed = await flow.load(transaction.id);
    expect(refreshed.association!.commitmentId, historicalOwner);
    expect(refreshed.available.minorUnits, 1000);
    expect(refreshed.review!.isIndependent, false);
  });

  test('financial correction preserves original history but does not transfer association', () async {
    final saved = await associate(
      await repository.loadAssociation(transaction.id),
      owner,
    );
    final finance = DriftFinanceRepository(database);
    final account = (await finance.listAccounts()).single;
    final corrected = await FinanceUseCases(finance).correctEntry(
      original: transaction,
      account: account,
      type: transaction.type,
      amount: const Money(minorUnits: 900, currency: 'IRR'),
      occurredAt: transaction.occurredAt,
    );
    expect(
      (await repository.loadAssociation(transaction.id)).sameState(saved),
      true,
    );
    final replacement = await repository.loadAssociation(corrected.id);
    expect(replacement.revision, 0);
    expect(replacement.commitmentId, isNull);
    await expectLater(associate(saved, null), throwsA(isA<ValidationError>()));
    final filter = ReportFilter(
      from: DateTime(2026),
      to: DateTime(2026, 12, 31),
    );
    final snapshot = await DriftReportsReader(database)
        .read(filter, now: DateTime(2026));
    expect(
      buildPersonalReport(
        snapshot,
        filter,
        kind: PersonalReportKind.topic,
        now: DateTime(2026),
      ).associations,
      isEmpty,
    );
    final validator = await storage();
    await validator.validatePayload(
      await sqliteBackupSnapshot(
        database: database,
        target: File('${directory.path}/snapshot.sqlite'),
        redact: true,
      ),
    );
  });

  test('cold reopen retains null head and all before/after history', () async {
    var current = await repository.loadAssociation(transaction.id);
    current = await associate(current, owner);
    current = await associate(current, null);
    await database.close();
    database = AppDatabase.forTesting(NativeDatabase(file));
    repository = DriftReconciliationRepository(database);
    expect(
      (await repository.loadAssociation(transaction.id)).sameState(current),
      true,
    );
    final history = await repository.associationHistory(transaction.id);
    expect(history, hasLength(2));
    expect(history.first.after.commitmentId, owner);
    expect(history.last.after.commitmentId, isNull);
  });

  test(
    'ABA target and null-head cycles never revive stale revision tokens',
    () async {
      final empty = await repository.loadAssociation(transaction.id);
      final first = await associate(empty, owner);
      final changed = await associate(first, historicalOwner);
      final returned = await associate(changed, owner);
      final before = await effects();
      await expectLater(
        associate(first, historicalOwner),
        throwsA(isA<ValidationError>()),
      );
      await expectLater(
        associate(first, owner),
        throwsA(isA<ValidationError>()),
      );
      final unlinked = await associate(returned, null);
      await expectLater(
        associate(empty, owner),
        throwsA(isA<ValidationError>()),
      );
      expect(unlinked.revision, 4);
      expect(await repository.associationHistory(transaction.id), hasLength(4));
      expect(await effects(), before);
    },
  );

  test('stale same-target and wrong transaction expected heads reject without writes', () async {
    final empty = await repository.loadAssociation(transaction.id);
    await associate(empty, owner);
    for (final expected in [
      empty,
      CommitmentAssociation(transactionId: StableId.generate()),
    ]) {
      await expectLater(
        associate(expected, owner),
        throwsA(isA<ValidationError>()),
      );
    }
    expect(await repository.associationHistory(transaction.id), hasLength(1));
  });

  test(
    'independent SQLite writers cannot both admit the same expected revision',
    () async {
      final second = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final other = DriftReconciliationRepository(second);
        final empty = await repository.loadAssociation(transaction.id);
        final outcomes = await Future.wait([
          associate(
            empty,
            owner,
          ).then((_) => true, onError: (Object _) => false),
          other
              .associateCommitment(
                expected: empty,
                transactionId: transaction.id,
                commitmentId: historicalOwner,
              )
              .then((_) => true, onError: (Object _) => false),
        ]);
        expect(outcomes.where((e) => e), hasLength(1));
        expect(
          await repository.associationHistory(transaction.id),
          hasLength(1),
        );
      } finally {
        await second.close();
      }
    },
  );

  test('missing target archived account currency mismatch reversal and transfer reject', () async {
    final empty = await repository.loadAssociation(transaction.id);
    await expectLater(
      associate(empty, StableId.generate()),
      throwsA(isA<ValidationError>()),
    );
    await database.customStatement('UPDATE financial_accounts SET status=1');
    await expectLater(associate(empty, owner), throwsA(isA<ValidationError>()));
    await database.customStatement(
      "UPDATE financial_accounts SET status=0, currency='USD'",
    );
    await expectLater(associate(empty, owner), throwsA(isA<ValidationError>()));
    await database.customStatement(
      "UPDATE financial_accounts SET currency='IRR'",
    );
    await database.customStatement('UPDATE account_entries SET type=?', [
      AccountEntryType.transferOut.index,
    ]);
    await expectLater(associate(empty, owner), throwsA(isA<ValidationError>()));
    await database.customStatement('UPDATE account_entries SET type=?', [
      AccountEntryType.expense.index,
    ]);
    await database.customStatement(
      'INSERT INTO account_entries(id,account_id,type,minor_units,currency,occurred_at,reference_id) VALUES (?, ?, ?, 1000, ?, 0, ?)',
      [
        StableId.generate().value,
        transaction.accountId.value,
        AccountEntryType.reversal.index,
        'IRR',
        transaction.id.value,
      ],
    );
    await expectLater(associate(empty, owner), throwsA(isA<ValidationError>()));
    expect(await repository.associationHistory(transaction.id), isEmpty);
  });

  test(
    'failed head write rolls back appended revision and retry succeeds',
    () async {
      final empty = await repository.loadAssociation(transaction.id);
      await database.customStatement(
        "CREATE TRIGGER fail_association_head BEFORE INSERT ON schema_metadata WHEN NEW.key LIKE 'transaction_commitment_head_v1:%' BEGIN SELECT RAISE(ABORT, 'test'); END",
      );
      await expectLater(associate(empty, owner), throwsException);
      expect(await repository.associationHistory(transaction.id), isEmpty);
      await database.customStatement('DROP TRIGGER fail_association_head');
      expect((await associate(empty, owner)).revision, 1);
    },
  );

  test('strict personal snapshot preserves association and rejects corrupt head history and refs', () async {
    await associate(
      await repository.loadAssociation(transaction.id),
      historicalOwner,
    );
    final validator = await storage();
    final payload = await sqliteBackupSnapshot(
      database: database,
      target: File('${directory.path}/snapshot.sqlite'),
      redact: true,
    );
    await validator.validatePayload(payload);
    final restored = File('${directory.path}/restored.sqlite');
    await restored.writeAsBytes(payload);
    final reopened = AppDatabase.forTesting(NativeDatabase(restored));
    try {
      expect(
        (await DriftReconciliationRepository(reopened)
                .loadAssociation(transaction.id))
            .commitmentId,
        historicalOwner,
      );
    } finally {
      await reopened.close();
    }
    final head =
        '${CommitmentAssociationMetadata.headPrefix}${transaction.id.value}';
    final revision =
        '${CommitmentAssociationMetadata.historyPrefix}${transaction.id.value}:1';
    final corruptions = <void Function(sqlite.Database)>[
      (db) => db.execute('DELETE FROM schema_metadata WHERE key=?', [head]),
      (db) => db.execute('DELETE FROM schema_metadata WHERE key=?', [revision]),
      (db) => db.execute('UPDATE schema_metadata SET value=? WHERE key=?', [
        '{}',
        head,
      ]),
      (db) => db.execute('UPDATE schema_metadata SET value=? WHERE key=?', [
        jsonEncode({
          'transactionId': transaction.id.value,
          'revision': 2,
          'commitmentId': historicalOwner.value,
        }),
        head,
      ]),
      (db) => db.execute('DELETE FROM commitments WHERE id=?', [
        historicalOwner.value,
      ]),
      (db) => db.execute('UPDATE account_entries SET type=? WHERE id=?', [
        AccountEntryType.transferOut.index,
        transaction.id.value,
      ]),
    ];
    for (final corrupt in corruptions) {
      await restored.writeAsBytes(payload);
      final raw = sqlite.sqlite3.open(restored.path);
      try {
        corrupt(raw);
      } finally {
        raw.close();
      }
      expect(
        () => validator.validateFile(restored),
        throwsA(isA<ValidationError>()),
      );
      // Exercise the incoming-payload boundary too, not just the helper.
      await expectLater(
        validator.validatePayload(await restored.readAsBytes()),
        throwsA(isA<ValidationError>()),
      );
      expect(await repository.associationHistory(transaction.id), hasLength(1));
    }
  });

  test('production reports separate descriptive row from subject cash settlement and attention', () async {
    await associate(
      await repository.loadAssociation(transaction.id),
      historicalOwner,
    );
    final reader = DriftReportsReader(database);
    final filter = ReportFilter(
      from: DateTime(2026),
      to: DateTime(2026, 12, 31),
    );
    final snapshot = await reader.read(filter, now: DateTime.utc(2026));
    expect(snapshot.associations, hasLength(1));
    final report = buildPersonalReport(
      snapshot,
      filter,
      kind: PersonalReportKind.overview,
      now: DateTime.utc(2026),
    );
    expect(report.associations, hasLength(1));
    expect(report.settlements, isEmpty);
    expect(report.cashTotals['IRR']!.outgoing, 1000);
    expect(report.unreviewed[transaction.id]!.remainderMinorUnits, 1000);
    final subject = buildPersonalReport(
      snapshot,
      ReportFilter(
        from: DateTime(2026),
        to: DateTime(2026, 12, 31),
        commitmentId: historicalOwner,
      ),
      kind: PersonalReportKind.topic,
      now: DateTime.utc(2026),
    );
    expect(subject.associations, hasLength(1));
    expect(subject.movements, isEmpty);
    expect(subject.cashTotals, isEmpty);
    final other = buildPersonalReport(
      snapshot,
      ReportFilter(
        from: DateTime(2025),
        to: DateTime(2027),
        commitmentId: owner,
      ),
      kind: PersonalReportKind.topic,
      now: DateTime.utc(2026),
    );
    expect(other.associations, isEmpty);
    final mismatches = <ReportFilter>[
      ReportFilter(from: DateTime(2025), to: DateTime(2025, 12, 31)),
      ReportFilter(
        from: DateTime(2026),
        to: DateTime(2026, 12, 31),
        accountId: StableId.generate(),
      ),
      ReportFilter(
        from: DateTime(2026),
        to: DateTime(2026, 12, 31),
        currency: 'USD',
      ),
      ReportFilter(
        from: DateTime(2026),
        to: DateTime(2026, 12, 31),
        entryType: AccountEntryType.income,
      ),
      ReportFilter(
        from: DateTime(2026),
        to: DateTime(2026, 12, 31),
        category: 'other',
      ),
      ReportFilter(
        from: DateTime(2026),
        to: DateTime(2026, 12, 31),
        query: 'absent',
      ),
      ReportFilter(
        from: DateTime(2026),
        to: DateTime(2026, 12, 31),
        cycleId: StableId.generate(),
      ),
      ReportFilter(
        from: DateTime(2026),
        to: DateTime(2026, 12, 31),
        settlementState: ReportSettlementState.settled,
      ),
      ReportFilter(
        from: DateTime(2026),
        to: DateTime(2026, 12, 31),
        tags: {StableId.generate()},
      ),
      ReportFilter(
        from: DateTime(2026),
        to: DateTime(2026, 12, 31),
        tags: {StableId.generate()},
        tagSource: ReportTagSource.relatedAllocation,
      ),
    ];
    for (final mismatch in mismatches) {
      expect(
        buildPersonalReport(
          snapshot,
          mismatch,
          kind: PersonalReportKind.topic,
          now: DateTime.utc(2026),
        ).associations,
        isEmpty,
      );
    }
  });
}
