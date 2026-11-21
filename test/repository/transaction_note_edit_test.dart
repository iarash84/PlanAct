import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/database/undo_journal.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';

void main() {
  late Directory directory;
  late File file;
  late AppDatabase database;
  late DriftFinanceRepository repository;
  late FinanceUseCases commands;
  late FinancialAccount account;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('note-edit-');
    file = File('${directory.path}/state.sqlite');
    database = AppDatabase.forTesting(NativeDatabase(file));
    repository = DriftFinanceRepository(database);
    commands = FinanceUseCases(repository);
    account = FinancialAccount(
      id: StableId.generate(),
      name: 'حساب',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await commands.createAccount(account);
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });
  Future<AccountEntry> record(AccountEntryType type) => commands.record(
    account: account,
    type: type,
    amount: const Money(minorUnits: 500, currency: 'IRR'),
    occurredAt: DateTime.utc(2026, 11, 1),
    note: 'خرید',
    category: 'عمومی',
  );
  Future<AccountEntry> edit(
    AccountEntry original,
    String? note, {
    int? amount,
  }) => commands.correctEntry(
    original: original,
    account: account,
    type: original.type,
    amount: amount == null
        ? original.amount
        : Money(minorUnits: amount, currency: 'IRR'),
    occurredAt: original.occurredAt,
    note: note,
    category: original.category,
  );

  for (final type in [AccountEntryType.income, AccountEntryType.expense]) {
    test(
      '${type.name} note edit preserves identity and balance through reopen and snapshot',
      () async {
        final original = await record(type);
        final edited = await edit(original, 'خرید مواد غذایی');
        expect(edited.id, original.id);
        Future<void> verify() async {
          final entries = await repository.listEntries();
          expect(entries, hasLength(1));
          final retained = entries.single;
          expect(retained.id, original.id);
          expect(retained.note, 'خرید مواد غذایی');
          expect(retained.noteRevision, 1);
          expect(retained.source, original.source);
          expect(retained.referenceId, original.referenceId);
          expect(retained.category, original.category);
          expect(retained.occurredAt, original.occurredAt);
          expect(
            (await commands.balance(account)).minorUnits,
            type == AccountEntryType.income ? 500 : -500,
          );
          final event = await UndoJournal(database)
              .latest('transaction-note:${original.id.value}');
          expect(event!['before'], {'note': 'خرید', 'revision': 0});
          expect(event['after'], {'note': 'خرید مواد غذایی', 'revision': 1});
        }

        await verify();
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftFinanceRepository(database);
        commands = FinanceUseCases(repository);
        await verify();
        final bytes = await sqliteBackupSnapshot(
          database: database,
          target: File('${directory.path}/snapshot.sqlite'),
          redact: true,
        );
        await database.close();
        await file.writeAsBytes(bytes, flush: true);
        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftFinanceRepository(database);
        commands = FinanceUseCases(repository);
        await verify();
      },
    );
  }
  test('no-op does not append; clear note works; stale edits including ABA are rejected', () async {
    final original = await record(AccountEntryType.expense);
    await edit(original, original.note);
    expect(
      await UndoJournal(database)
          .latest('transaction-note:${original.id.value}'),
      isNull,
    );
    final cleared = await edit(original, null);
    expect(cleared.note, isNull);
    await expectLater(edit(original, 'stale'), throwsA(isA<ValidationError>()));
    await edit(cleared, original.note);
    await expectLater(
      edit(original, 'stale after ABA'),
      throwsA(isA<ValidationError>()),
    );
    await expectLater(
      edit(original, 'stale financial', amount: 900),
      throwsA(isA<ValidationError>()),
    );
    expect(await repository.listEntries(), hasLength(1));
  });
  test('financial changes still reverse and replace; reversed original cannot edit note', () async {
    final original = await record(AccountEntryType.expense);
    await edit(original, 'new amount and note', amount: 700);
    expect(await repository.listEntries(), hasLength(3));
    expect((await commands.balance(account)).minorUnits, -700);
    await expectLater(
      edit(original, 'invalid'),
      throwsA(isA<ValidationError>()),
    );
  });
  test('history failure rolls back note and revision together', () async {
    final original = await record(AccountEntryType.expense);
    await database.customStatement(
      "CREATE TRIGGER reject_note_history BEFORE INSERT ON schema_metadata WHEN NEW.key LIKE 'undo_event_v1:%' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
    );
    await expectLater(edit(original, 'must roll back'), throwsA(anything));
    final fresh = (await repository.listEntries()).single;
    expect(fresh.note, original.note);
    expect(fresh.noteRevision, 0);
  });
}
