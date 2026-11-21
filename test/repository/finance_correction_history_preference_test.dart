import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/transaction_history.dart';

void main() {
  test(
    'preference and complete chain survive cold reopen and backup snapshot',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'finance-history-',
      );
      final file = File('${directory.path}/state.sqlite');
      var database = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(() async {
        await database.close();
        await directory.delete(recursive: true);
      });
      var repository = DriftFinanceRepository(database);
      var commands = FinanceUseCases(repository);
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'نقدی',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      await commands.createAccount(account);
      expect(
        await AppSettings(database).readShowTransactionCorrectionHistory(),
        isFalse,
      );
      final original = await commands.record(
        account: account,
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 100, currency: 'IRR'),
        occurredAt: DateTime.utc(2026, 11),
      );
      Future<AccountEntry> correct(AccountEntry entry, int amount) =>
          commands.correctEntry(
            original: entry,
            account: account,
            type: entry.type,
            amount: Money(minorUnits: amount, currency: 'IRR'),
            occurredAt: entry.occurredAt,
          );
      final intermediate = await correct(original, 200);
      final current = await correct(intermediate, 300);
      Future<void> verify() async {
        final entries = await repository.listEntries();
        expect(entries, hasLength(5));
        expect(
          entries
              .where((e) => showInFinanceTransactionList(e))
              .map((e) => e.id),
          [current.id],
        );
        expect(
          entries.where(
            (e) => showInFinanceTransactionList(e, showCorrectionHistory: true),
          ),
          hasLength(5),
        );
        expect(
          entries.firstWhere((e) => e.id == current.id).history!.chain,
          hasLength(5),
        );
        expect((await commands.balance(account)).minorUnits, -300);
        expect(
          await AppSettings(database).readShowTransactionCorrectionHistory(),
          isTrue,
        );
      }

      await AppSettings(database).writeShowTransactionCorrectionHistory(true);
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
      await commands.voidEntry(
        original: (await repository.listEntries()).firstWhere(
          (e) => e.id == current.id,
        ),
        account: account,
      );
      final cancelled = await repository.listEntries();
      final visible = cancelled
          .where((e) => showInFinanceTransactionList(e))
          .toList();
      expect(visible, hasLength(1));
      expect(
        visible.single.history!.role.reversalPurpose,
        ReversalPurpose.cancellation,
      );
      expect((await commands.balance(account)).minorUnits, 0);
      expect(cancelled.first.history!.chain, hasLength(6));
      await AppSettings(database).writeShowTransactionCorrectionHistory(false);
      await database.customStatement(
        "CREATE TRIGGER reject_preference BEFORE INSERT ON schema_metadata WHEN NEW.key = 'finance_correction_history_v1' BEGIN SELECT RAISE(ABORT, 'test failure'); END",
      );
      await expectLater(
        AppSettings(database).writeShowTransactionCorrectionHistory(true),
        throwsA(anything),
      );
      expect(
        await AppSettings(database).readShowTransactionCorrectionHistory(),
        isFalse,
      );
    },
  );

  test(
    'unknown legacy and ordinary cancellation stay visible without inference',
    () {
      final account = StableId.generate();
      AccountEntry entry(AccountEntryType type, {String? reference}) =>
          AccountEntry(
            id: StableId.generate(),
            accountId: account,
            type: type,
            amount: const Money(minorUnits: 100, currency: 'IRR'),
            occurredAt: DateTime.utc(2026),
            referenceId: reference,
          );
      final original = entry(AccountEntryType.expense);
      final reversal = entry(
        AccountEntryType.reversal,
        reference: original.id.value,
      );
      final legacy = entry(
        AccountEntryType.expense,
        reference: original.id.value,
      );
      final unknown = projectTransactionHistory([
        original,
        reversal,
        legacy,
      ], []);
      expect(
        unknown.where((e) => showInFinanceTransactionList(e)),
        hasLength(3),
      );
      final cancellation = projectTransactionHistory(
        [original, reversal],
        [
          FinanceHistoryOperation(
            before: [original.id.value],
            after: [reversal.id.value],
          ),
        ],
      );
      expect(
        cancellation.where((e) => showInFinanceTransactionList(e)),
        hasLength(2),
      );
    },
  );
}
