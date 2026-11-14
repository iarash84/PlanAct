import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/calendar/data/drift_calendar_transaction_reader.dart';
import 'package:planact/features/calendar/domain/calendar_visibility.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  test('calendar projects only durable explicit banks and direct tags after reopen', () async {
    final dir = await Directory.systemTemp.createTemp('calendar-metadata-');
    final file = File('${dir.path}/live.sqlite');
    var db = AppDatabase.forTesting(NativeDatabase(file));
    try {
      final finance = DriftFinanceRepository(db);
      final tags = DriftTagRepository(db);
      final bank = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب شخصی',
        currency: 'IRR',
        type: FinancialAccountType.bank,
        bank: IranianBank.mellat,
      );
      final unnamedBank = FinancialAccount(
        id: StableId.generate(),
        name: 'ملت',
        currency: 'IRR',
        type: FinancialAccountType.bank,
      );
      await finance.saveAccount(bank);
      await finance.saveAccount(unnamedBank);
      final group = StableId.generate();
      AccountEntry entry(
        FinancialAccount account,
        AccountEntryType type, {
        bool transfer = false,
      }) => AccountEntry(
        id: StableId.generate(),
        accountId: account.id,
        type: type,
        amount: Money(minorUnits: 12345, currency: 'IRR'),
        occurredAt: DateTime(2026, 11, 14, 14),
        transferGroupId: transfer ? group : null,
      );
      final expense = entry(unnamedBank, AccountEntryType.expense);
      final income = entry(bank, AccountEntryType.income);
      final outgoing = entry(
        bank,
        AccountEntryType.transferOut,
        transfer: true,
      );
      final incoming = entry(
        unnamedBank,
        AccountEntryType.transferIn,
        transfer: true,
      );
      for (final item in [expense, income, incoming, outgoing]) {
        await finance.saveEntry(item);
      }
      final shared = await tags.getOrCreate('مشترک');
      final otherLeg = await tags.getOrCreate('مقصد');
      await tags.getOrCreate('بی‌ارتباط');
      for (final item in [expense, incoming, outgoing]) {
        await tags.attach(
          recordId: item.id.value,
          tag: shared,
          type: TaggableType.accountEntry,
        );
      }
      await tags.attach(
        recordId: incoming.id.value,
        tag: otherLeg,
        type: TaggableType.accountEntry,
      );
      await db.close();
      db = AppDatabase.forTesting(NativeDatabase(file));
      final reader = DriftCalendarTransactionReader(db);
      final rows = await reader.loadRange(
        LocalDate(2026, 11, 14),
        LocalDate(2026, 11, 15),
        const CalendarVisibility(income: true, expense: true, transfers: true),
      );
      expect(rows, hasLength(3));
      final expenseRow = rows.singleWhere((r) => r.entry.id == expense.id);
      expect(expenseRow.accounts.single.bank, isNull);
      expect(expenseRow.accounts.single.name, 'ملت');
      expect(expenseRow.tags.map((t) => t.label), ['مشترک']);
      final incomeRow = rows.singleWhere((r) => r.entry.id == income.id);
      expect(incomeRow.accounts.single.bank, IranianBank.mellat);
      expect(incomeRow.tags, isEmpty);
      final transfer = rows.singleWhere((r) => r.entry.id == outgoing.id);
      expect(transfer.accounts.map((a) => a.id).toSet(), {
        bank.id,
        unnamedBank.id,
      });
      expect(transfer.tags.map((t) => t.label).toSet(), {'مشترک', 'مقصد'});
      expect(await DriftFinanceRepository(db).listEntries(), hasLength(4));
      expect(await tagsForReopened(db, expense.id.value), {shared.id});
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });
}

Future<Set<StableId>> tagsForReopened(AppDatabase db, String id) =>
    DriftTagRepository(db).tagsFor(id, TaggableType.accountEntry);
