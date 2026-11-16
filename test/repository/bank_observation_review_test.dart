import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:planact/features/finance/data/bank_balance_store.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';
import 'package:planact/features/finance/domain/finance.dart';

FinancialAccount account() => FinancialAccount(
  id: StableId.generate(),
  name: 'بانک',
  currency: 'IRR',
  type: FinancialAccountType.bank,
);
BankBalanceObservation source(String accountId, {DateTime? time}) =>
    BankBalanceObservation(
      id: 'sms',
      entryId: 'entry',
      accountId: accountId,
      irr: null,
      sourceAmount: 10,
      sourceUnit: null,
      transactionTime: time,
    );
Future<void> review(
  DriftFinanceRepository repo,
  BankBalanceObservation expected, {
  String? accountId,
  int amount = 0,
  String? unit = 'toman',
  DateTime? time,
  bool active = true,
}) => repo.reviewBankObservation(
  expected: expected,
  accountId: accountId ?? expected.accountId,
  sourceAmount: amount,
  sourceUnit: unit,
  transactionTime: time,
  active: active,
);

void main() {
  test('legacy original, review, invalidation and reactivation survive cold reopen and backup without ledger effects', () async {
    final directory = await Directory.systemTemp.createTemp('bank-review');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/live.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    var repo = DriftFinanceRepository(db);
    final first = account();
    final second = account();
    await repo.saveAccount(first);
    await repo.saveAccount(second);
    final original = source(first.id.value);
    // Legacy payloads have no review revision/active fields.
    final legacy = original.toJson()
      ..remove('revision')
      ..remove('active');
    await db.writeMetadata('bank_observation_v1:sms', jsonEncode(legacy));
    final missing = await repo.bankBalance(first.id.value);
    expect(missing.ambiguous, isTrue);
    expect(missing.latest, isNull);
    expect(missing.observations.single.revision, 0);
    final time = DateTime.utc(2026, 1, 1, 12);
    await review(
      repo,
      missing.observations.single,
      time: time,
      amount: 123,
      accountId: second.id.value,
    );
    expect((await repo.bankBalance(first.id.value)).observations, isEmpty);
    var snapshot = await repo.bankBalance(second.id.value);
    expect(snapshot.latest!.irr, 1230);
    expect(snapshot.latest!.revision, 1);
    await review(repo, snapshot.observations.single, active: false, time: time);
    snapshot = await repo.bankBalance(second.id.value);
    expect(snapshot.latest, isNull);
    expect(snapshot.ambiguous, isFalse);
    expect(snapshot.observations.single.active, isFalse);
    await review(repo, snapshot.observations.single, time: time);
    snapshot = await repo.bankBalance(second.id.value);
    expect(snapshot.latest!.irr, 0);
    expect(snapshot.latest!.revision, 3);
    expect(await repo.listEntries(), isEmpty);
    final retained = await db.readMetadata('bank_observation_v1:sms');
    expect(jsonDecode(retained!), legacy);
    final before = snapshot.token;
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase(file));
    repo = DriftFinanceRepository(db);
    expect((await repo.bankBalance(second.id.value)).token, before);
    final bytes = await sqliteBackupSnapshot(
      database: db,
      target: File('${directory.path}/snapshot.sqlite'),
      redact: true,
    );
    await db.close();
    final sql = sqlite3.open(file.path);
    final schema = SqliteBackupStorage.schema(sql);
    sql.close();
    await SqliteBackupStorage(
      live: file,
      schemaVersion: db.schemaVersion,
      expectedSchema: schema,
      snapshot: file.readAsBytes,
      closeLive: () async {},
    ).validatePayload(bytes);
    final restoredFile = File('${directory.path}/restored.sqlite');
    await restoredFile.writeAsBytes(bytes);
    db = AppDatabase.forTesting(NativeDatabase(restoredFile));
    addTearDown(db.close);
    repo = DriftFinanceRepository(db);
    expect((await repo.bankBalance(second.id.value)).token, before);
    expect(
      jsonDecode((await db.readMetadata('bank_observation_v1:sms'))!),
      legacy,
    );
    expect(
      await db.readMetadata('bank_observation_review_v1:sms:1'),
      isNotNull,
    );
    expect(
      await db.readMetadata('bank_observation_review_v1:sms:3'),
      isNotNull,
    );
    expect(await repo.listEntries(), isEmpty);
  });

  test(
    'fresh revision rejects replay, overflow and active dependency atomically',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final repo = DriftFinanceRepository(db);
      final owner = account();
      await repo.saveAccount(owner);
      final original = source(owner.id.value);
      await BankBalanceStore(db).observe(original);
      final time = DateTime.utc(2026, 1, 1);
      await review(repo, original, time: time, amount: 50);
      final current = (await repo.bankBalance(owner.id.value))
          .observations
          .single;
      await expectLater(review(repo, original, time: time), throwsA(anything));
      await expectLater(
        review(repo, current, amount: 9223372036854775807, time: time),
        throwsA(anything),
      );
      expect(
        (await repo.bankBalance(owner.id.value)).observations.single.revision,
        1,
      );
      final reconciliation = await repo.reconcileBankBalance(
        await repo.bankBalance(owner.id.value),
        BankReconciliationReason.unknownAdjustment,
      );
      await expectLater(
        review(repo, current, active: false),
        throwsA(anything),
      );
      expect(
        (await repo.bankBalance(owner.id.value)).observations.single.revision,
        1,
      );
      expect((await repo.listEntries()).single.id, reconciliation.id);
      expect(await db.readMetadata('bank_observation_review_v1:sms:2'), isNull);
      await expectLater(
        BankBalanceStore(db).observe(
          BankBalanceObservation(
            id: original.id,
            entryId: original.entryId,
            accountId: original.accountId,
            irr: 0,
            sourceAmount: 0,
            sourceUnit: 'rial',
            transactionTime: time,
          ),
        ),
        throwsA(anything),
      );
    },
  );

  test(
    'two database writers cannot both append the same expected revision',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bank-review-race',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/race.sqlite');
      final db1 = AppDatabase.forTesting(NativeDatabase(file));
      final db2 = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db1.close);
      addTearDown(db2.close);
      final repo1 = DriftFinanceRepository(db1);
      final repo2 = DriftFinanceRepository(db2);
      final owner = account();
      await repo1.saveAccount(owner);
      final original = source(owner.id.value);
      await BankBalanceStore(db1).observe(original);
      await repo2.bankBalance(owner.id.value);
      Future<bool> attempt(DriftFinanceRepository repo) async {
        try {
          await review(repo, original, time: DateTime.utc(2026, 1, 1));
          return true;
        } catch (_) {
          return false;
        }
      }

      final results = await Future.wait([attempt(repo1), attempt(repo2)]);
      expect(results.where((ok) => ok), hasLength(1));
      expect(
        (await repo1.bankBalance(owner.id.value)).observations.single.revision,
        1,
      );
      expect(await repo1.listEntries(), isEmpty);
    },
  );
}
