import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/account_identifiers.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory directory;
  late File live;
  late db.AppDatabase database;
  late DriftFinanceRepository repository;
  FinancialAccount account({
    String name = 'حساب ملی',
    AccountIdentifiers identifiers = AccountIdentifiers.empty,
    StableId? id,
  }) => FinancialAccount(
    id: id ?? StableId.generate(),
    name: name,
    currency: 'IRR',
    type: FinancialAccountType.bank,
    identifiers: identifiers,
  );
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('planact-account-');
    live = File('${directory.path}/live.sqlite');
    database = db.AppDatabase(NativeDatabase(live));
    repository = DriftFinanceRepository(database);
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('legacy absent metadata, atomic create, file reopen and exact validated restore', () async {
    final legacy = account();
    await database
        .into(database.financialAccounts)
        .insert(
          db.FinancialAccountsCompanion.insert(
            id: legacy.id.value,
            name: legacy.name,
            currency: 'IRR',
            type: 0,
            status: 0,
          ),
        );
    expect(
      (await repository.listAccounts()).single.identifiers,
      AccountIdentifiers.empty,
    );
    expect((await repository.listAccounts()).single.bank, isNull);
    final identifiers = AccountIdentifiers(
      cardNumber: '0000000000000018',
      iban: 'IR820540102680020817909002',
      accountNumber: '000123',
    );
    final created = account(identifiers: identifiers);
    await FinanceUseCases(repository).createAccount(
      created,
      openingBalance: const Money(minorUnits: -101, currency: 'IRR'),
    );
    final snapshot = await sqliteBackupSnapshot(
      database: database,
      target: File('${directory.path}/snapshot.sqlite'),
      redact: true,
    );
    await database.close();
    database = db.AppDatabase(NativeDatabase(live));
    repository = DriftFinanceRepository(database);
    expect((await repository.listAccounts()).last.identifiers, identifiers);
    expect(
      await FinanceUseCases(repository).balance(created),
      const Money(minorUnits: -101, currency: 'IRR'),
    );
    await database.close();
    final sql = sqlite3.open(live.path);
    final schema = SqliteBackupStorage.schema(sql);
    sql.close();
    final storage = SqliteBackupStorage(
      live: live,
      schemaVersion: 19,
      expectedSchema: schema,
      snapshot: live.readAsBytes,
      closeLive: () async {},
    );
    await storage.validatePayload(snapshot);
    await storage.writeTemporary(snapshot);
    await storage.flushTemporary();
    await storage.replaceTemporary();
    database = db.AppDatabase(NativeDatabase(live));
    repository = DriftFinanceRepository(database);
    final restored = (await repository.listAccounts()).firstWhere(
      (a) => a.id == created.id,
    );
    expect(restored.identifiers, identifiers);
    expect((await repository.listEntries()).single.amount.minorUnits, -101);
    expect(database.schemaVersion, 19);
  });

  test('fresh admission preserves concurrent status/currency and ledger; stale edit rejects', () async {
    final original = account(
      identifiers: AccountIdentifiers(accountNumber: '000123'),
    );
    final commands = FinanceUseCases(repository);
    await commands.createAccount(
      original,
      openingBalance: const Money(minorUnits: 123, currency: 'IRR'),
    );
    await commands.archive(original);
    final replacement = FinancialAccount(
      id: original.id,
      name: 'نام جدید',
      currency: 'USD',
      type: FinancialAccountType.cash,
      bank: IranianBank.saman,
      identifiers: AccountIdentifiers.empty,
    );
    await commands.editAccount(original: original, replacement: replacement);
    var fresh = (await repository.listAccounts()).single;
    expect(fresh.currency, 'IRR');
    expect(fresh.status, FinancialAccountStatus.archived);
    expect(fresh.identifiers, AccountIdentifiers.empty);
    expect(fresh.bank, IranianBank.saman);
    await expectLater(
      commands.editAccount(original: original, replacement: replacement),
      throwsException,
    );
    await commands.restore(original);
    fresh = (await repository.listAccounts()).single;
    expect(fresh.name, 'نام جدید');
    expect(fresh.bank, IranianBank.saman);
    expect(fresh.status, FinancialAccountStatus.active);
    expect((await repository.listEntries()).single.amount.minorUnits, 123);
    expect(
      await commands.balance(fresh),
      const Money(minorUnits: 123, currency: 'IRR'),
    );
  });

  test(
    'metadata write failures rollback account create/opening and edit row',
    () async {
      await database.writeMetadata('initialize', 'yes');
      await database.customStatement(
        "CREATE TRIGGER fail_account_metadata BEFORE INSERT ON schema_metadata WHEN NEW.key LIKE 'account_identifiers_v1:%' BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      final original = account();
      await expectLater(
        FinanceUseCases(repository).createAccount(
          original,
          openingBalance: const Money(minorUnits: 1, currency: 'IRR'),
        ),
        throwsException,
      );
      expect(await repository.listAccounts(), isEmpty);
      expect(await repository.listEntries(), isEmpty);
      await database.customStatement('DROP TRIGGER fail_account_metadata');
      await repository.createAccount(original);
      await database.customStatement(
        "CREATE TRIGGER fail_account_metadata BEFORE INSERT ON schema_metadata WHEN NEW.key LIKE 'account_identifiers_v1:%' BEGIN SELECT RAISE(ABORT, 'injected'); END",
      );
      await expectLater(
        repository.editAccount(
          original: original,
          replacement: original.update(name: 'تغییر'),
        ),
        throwsException,
      );
      expect((await repository.listAccounts()).single.name, original.name);
    },
  );
}
