import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
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
  late FinancialAccount originalAccount;
  late FinancialAccount destination;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('account-correction-');
    file = File('${directory.path}/state.sqlite');
    database = AppDatabase.forTesting(NativeDatabase(file));
    repository = DriftFinanceRepository(database);
    commands = FinanceUseCases(repository);
    originalAccount = FinancialAccount(
      id: StableId.generate(),
      name: 'ملی',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    destination = FinancialAccount(
      id: StableId.generate(),
      name: 'ملت',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await commands.createAccount(originalAccount);
    await commands.createAccount(destination);
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Future<AccountEntry> record(AccountEntryType type) => commands.record(
    account: originalAccount,
    type: type,
    amount: const Money(minorUnits: 500, currency: 'IRR'),
    occurredAt: DateTime.utc(2026, 11, 1),
    note: 'source note',
  );
  Future<AccountEntry> correct(AccountEntry original) => commands.correctEntry(
    original: original,
    account: destination,
    type: original.type,
    amount: const Money(minorUnits: 700, currency: 'IRR'),
    occurredAt: original.occurredAt,
    note: original.note,
  );

  for (final type in [AccountEntryType.income, AccountEntryType.expense]) {
    test(
      '${type.name} correction changes account atomically and survives reopen and snapshot',
      () async {
        final original = await record(type);
        final corrected = await correct(original);
        Future<void> verify() async {
          final entries = await repository.listEntries();
          expect(entries, hasLength(3));
          final retained = entries.singleWhere((e) => e.id == original.id);
          expect(retained.accountId, originalAccount.id);
          expect(retained.amount, original.amount);
          expect(retained.note, original.note);
          final reversal = entries.singleWhere(
            (e) => e.type == AccountEntryType.reversal,
          );
          expect(reversal.accountId, originalAccount.id);
          expect(reversal.signedAmount, -original.signedAmount);
          expect(corrected.referenceId, original.id.value);
          expect(corrected.accountId, destination.id);
          expect(entries.every((e) => e.transferGroupId == null), isTrue);
          expect((await commands.balance(originalAccount)).minorUnits, 0);
          expect(
            (await commands.balance(destination)).minorUnits,
            type == AccountEntryType.income ? 700 : -700,
          );
          await expectLater(correct(original), throwsA(isA<ValidationError>()));
        }

        await verify();
        await database.close();
        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftFinanceRepository(database);
        commands = FinanceUseCases(repository);
        await verify();
        final snapshot = await sqliteBackupSnapshot(
          database: database,
          target: File('${directory.path}/snapshot.sqlite'),
          redact: true,
        );
        await database.close();
        await file.writeAsBytes(snapshot, flush: true);
        database = AppDatabase.forTesting(NativeDatabase(file));
        repository = DriftFinanceRepository(database);
        commands = FinanceUseCases(repository);
        await verify();
      },
    );
  }

  test(
    'fresh destination archive rejects a stale selected account without writes',
    () async {
      final original = await record(AccountEntryType.expense);
      await commands.archive(destination);
      await expectLater(correct(original), throwsA(isA<ValidationError>()));
      expect(await repository.listEntries(), hasLength(1));
      expect((await commands.balance(originalAccount)).minorUnits, -500);
    },
  );

  test(
    'missing destination and mismatched currency are rejected without writes',
    () async {
      final original = await record(AccountEntryType.income);
      await commands.deleteAccount(destination.id);
      await expectLater(correct(original), throwsA(isA<ValidationError>()));
      expect(await repository.listEntries(), hasLength(1));
      destination = FinancialAccount(
        id: StableId.generate(),
        name: 'USD',
        currency: 'USD',
        type: FinancialAccountType.bank,
      );
      await commands.createAccount(destination);
      await expectLater(
        commands.correctEntry(
          original: original,
          account: destination,
          type: original.type,
          amount: const Money(minorUnits: 700, currency: 'USD'),
          occurredAt: original.occurredAt,
        ),
        throwsA(isA<ValidationError>()),
      );
      expect(await repository.listEntries(), hasLength(1));
    },
  );

  test('second insert failure rolls back reversal and permits retry', () async {
    final original = await record(AccountEntryType.expense);
    await database.customStatement('''
      CREATE TRIGGER reject_corrected BEFORE INSERT ON account_entries
      WHEN NEW.account_id = '${destination.id.value}'
      BEGIN SELECT RAISE(ABORT, 'synthetic failure'); END
    ''');
    await expectLater(correct(original), throwsA(anything));
    expect(await repository.listEntries(), hasLength(1));
    expect((await commands.balance(originalAccount)).minorUnits, -500);
    await database.customStatement('DROP TRIGGER reject_corrected');
    await correct(original);
    expect(await repository.listEntries(), hasLength(3));
  });
}
