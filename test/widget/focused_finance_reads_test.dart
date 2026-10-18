import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

import 'global_search_test.dart' show settleIo;

class _CountingTags extends DriftTagRepository {
  _CountingTags(super.database);
  final reads = <String>[];
  @override
  Future<Set<StableId>> tagsFor(String recordId, TaggableType type) {
    reads.add(recordId);
    return super.tagsFor(recordId, type);
  }
}

void main() {
  for (final kind in FinanceRecordKind.values) {
    testWidgets(
      'focused $kind bounds tag reads with 1000 entries and retains ledger semantics',
      (tester) async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        final finance = DriftFinanceRepository(db);
        final tags = _CountingTags(db);
        FinancialAccount account(String name) => FinancialAccount(
          id: StableId.generate(),
          name: name,
          currency: 'IRR',
          type: FinancialAccountType.cash,
        );
        final selected = account('حساب انتخابی');
        final other = account('حساب دیگر');
        await finance.saveAccount(selected);
        await finance.saveAccount(other);
        final original = AccountEntry(
          id: StableId.generate(),
          accountId: selected.id,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 700, currency: 'IRR'),
          occurredAt: DateTime.utc(2026, 10, 17),
          note: 'تراکنش انتخابی',
        );
        await db.transaction(() async {
          for (var i = 0; i < 998; i++) {
            await finance.saveEntry(
              AccountEntry(
                id: StableId.generate(),
                accountId: i.isEven ? selected.id : other.id,
                type: AccountEntryType.expense,
                amount: const Money(minorUnits: 100, currency: 'IRR'),
                occurredAt: DateTime.utc(2026, 10, 16),
              ),
            );
          }
          await finance.saveEntry(original);
          await finance.reverseEntry(
            expected: original,
            accountId: selected.id,
            occurredAt: DateTime.utc(2026, 10, 18),
          );
        });
        final tag = await tags.getOrCreate('خانه');
        await tags.attach(
          recordId: original.id.value,
          tag: tag,
          type: TaggableType.accountEntry,
        );
        final before = (await db.select(db.accountEntries).get())
            .map((row) => row.toJson())
            .toList();
        final key = GlobalKey<FinancePageState>();
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('fa'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: FinancePage(
              key: key,
              repository: finance,
              tagRepository: tags,
              focusedKind: kind,
              focusedRecordId: kind == FinanceRecordKind.account
                  ? selected.id.value
                  : original.id.value,
            ),
          ),
        );
        // Query-count evidence, not a device latency benchmark.
        for (var n = 0; n < 60; n++) {
          await settleIo(tester);
          if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
        }
        expect(find.byType(CircularProgressIndicator), findsNothing);
        final expectedReads = kind == FinanceRecordKind.account
            ? <String>[]
            : [original.id.value];
        expect(tags.reads, expectedReads);
        if (kind == FinanceRecordKind.account) {
          expect(
            find.text(
              PersianMoneyText.money(
                const Money(minorUnits: -49900, currency: 'IRR'),
              ),
            ),
            findsOneWidget,
          );
        } else {
          expect(find.textContaining('#خانه'), findsOneWidget);
          await tester.tap(
            find.byKey(ValueKey('entry-menu:${original.id.value}')),
          );
          await tester.pumpAndSettle();
          expect(find.text('برچسب‌های تراکنش'), findsOneWidget);
          expect(find.text('حذف امن تراکنش'), findsNothing);
          expect(find.text('اصلاح تراکنش'), findsNothing);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
        }
        await tester.runAsync(() => key.currentState!.refreshData());
        await tester.pumpAndSettle();
        expect(tags.reads, [...expectedReads, ...expectedReads]);
        expect(
          (await db.select(db.accountEntries).get())
              .map((row) => row.toJson())
              .toList(),
          before,
        );
        expect(await finance.listEntries(), hasLength(1000));
      },
    );
  }
}
