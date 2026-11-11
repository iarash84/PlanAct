import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

import 'sms_bounded_ingestion_test.dart' show PagedSource;

void main() {
  test(
    'Novin corpus survives consented ingestion, replay and cold reopen',
    () async {
      final rows = File('test/fixtures/device_sms_corpus/ENBANK.txt')
          .readAsStringSync()
          .split(RegExp(r'(?=^Row:)', multiLine: true))
          .where((row) => row.startsWith('Row:'))
          .toList();
      expect(rows, hasLength(15));
      final messages = [
        for (final row in rows)
          AndroidSmsMessage(
            sourceKey:
                'android-sms:${RegExp(r'_id=(\d+)').firstMatch(row)!.group(1)}',
            address: 'ENBANK',
            body: row
                .substring(row.indexOf('body=') + 5)
                .replaceFirst(RegExp(r', date=\d+\s*$'), ''),
            receivedAt: DateTime.fromMillisecondsSinceEpoch(
              int.parse(RegExp(r', date=(\d+)').firstMatch(row)!.group(1)!),
              isUtc: true,
            ),
          ),
      ];
      final dir = await Directory.systemTemp.createTemp('novin-sms-');
      final file = File('${dir.path}/state.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(() async {
        await db.close();
        await dir.delete(recursive: true);
      });
      var repo = DriftInboxRepository(db);
      final source = PagedSource([
        for (var i = 0; i < messages.length; i++)
          SmsProviderRow(
            messages[i].receivedAt.millisecondsSinceEpoch,
            i + 1,
            messages[i],
          ),
      ]);
      final command = SmsIngestion(InboxUseCases(repo), source);
      await expectLater(
        command.run(onProgress: (_) {}),
        throwsA(isA<ValidationError>()),
      );
      expect(source.reads, 0);
      await command.consent(
        from: messages.first.receivedAt.subtract(const Duration(seconds: 1)),
        until: messages.last.receivedAt.add(const Duration(seconds: 1)),
        newOnly: false,
      );
      await command.run(onProgress: (_) {});
      expect((await command.load())!.unsupported, 0);
      final suggestions = await repo.listSuggestions();
      expect(suggestions, hasLength(15));
      for (var i = 0; i < messages.length; i++) {
        final item = suggestions.singleWhere(
          (s) => s.draft.amount.minorUnits == 345678 + (i + 1) * 21347,
        );
        expect(item.status, SuggestionStatus.pending);
        expect(item.draft.bank, 'اقتصاد نوین');
        expect(item.draft.sourceAddress, 'ENBANK');
        expect(item.draft.balance!.minorUnits, 45678901 + (i + 1) * 31973);
        expect(
          item.draft.direction,
          {0, 11}.contains(i)
              ? TransactionDirection.incoming
              : TransactionDirection.outgoing,
        );
        expect(item.draft.dateSource, TransactionDateSource.receipt);
        expect(item.extractedEvidence!.sourceDate, '4/${i + 3}');
        expect(item.extractedEvidence!.occurredAt, isNull);
        final replay = await InboxUseCases(repo).stageSms(
          rawText: messages[i].body,
          sourceKey: messages[i].sourceKey,
          sourceAddress: messages[i].address,
          importedAt: messages[i].receivedAt,
          currency: 'IRR',
        );
        expect(replay.id, item.id);
      }
      final originals = {
        for (final s in suggestions) s.id.value: s.extractedEvidence!.toJson(),
      };
      expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      repo = DriftInboxRepository(db);
      expect({
        for (final s in await repo.listSuggestions())
          s.id.value: s.extractedEvidence!.toJson(),
      }, originals);
      expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
    },
  );

  test('consented ingestion preserves bounded evidence, replay and confirmation across reopen', () async {
    final dir = await Directory.systemTemp.createTemp('evidence-sms-');
    final file = File('${dir.path}/state.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(() async {
      await db.close();
      await dir.delete(recursive: true);
    });
    var repo = DriftInboxRepository(db);
    var inbox = InboxUseCases(repo);
    const body =
        'برداشت از حساب: ****0123\nمبلغ: 12,501 تومان\nمانده: 80,000 ریال';
    final bodies = [
      body,
      '$body\nمبلغ: 20 ریال',
      body.replaceFirst('برداشت از', 'انتقال از'),
    ];
    final source = PagedSource([
      for (var i = 0; i < bodies.length; i++)
        SmsProviderRow(
          1000,
          i,
          AndroidSmsMessage(
            sourceKey: 'android-sms:$i',
            body: bodies[i],
            receivedAt: DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
          ),
        ),
    ]);
    var command = SmsIngestion(inbox, source);
    await expectLater(
      command.run(onProgress: (_) {}),
      throwsA(isA<ValidationError>()),
    );
    expect(source.reads, 0);
    await command.consent(
      from: DateTime.fromMillisecondsSinceEpoch(500),
      until: DateTime.fromMillisecondsSinceEpoch(1500),
      newOnly: false,
    );
    await command.run(onProgress: (_) {});
    expect((await command.load())!.unsupported, 1);
    expect(await repo.listSuggestions(), hasLength(2));
    final originals = {
      for (final s in await repo.listSuggestions())
        s.id.value: s.extractedEvidence!.toJson(),
    };
    expect(await DriftFinanceRepository(db).listEntries(), isEmpty);
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    repo = DriftInboxRepository(db);
    inbox = InboxUseCases(repo);
    command = SmsIngestion(inbox, source);
    await command.run(onProgress: (_) {});
    expect((await command.load())!.unsupported, 1);
    final suggestions = await repo.listSuggestions();
    expect({
      for (final s in suggestions) s.id.value: s.extractedEvidence!.toJson(),
    }, originals);
    final item = suggestions.singleWhere(
      (s) => !s.extractedEvidence!.isTransfer,
    );
    expect(item.draft.amount.minorUnits, 125010);
    expect(item.draft.dateSource, TransactionDateSource.receipt);
    expect(item.extractedEvidence!.sourceDate, isNull);
    expect(item.extractedEvidence!.sourceTime, isNull);
    final replay = await inbox.stageSms(
      rawText: body,
      sourceKey: 'android-sms:0',
      currency: 'IRR',
      importedAt: DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true),
    );
    expect(replay.id, item.id);
    final finance = DriftFinanceRepository(db);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'نمونه',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    // Staging and replay have no ledger effect. The UI separately presents
    // receipt-date acknowledgement before invoking explicit confirmation.
    expect(await finance.listEntries(), isEmpty);
    for (final suggestion in suggestions) {
      final old = suggestion.draft;
      final edited = await inbox.edit(
        suggestion,
        TransactionDraft(
          id: old.id,
          stagedImportId: old.stagedImportId,
          amount: old.amount,
          occurredAt: DateTime(2026, 10, 11, 18, 23),
          dateSource: TransactionDateSource.reviewer,
          type: 'expense',
          direction: TransactionDirection.outgoing,
          currencyEvidence: old.currencyEvidence,
        ),
      );
      if (suggestion.extractedEvidence!.isTransfer) {
        await expectLater(
          inbox.confirm(suggestion: edited, account: account, finance: finance),
          throwsA(isA<ValidationError>()),
        );
      } else {
        await expectLater(
          inbox.confirm(
            suggestion: suggestion,
            account: account,
            finance: finance,
          ),
          throwsA(isA<ValidationError>()),
        );
        await inbox.confirm(
          suggestion: edited,
          account: account,
          finance: finance,
        );
      }
    }
    final entries = await finance.listEntries();
    expect(entries, hasLength(1));
    expect(entries.single.amount.minorUnits, 125010);
    final snapshot = await sqliteBackupSnapshot(
      database: db,
      target: File('${dir.path}/snapshot.sqlite'),
      redact: true,
    );
    await db.close();
    final restored = File('${dir.path}/restored.sqlite');
    await restored.writeAsBytes(snapshot);
    db = AppDatabase.forTesting(NativeDatabase(restored));
    repo = DriftInboxRepository(db);
    expect({
      for (final s in await repo.listSuggestions())
        s.id.value: s.extractedEvidence!.toJson(),
    }, originals);
    expect((await repo.listImports()).every((s) => s.rawText.isEmpty), isTrue);
    expect(await DriftFinanceRepository(db).listEntries(), hasLength(1));
  });
}
