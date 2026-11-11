import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/today/application/attention_engine.dart';
import 'package:planact/features/today/presentation/today_page.dart';

void main() {
  final date = DateTime(2026, 11, 1, 12);
  final account = FinancialAccount(
    id: StableId.generate(),
    name: 'حساب روزمره',
    currency: 'IRR',
    type: FinancialAccountType.bank,
    bank: IranianBank.melli,
  );
  final entries = List.generate(
    8,
    (index) => AccountEntry(
      id: StableId.generate(),
      accountId: account.id,
      type: AccountEntryType.expense,
      amount: const Money(minorUnits: 123456, currency: 'IRR'),
      occurredAt: date.add(Duration(days: index)),
    ),
  );
  TodayActionCenter project({int count = 8, bool metadata = true}) =>
      const AttentionEngine().buildActionCenter(
        now: date,
        commitments: const [],
        plans: const {},
        expectations: const [],
        matches: const [],
        inboxSuggestions: const [],
        entries: entries.take(count),
        accounts: metadata ? [account] : [],
        transactionTags: metadata
            ? {
                for (final entry in entries) entry.id: ['خرید', 'خانه'],
              }
            : {},
      );

  test('financial preview preserves bank, tags, date and review amount', () {
    final item = project().attention.first.attentionItem!;
    expect(item.bankName, account.bank!.label);
    expect(item.accountName, account.name);
    expect(item.tags, ['خرید', 'خانه']);
    expect(item.occurredAt, date);
    expect(item.amountMinorUnits, 123456);
    expect(
      project(metadata: false).attention.first.attentionItem!.bankName,
      isNull,
    );
    expect(
      project(metadata: false).attention.first.attentionItem!.tags,
      isEmpty,
    );
  });

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '$brightness $scale bounded relationship preview and actions',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var queueOpened = 0;
          TodayActionItem? reviewed;
          await tester.pumpWidget(
            MaterialApp(
              theme: brightness == Brightness.dark
                  ? PlanActTheme.dark()
                  : PlanActTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Scaffold(
                    body: TodayPage(
                      commitments: const [],
                      scheduledDates: const {},
                      actionCenter: project(),
                      onAdd: () {},
                      onCommitmentTap: (_) {},
                      onCommitmentArchive: (_) {},
                      onReview: (item) => reviewed = item,
                      onOpenRelationshipQueue: () => queueOpened++,
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(find.text('#خرید'), findsNothing);
          final tile = tester.widget<ExpansionTile>(find.byType(ExpansionTile));
          expect(tile.initiallyExpanded, isFalse);
          expect((tile.subtitle! as Text).data, contains('۸'));
          await tester.dragUntilVisible(
            find.byType(ExpansionTile).hitTestable(),
            find.byType(ListView),
            const Offset(0, -150),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byType(ExpansionTile));
          await tester.pumpAndSettle();
          expect(find.text('#خرید'), findsNWidgets(3));
          final group = find.byType(ExpansionTile);
          expect(
            find.ancestor(of: group, matching: find.byType(Card)),
            findsNothing,
          );
          final transactionCards = find.descendant(
            of: group,
            matching: find.byType(Card),
          );
          expect(transactionCards, findsNWidgets(3));
          for (var index = 0; index < 3; index++) {
            final card = transactionCards.at(index);
            expect(
              find.descendant(of: card, matching: find.text('#خرید')),
              findsOneWidget,
            );
            expect(
              find.descendant(of: card, matching: find.byType(TextButton)),
              findsOneWidget,
            );
            if (index > 0) {
              expect(
                tester.getTopLeft(card).dy,
                greaterThan(
                  tester.getBottomLeft(transactionCards.at(index - 1)).dy,
                ),
              );
            }
          }
          expect(find.text('#خانه'), findsNWidgets(3));
          expect(find.textContaining(account.name), findsNWidgets(3));
          expect(find.textContaining(account.bank!.label), findsNWidgets(3));
          expect(
            find.textContaining(
              PersianDateFormatter.date(JalaliDate.fromDateTime(date)),
            ),
            findsOneWidget,
          );
          final review = find
              .widgetWithText(TextButton, project().attention.first.actionLabel)
              .first;
          await tester.dragUntilVisible(
            review.hitTestable(),
            find.byType(ListView),
            const Offset(0, -100),
          );
          await tester.pumpAndSettle();
          await tester.tap(review);
          expect(reviewed!.sourceReference, entries.first.id.value);
          final all = find.byKey(const ValueKey('today-relationship-view-all'));
          await tester.dragUntilVisible(
            all.hitTestable(),
            find.byType(ListView),
            const Offset(0, -250),
          );
          await tester.pumpAndSettle();
          await tester.tap(all);
          expect(queueOpened, 1);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'missing metadata remains explicit and short group has no more link',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayPage(
              commitments: const [],
              scheduledDates: const {},
              actionCenter: project(count: 1, metadata: false),
              onAdd: () {},
              onCommitmentTap: (_) {},
              onCommitmentArchive: (_) {},
              onReview: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();
      expect(find.textContaining('بانک: نامشخص'), findsOneWidget);
      expect(find.text('#خرید'), findsNothing);
      expect(
        find.byKey(const ValueKey('today-relationship-view-all')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
