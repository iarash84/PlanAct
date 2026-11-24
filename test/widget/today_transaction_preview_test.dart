import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/today/application/attention_engine.dart';
import 'package:planact/features/today/presentation/today_transaction_preview.dart';

void main() {
  final date = DateTime(2026, 11, 21, 14, 35);
  TodayActionItem item({
    bool inbox = false,
    bool long = false,
    bool stress = false,
    String? bank = 'بانک ملی',
    List<String> tags = const ['خانه'],
  }) {
    final details = AttentionItem(
      id: 'preview',
      reason: inbox
          ? AttentionReason.inboxReview
          : AttentionReason.unmatchedTransaction,
      title: inbox ? 'برداشت' : 'تراکنش',
      explanation: 'بررسی',
      urgency: 65,
      amountMinorUnits: stress ? 987654321012345 : 40000,
      transactionTotalMinorUnits: 100000,
      transactionType: AccountEntryType.expense,
      currency: 'IRR',
      occurredAt: date,
      accountName: stress
          ? List.filled(8, 'حساب روزمره').join(' ')
          : 'حساب روزمره',
      bankName: 'بانک ملی',
      description: long
          ? List.filled(30, 'شرح بلند تراکنش').join(' ')
          : 'خرید روزانه',
      tags: tags,
      inboxDraft: inbox
          ? TransactionDraft(
              id: StableId.generate(),
              stagedImportId: StableId.generate(),
              amount: const Money(minorUnits: 40000, currency: 'IRR'),
              occurredAt: date,
              type: 'expense',
              direction: TransactionDirection.outgoing,
              bank: bank,
              sourceAddress: 'BANK',
              merchant: 'خرید روزانه',
              dateSource: TransactionDateSource.receipt,
            )
          : null,
    );
    return TodayActionItem(
      id: details.id,
      type: inbox
          ? TodayActionItemType.inboxReview
          : TodayActionItemType.financialReview,
      title: details.title,
      subtitle: details.explanation,
      urgency: 65,
      attentionAction: details.action,
      attentionItem: details,
    );
  }

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 360.0, 400.0]) {
      for (final scale in [1.0, 2.0]) {
        for (final inbox in [false, true]) {
          testWidgets(
            '$brightness width $width scale $scale inbox $inbox readable compact preview',
            (tester) async {
              tester.view.physicalSize = Size(width, 1800);
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.resetPhysicalSize);
              addTearDown(tester.view.resetDevicePixelRatio);
              var reviewed = 0;
              await tester.pumpWidget(
                MaterialApp(
                  theme: brightness == Brightness.light
                      ? PlanActTheme.light()
                      : PlanActTheme.dark(),
                  home: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Scaffold(
                        body: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            TodayTransactionPreview(
                              item: item(inbox: inbox),
                              onReview: () => reviewed++,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
              expect(find.text('خرید روزانه'), findsOneWidget);
              expect(find.textContaining('بانک ملی'), findsOneWidget);
              expect(find.text('#خانه'), findsOneWidget);
              if (inbox) {
                expect(find.text('هنوز ثبت نشده'), findsOneWidget);
                expect(
                  find.text('تاریخ تراکنش نیاز به بررسی دارد'),
                  findsOneWidget,
                );
                expect(find.textContaining('تاریخ استخراج'), findsNothing);
              } else {
                expect(find.text('مبلغ بدون ارتباط'), findsOneWidget);
                expect(find.textContaining('کل تراکنش:'), findsOneWidget);
                expect(find.textContaining('حساب روزمره'), findsOneWidget);
                expect(find.textContaining('۱۴:۳۵'), findsOneWidget);
              }
              if (scale == 1) {
                // Typical phone width; narrow/large-text cases may grow naturally.
                expect(
                  tester.getSize(find.byType(Card)).height,
                  lessThanOrEqualTo(width == 320 ? 300 : 280),
                );
              }
              final action = find.byType(TextButton);
              await tester.ensureVisible(action);
              await tester.tap(action);
              expect(reviewed, 1);
              expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }

  Future<void> pumpPreview(
    WidgetTester tester, {
    double width = 360,
    double scale = 1,
    Brightness brightness = Brightness.light,
    TodayActionItem? preview,
  }) async {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.light
            ? PlanActTheme.light()
            : PlanActTheme.dark(),
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TodayTransactionPreview(
                    item: preview ?? item(),
                    onReview: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('measured RTL header places type at start and amount at end', (
    tester,
  ) async {
    // The test font is wider than device Persian fonts; test actual fit,
    // independently from the phone-width compactness/stacking matrix.
    await pumpPreview(tester, width: 600);
    final type = tester.getRect(find.text('برداشت'));
    final amount = tester.getRect(find.text('۴۰,۰۰۰ ریال'));
    final remainder = tester.getRect(find.text('مبلغ بدون ارتباط'));
    final total = tester.getRect(find.textContaining('کل تراکنش:'));
    expect(type.left, greaterThan(amount.right));
    expect(type.top, lessThan(amount.bottom));
    expect(remainder.bottom, lessThanOrEqualTo(amount.top));
    expect(total.top, greaterThanOrEqualTo(amount.bottom));
    expect(amount.left, closeTo(total.left, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'tags bounded to two, description separate, bank preferred and sender fallback',
    (tester) async {
      final preview = item(
        inbox: true,
        tags: ['خانه', 'خرید', 'سفر', 'خانواده'],
      );
      await pumpPreview(tester, preview: preview);
      expect(find.text('#خانه'), findsOneWidget);
      expect(find.text('#خرید'), findsOneWidget);
      expect(find.text('#سفر'), findsNothing);
      expect(find.text('#خانواده'), findsNothing);
      expect(find.text('و ۲ برچسب دیگر'), findsOneWidget);
      expect(
        tester.getRect(find.text('#خانه')).top,
        greaterThanOrEqualTo(tester.getRect(find.text('خرید روزانه')).bottom),
      );
      expect(find.textContaining('BANK'), findsNothing);
      final status = tester.widget<Text>(find.text('هنوز ثبت نشده'));
      final context = tester.element(find.byType(TodayTransactionPreview));
      expect(
        status.style?.color,
        Theme.of(context).colorScheme.onSurfaceVariant,
      );
      await pumpPreview(tester, preview: item(inbox: true, bank: null));
      expect(find.textContaining('BANK'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    for (final width in [320.0, 360.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'stress $brightness $width $scale stacks without losing metadata',
          (tester) async {
            await pumpPreview(
              tester,
              width: width,
              scale: scale,
              brightness: brightness,
              preview: item(
                stress: true,
                long: true,
                tags: ['خانه', 'خرید', 'سفر'],
              ),
            );
            final type = tester.getRect(find.text('برداشت'));
            final remainder = tester.getRect(find.text('مبلغ بدون ارتباط'));
            expect(remainder.top, greaterThanOrEqualTo(type.bottom));
            expect(find.textContaining('۹۸۷,۶۵۴,۳۲۱,۰۱۲,۳۴۵'), findsOneWidget);
            expect(find.textContaining('حساب روزمره'), findsOneWidget);
            expect(find.textContaining('۱۴:۳۵'), findsOneWidget);
            expect(find.text('و ۱ برچسب دیگر'), findsOneWidget);
            expect(tester.takeException(), isNull);
            final action = find.byType(TextButton);
            await tester.ensureVisible(action);
            expect(tester.getSize(action).height, greaterThanOrEqualTo(48));
          },
        );
      }
    }
  }

  testWidgets('long description is bounded without losing review action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PlanActTheme.light(),
        home: Scaffold(
          body: TodayTransactionPreview(
            item: item(long: true),
            onReview: () {},
          ),
        ),
      ),
    );
    final description = tester.widget<Text>(find.textContaining('شرح بلند'));
    expect(description.maxLines, 2);
    expect(description.overflow, TextOverflow.ellipsis);
    expect(find.byType(TextButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
