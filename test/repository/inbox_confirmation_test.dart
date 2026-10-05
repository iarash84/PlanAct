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
