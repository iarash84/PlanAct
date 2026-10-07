import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

void main() {
  test(
    'concurrent confirmations and restart retry create one ledger entry',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'planact-inbox-confirm-',
      );
      final file = File(
        '${directory.path}${Platform.pathSeparator}planact.sqlite',
      );
      final database = AppDatabase.forTesting(NativeDatabase(file));
      final inbox = InboxUseCases(DriftInboxRepository(database));
      final finance = DriftFinanceRepository(database);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'بانک',
        currency: 'IRR',
        type: FinancialAccountType.bank,
      );
      await finance.saveAccount(account);
      final suggestion = await inbox.stageSms(
        rawText: 'برداشت مبلغ ۲۵۰۰ 2026-09-20',
        sourceKey: 'sms:one',
        currency: 'IRR',
        importedAt: DateTime.utc(2026, 9, 20),
      );
      final results = await Future.wait([
        inbox.confirm(
          suggestion: suggestion,
          account: account,
          finance: finance,
        ),
        inbox.confirm(
          suggestion: suggestion,
          account: account,
          finance: finance,
        ),
      ]);
      expect(results[0].id, results[1].id);
      expect(await finance.listEntries(), hasLength(1));
      await database.close();
      final reopened = AppDatabase.forTesting(NativeDatabase(file));
      final replay = await InboxUseCases(DriftInboxRepository(reopened))
          .confirm(
            suggestion: suggestion,
            account: account,
            finance: DriftFinanceRepository(reopened),
          );
      expect(replay.id, results.first.id);
      final differentAccount = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب دوم',
        currency: 'IRR',
        type: FinancialAccountType.bank,
      );
      await DriftFinanceRepository(reopened).saveAccount(differentAccount);
      await expectLater(
        InboxUseCases(DriftInboxRepository(reopened)).confirm(
          suggestion: suggestion,
          account: differentAccount,
          finance: DriftFinanceRepository(reopened),
        ),
        throwsStateError,
      );
      expect(
        await DriftFinanceRepository(reopened).listEntries(),
        hasLength(1),
      );
      expect(
        (await DriftInboxRepository(reopened).listSuggestions()).single.status,
        SuggestionStatus.confirmed,
      );
      await reopened.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'concurrent staging preserves one import and suggestion after restart',
    () async {
      final directory = await Directory.systemTemp.createTemp('planact-stage-');
      final file = File(
        '${directory.path}${Platform.pathSeparator}planact.sqlite',
      );
      final database = AppDatabase.forTesting(NativeDatabase(file));
      final inbox = InboxUseCases(DriftInboxRepository(database));
      final staged = await Future.wait([
        inbox.stageSms(
          rawText: 'برداشت مبلغ ۲۵۰۰ 2026-09-20',
          sourceKey: 'sms:shared',
          currency: 'IRR',
          importedAt: DateTime.utc(2026, 9, 20),
        ),
        inbox.stageSms(
          rawText: 'برداشت مبلغ ۲۵۰۰ 2026-09-20',
          sourceKey: 'sms:shared',
          currency: 'IRR',
          importedAt: DateTime.utc(2026, 9, 21),
        ),
      ]);
      expect(staged.first.id, staged.last.id);
      await database.close();
      final reopened = AppDatabase.forTesting(NativeDatabase(file));
      final repository = DriftInboxRepository(reopened);
      expect(await repository.listImports(), hasLength(1));
      expect(await repository.listSuggestions(), hasLength(1));
      await reopened.close();
      await directory.delete(recursive: true);
    },
  );

  test('rejection persists both statuses', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftInboxRepository(database);
    final inbox = InboxUseCases(repository);
    final suggestion = await inbox.stageSms(
      rawText: 'برداشت مبلغ ۳۰۰۰ 2026-09-20',
      sourceKey: 'sms:reject',
      currency: 'IRR',
    );
    await inbox.reject(suggestion);
    expect(
      (await repository.listSuggestions()).single.status,
      SuggestionStatus.rejected,
    );
    final rejectedImport = (await repository.listImports()).single;
    expect(rejectedImport.status, StagedItemStatus.rejected);
    expect(rejectedImport.retentionStatus, RawTextRetentionStatus.rejected);
    expect(rejectedImport.lastDecisionAt, isNotNull);
  });

  test(
    'same source key with different content cannot overwrite import',
    () async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final repository = DriftInboxRepository(database);
      final inbox = InboxUseCases(repository);
      final original = await inbox.stageSms(
        rawText: 'برداشت مبلغ ۳۰۰۰ 2026-09-20',
        sourceKey: 'sms:collision',
        currency: 'IRR',
      );
      await expectLater(
        inbox.stageSms(
          rawText: 'برداشت مبلغ ۴۰۰۰ 2026-09-20',
          sourceKey: 'sms:collision',
          currency: 'IRR',
        ),
        throwsA(isA<Exception>()),
      );
      expect((await repository.listImports()).single.rawText, contains('۳۰۰۰'));
      expect((await repository.listSuggestions()).single.id, original.id);
    },
  );

  test('failed suggestion insert rolls back staged import', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftInboxRepository(database);
    final inbox = InboxUseCases(repository);
    // Force a failure after the import write, inside the same transaction.
    await database.customStatement('''
      CREATE TRIGGER fail_suggestion BEFORE INSERT ON inbox_suggestions
      BEGIN SELECT RAISE(ABORT, 'injected suggestion failure'); END
    ''');
    await expectLater(
      inbox.stageSms(
        rawText: 'برداشت مبلغ ۳۰۰۰ 2026-09-20',
        sourceKey: 'sms:failed',
        currency: 'IRR',
      ),
      throwsA(anything),
    );
    expect(await repository.listImports(), isEmpty);
    expect(await repository.listSuggestions(), isEmpty);
  });

  test('failed import status update rolls back suggestion rejection', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftInboxRepository(database);
    final inbox = InboxUseCases(repository);
    final suggestion = await inbox.stageSms(
      rawText: 'برداشت مبلغ ۳۰۰۰ 2026-09-20',
      sourceKey: 'sms:reject-failure',
      currency: 'IRR',
    );
    await database.customStatement('''
      CREATE TRIGGER fail_rejection BEFORE UPDATE ON staged_imports
      BEGIN SELECT RAISE(ABORT, 'injected import update failure'); END
    ''');
    await expectLater(inbox.reject(suggestion), throwsA(anything));
    expect(
      (await repository.listSuggestions()).single.status,
      SuggestionStatus.pending,
    );
    expect(
      (await repository.listImports()).single.status,
      StagedItemStatus.pending,
    );
  });

  test('confirmed suggestion cannot be rejected with stale copy', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftInboxRepository(database);
    final inbox = InboxUseCases(repository);
    final finance = DriftFinanceRepository(database);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    final suggestion = await inbox.stageSms(
      rawText: 'برداشت مبلغ ۳۰۰۰ 2026-09-20',
      sourceKey: 'sms:confirmed',
      currency: 'IRR',
    );
    await inbox.confirm(
      suggestion: suggestion,
      account: account,
      finance: finance,
    );
    await expectLater(inbox.reject(suggestion), throwsA(isA<Exception>()));
    expect(
      (await repository.listSuggestions()).single.status,
      SuggestionStatus.confirmed,
    );
    expect(
      (await repository.listImports()).single.status,
      StagedItemStatus.confirmed,
    );
    expect(await finance.listEntries(), hasLength(1));
  });

  test('rejected stale suggestion cannot insert a financial entry', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final inbox = InboxUseCases(DriftInboxRepository(database));
    final finance = DriftFinanceRepository(database);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    final suggestion = await inbox.stageSms(
      rawText: 'برداشت مبلغ ۳۰۰۰ 2026-09-20',
      sourceKey: 'sms:two',
      currency: 'IRR',
    );
    // Rejecting a stale suggestion must not insert a financial row.
    await inbox.reject(suggestion);
    await expectLater(
      inbox.confirm(suggestion: suggestion, account: account, finance: finance),
      throwsStateError,
    );
    expect(await finance.listEntries(), isEmpty);
  });
}
