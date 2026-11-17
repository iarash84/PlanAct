import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/transaction_account_icon.dart';
import 'package:planact/features/finance/presentation/transaction_card.dart';

void main() {
  for (final dark in [false, true]) {
    for (final enlarged in [false, true]) {
      testWidgets('compact fixture ${dark ? 'dark' : 'light'} '
          '${enlarged ? '320dp 2x' : '400dp 1x'}', (tester) async {
        final width = enlarged ? 320.0 : 400.0;
        tester.view.physicalSize = Size(width, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب روزمره · ملت',
          currency: 'IRR',
          type: FinancialAccountType.bank,
          bank: IranianBank.mellat,
        );
        final entry = AccountEntry(
          id: StableId.generate(),
          accountId: account.id,
          type: AccountEntryType.expense,
          amount: const Money(minorUnits: 123456789, currency: 'IRR'),
          occurredAt: DateTime(2026, 11, 14, 18, 37),
        );
        var operations = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: TextScaler.linear(enlarged ? 2 : 1),
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: TransactionCard(
                      entry: entry,
                      label: 'هزینه',
                      amount: '۱۲۳,۴۵۶,۷۸۹ ریال',
                      operations: IconButton(
                        tooltip: 'عملیات تراکنش',
                        onPressed: () => operations++,
                        icon: const Icon(Icons.more_vert),
                      ),
                      children: [
                        const Text('۱۴۰۵/۰۸/۲۳ · ۱۸:۳۷'),
                        const Text('خریدهای خانه · خرید روزانه'),
                        Row(
                          children: [
                            TransactionAccountIcon(account: account),
                            const SizedBox(width: 8),
                            Expanded(child: Text(account.name)),
                          ],
                        ),
                        const Text('#خانه · #روزمره'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final card = find.byType(TransactionCard);
        debugPrint(
          'CARD_HEIGHT $width ${enlarged ? 2 : 1} dark=$dark: '
          '${tester.getSize(card).height}',
        );
        for (final text in [
          'هزینه',
          '۱۲۳,۴۵۶,۷۸۹ ریال',
          '۱۴۰۵/۰۸/۲۳ · ۱۸:۳۷',
          'خریدهای خانه · خرید روزانه',
          account.name,
          '#خانه · #روزمره',
        ]) {
          expect(find.text(text), findsOneWidget);
          final widget = tester.widget<Text>(find.text(text));
          expect(widget.maxLines, isNull);
          expect(widget.overflow, isNull);
          final rect = tester.getRect(find.text(text));
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
        }
        expect(
          tester.getSize(card).height,
          lessThanOrEqualTo(enlarged ? 956 : 296),
        );
        final frameFinder = find.descendant(
          of: find.byType(TransactionAccountIcon),
          matching: find.byKey(const ValueKey('account-identity-icon-frame')),
        );
        final frame = tester.widget<DecoratedBox>(
          find.descendant(of: frameFinder, matching: find.byType(DecoratedBox)),
        );
        final decoration = frame.decoration as BoxDecoration;
        expect(decoration.color, Colors.white);
        expect(decoration.borderRadius, isNotNull);
        expect(decoration.border, isNull);
        expect(find.byType(CircleBorder), findsNothing);
        final image = tester.widget<Image>(find.byType(Image));
        expect(image.fit, BoxFit.contain);
        expect(image.width, 28);
        expect(image.height, 28);
        expect(image.semanticLabel, contains('ملت'));
        final imageRect = tester.getRect(find.byType(Image));
        final frameRect = tester.getRect(frameFinder);
        expect(imageRect.left - frameRect.left, greaterThanOrEqualTo(6));
        expect(imageRect.top - frameRect.top, greaterThanOrEqualTo(6));
        expect(frameRect.width, 40);
        expect(frameRect.height, 40);
        final action = find.byType(IconButton);
        expect(tester.getSize(action).width, greaterThanOrEqualTo(48));
        expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
        await tester.tap(action);
        expect(operations, 1);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('header composes horizontally only when actual text fits', (
      tester,
    ) async {
      final entry = AccountEntry(
        id: StableId.generate(),
        accountId: StableId.generate(),
        type: AccountEntryType.expense,
        amount: const Money(minorUnits: 1200, currency: 'IRR'),
        occurredAt: DateTime(2026, 11, 14),
      );
      var opened = 0;
      for (final label in [
        'هزینه',
        'هزینهٔ ثبت‌شده · برگشت‌خورده؛ فقط تاریخچه',
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: PlanActTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 600,
                    child: TransactionCard(
                      entry: entry,
                      label: label,
                      amount: '۱,۲۰۰ ریال',
                      onTap: () => opened++,
                      children: const [Text('شرح کامل')],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final title = tester.getRect(find.text(label));
        final amount = tester.getRect(find.text('۱,۲۰۰ ریال'));
        if (label == 'هزینه') {
          expect((title.center.dy - amount.center.dy).abs(), lessThan(8));
          expect(amount.right, lessThan(title.left));
        } else {
          expect(amount.top, greaterThanOrEqualTo(title.bottom));
        }
        await tester.tap(find.text(label));
        expect(tester.takeException(), isNull);
      }
      expect(opened, 2);
    });
  }
}
