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
    'provider replay after restart preserves expired and rejected history',
    () async {
      final directory = await Directory.systemTemp.createTemp('sms-replay-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/state.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      final at = DateTime.utc(2026, 1, 2, 14, 37);
      var inbox = InboxUseCases(DriftInboxRepository(database));
      final original = await inbox.stageSms(
        rawText: 'برداشت مبلغ ۲۵۰۰',
        sourceKey: 'android-sms:42',
        currency: 'IRR',
        importedAt: at,
      );
      expect(original.draft.occurredAt, at);
      await inbox.reject(original);
      await inbox.expireRawText(now: DateTime.utc(2026, 3));
      await database.close();
      database = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(() => database.close());
      final repository = DriftInboxRepository(database);
      inbox = InboxUseCases(repository);
      final replay = await inbox.stageSms(
        rawText: 'برداشت مبلغ ۲۵۰۰',
        sourceKey: 'android-sms:42',
        currency: 'IRR',
        importedAt: at,
      );
      expect(replay.id, original.id);
      expect(replay.status, SuggestionStatus.rejected);
      expect((await repository.listImports()).single.rawText, isEmpty);
      expect(
        (await repository.listImports()).single.retentionStatus,
        RawTextRetentionStatus.expired,
      );
      await expectLater(
        inbox.stageSms(
          rawText: 'برداشت مبلغ ۲۵۰۰',
          sourceKey: 'android-sms:restored',
          currency: 'IRR',
          importedAt: at,
        ),
        throwsA(isA<DuplicateSmsImport>()),
      );
      expect(await repository.listSuggestions(), hasLength(1));
      expect(await DriftFinanceRepository(database).listEntries(), isEmpty);
    },
  );

  test('stale edit cannot reopen confirmed or rejected suggestions', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftInboxRepository(database);
    final inbox = InboxUseCases(repository);
    final finance = DriftFinanceRepository(database);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'بانک',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    final suggestion = await inbox.stageSms(
      rawText: 'برداشت مبلغ ۴۰۰۰',
      sourceKey: 'android-sms:44',
      currency: 'IRR',
    );
    await inbox.confirm(
      suggestion: suggestion,
      account: account,
      finance: finance,
    );
    await expectLater(
      inbox.edit(suggestion, suggestion.draft),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      repository.saveSuggestion(suggestion),
      throwsA(isA<Exception>()),
    );
    expect(
      (await repository.listSuggestions()).single.status,
      SuggestionStatus.confirmed,
    );
    expect(await finance.listEntries(), hasLength(1));
    final rejected = await inbox.stageSms(
      rawText: 'برداشت مبلغ ۵۰۰۰',
      sourceKey: 'android-sms:45',
      currency: 'IRR',
    );
    await inbox.reject(rejected);
    await expectLater(
      inbox.edit(rejected, rejected.draft),
      throwsA(isA<Exception>()),
    );
    expect(await finance.listEntries(), hasLength(1));
  });
}
