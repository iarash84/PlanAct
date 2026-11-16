import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/data/bank_balance_store.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';

import '../fixtures/real_bank_sms.dart';

void main() {
  test('confirmation preserves incomplete independent balance evidence and reversal does not invalidate it', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final finance = DriftFinanceRepository(db);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'بانک',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    final inbox = InboxUseCases(DriftInboxRepository(db));
    final suggestion = await inbox.stageSms(
      rawText: 'بانک رفاه\nواریز مبلغ 100 ریال\nمانده: 25',
      sourceKey: 'incomplete-balance',
      currency: 'IRR',
      importedAt: DateTime.utc(2026, 11, 1),
    );
    expect(suggestion.extractedEvidence!.reportedBalanceAmount, 25);
    expect(suggestion.extractedEvidence!.reportedBalanceUnit, isNull);
    expect(suggestion.extractedEvidence!.occurredAt, isNull);
    final entry = await inbox.confirm(
      suggestion: suggestion,
      account: account,
      finance: finance,
    );
    final before = await finance.bankBalance(account.id.value);
    final observation = before.observations.single;
    expect(observation.sourceAmount, 25);
    expect(observation.sourceUnit, isNull);
    expect(observation.irr, isNull);
    expect(observation.transactionTime, isNull);
    expect(before.canReconcile, isFalse);
    await FinanceUseCases(finance).voidEntry(
      original: entry,
      account: account,
      occurredAt: DateTime.utc(2026, 11, 2),
    );
    final after = (await finance.bankBalance(account.id.value))
        .observations
        .single;
    expect(after.toJson(), observation.toJson());
    expect(after.active, isTrue);
  });

  test('reverse confirmation order, cold reopen and snapshot retain source balance independently', () async {
    final dir = await Directory.systemTemp.createTemp('bank-balance-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/live.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    var finance = DriftFinanceRepository(db);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'بانک',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await finance.saveAccount(account);
    final inbox = InboxUseCases(DriftInboxRepository(db));
    for (final i in [0, 1]) {
      final suggestion = await inbox.stageSms(
        rawText: realBankSms[i],
        sourceKey: 'bank:$i',
        currency: 'IRR',
        importedAt: DateTime.utc(2026, 11, 1),
      );
      expect(suggestion.extractedEvidence!.reportedBalanceUnit, isNotNull);
      await inbox.confirm(
        suggestion: suggestion,
        account: account,
        finance: finance,
      );
    }
    final before = await finance.bankBalance(account.id.value);
    expect(before.latest!.irr, 12345678);
    expect(before.ambiguous, isFalse);
    expect(
      rebuildBalance(account, await finance.listEntries()).minorUnits,
      119360000,
    );
    expect(before.ledgerAtReport, 119360000);
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    finance = DriftFinanceRepository(db);
    expect((await finance.bankBalance(account.id.value)).token, before.token);
    final adjustment = await finance.reconcileBankBalance(
      before,
      BankReconciliationReason.unknownAdjustment,
    );
    expect(adjustment.type, AccountEntryType.adjustment);
    expect(adjustment.amount.minorUnits, 12345678 - 119360000);
    await expectLater(
      finance.reconcileBankBalance(
        before,
        BankReconciliationReason.unknownAdjustment,
      ),
      throwsA(anything),
    );
    final late = AccountEntry(
      id: StableId.generate(),
      accountId: account.id,
      type: AccountEntryType.expense,
      amount: Money(minorUnits: 100, currency: 'IRR'),
      occurredAt: DateTime(2026, 1, 1),
    );
    await expectLater(finance.saveEntry(late), throwsA(anything));
    final bytes = await sqliteBackupSnapshot(
      database: db,
      target: File('${dir.path}/snapshot.sqlite'),
      redact: true,
    );
    final token = (await finance.bankBalance(account.id.value)).token;
    await db.close();
    await file.writeAsBytes(bytes);
    db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    finance = DriftFinanceRepository(db);
    expect((await finance.bankBalance(account.id.value)).token, token);
    await FinanceUseCases(finance).voidEntry(
      original: adjustment,
      account: account,
      occurredAt: DateTime.utc(2026, 11, 2),
    );
    await finance.saveEntry(late);
    final corrected = await finance.bankBalance(account.id.value);
    expect(corrected.activeReconciliation, isFalse);
    expect(corrected.ledgerAtReport, 119359900);
    final fee = await finance.reconcileBankBalance(
      corrected,
      BankReconciliationReason.knownFee,
    );
    expect(fee.type, AccountEntryType.expense);
    expect(fee.amount.minorUnits, 119359900 - 12345678);
  });

  test('equal and unknown transaction times block reconciliation without receipt ordering', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = DriftFinanceRepository(db);
    final account = FinancialAccount(
      id: StableId.generate(),
      name: 'بانک',
      currency: 'IRR',
      type: FinancialAccountType.bank,
    );
    await repo.saveAccount(account);
    final store = BankBalanceStore(db);
    for (var i = 0; i < 3; i++) {
      await store.observe(
        BankBalanceObservation(
          id: 'observation-$i',
          entryId: 'entry-$i',
          accountId: account.id.value,
          irr: i,
          sourceAmount: i,
          sourceUnit: 'rial',
          transactionTime: i == 2 ? null : DateTime.utc(2026, 1, 1),
        ),
      );
      final snapshot = await repo.bankBalance(account.id.value);
      expect(snapshot.ambiguous, i > 0);
      if (i > 0) {
        expect(snapshot.canReconcile, isFalse);
        await expectLater(
          repo.reconcileBankBalance(
            snapshot,
            BankReconciliationReason.unknownAdjustment,
          ),
          throwsA(anything),
        );
      }
    }
    expect(await repo.listEntries(), isEmpty);
  });
}
