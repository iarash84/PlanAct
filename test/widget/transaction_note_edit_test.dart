import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

class _RetryNotes extends InMemoryFinanceRepository {
  bool fail = true;
  @override
  Future<AccountEntry> editEntryNote(
    AccountEntry expected,
    String? note,
  ) async {
    if (fail) throw StateError('unavailable');
    return super.editEntryNote(expected, note);
  }
}

void main() {
  for (final retry in [false, true]) {
    testWidgets(
      'note-only correction skips financial confirmation; retry=$retry',
      (tester) async {
        final repository = _RetryNotes()..fail = retry;
        final commands = FinanceUseCases(repository);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب',
          currency: 'IRR',
          type: FinancialAccountType.bank,
        );
        await commands.createAccount(account);
        final original = await commands.record(
          account: account,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 500, currency: 'IRR'),
          occurredAt: DateTime.utc(2026, 11, 1),
          note: 'خرید',
        );
        var refreshes = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: FinancePage(
              repository: repository,
              onDataChanged: () async {
                refreshes++;
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final menu = find.byKey(ValueKey('entry-menu:${original.id.value}'));
        await tester.ensureVisible(menu);
        await tester.pumpAndSettle();
        await tester.tap(menu);
        await tester.pumpAndSettle();
        await tester.tap(find.text('اصلاح تراکنش'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'شرح هزینه'),
          'خرید مواد غذایی',
        );
        await tester.tap(find.text('ثبت'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        if (retry) {
          expect(find.text('خرید مواد غذایی'), findsOneWidget);
          expect((await repository.listEntries()).single.note, 'خرید');
          repository.fail = false;
          await tester.tap(find.text('ثبت'));
          await tester.pumpAndSettle();
        }
        final entries = await repository.listEntries();
        expect(entries, hasLength(1));
        expect(entries.single.id, original.id);
        expect(entries.single.note, 'خرید مواد غذایی');
        expect(refreshes, 1);
        expect((await commands.balance(account)).minorUnits, -500);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
