import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';
import 'package:planact/features/today/application/attention_engine.dart';
import 'package:planact/features/today/presentation/today_page.dart';

final _date = DateTime(2026, 11, 1, 12);

InboxSuggestion suggestion(
  int index, {
  TransactionDirection direction = TransactionDirection.outgoing,
  TransactionDateSource dateSource = TransactionDateSource.extracted,
  SuggestionStatus status = SuggestionStatus.pending,
  bool metadata = true,
  bool unresolvedUnit = false,
}) {
  final staged = StableId.generate();
  return InboxSuggestion(
    id: StableId.generate(),
    stagedImportId: staged,
    status: status,
    draft: TransactionDraft(
      id: StableId.generate(),
      stagedImportId: staged,
      amount: const Money(minorUnits: 123456, currency: 'IRR'),
      occurredAt: _date.add(Duration(days: index)),
      type: 'expense',
      direction: direction,
      dateSource: dateSource,
      bank: metadata ? 'بانک ملی' : null,
      sourceAddress: metadata ? 'BANK$index' : null,
      currencyEvidence: unresolvedUnit
          ? const SmsCurrencyEvidence(sourceAmount: 123456)
          : null,
    ),
  );
}

TodayActionCenter center(List<InboxSuggestion> suggestions) =>
    const AttentionEngine().buildActionCenter(
      now: _date,
      commitments: const [],
      plans: const {},
      expectations: const [],
      matches: const [],
      inboxSuggestions: suggestions,
      entries: const [],
      accounts: const [],
    );

void main() {
  test('projection uses direction, preserves metadata and excludes resolved drafts', () {
    for (final direction in TransactionDirection.values) {
      final source = suggestion(0, direction: direction);
      final item = center([
        source,
        suggestion(1, status: SuggestionStatus.confirmed),
        suggestion(2, status: SuggestionStatus.rejected),
        suggestion(3, status: SuggestionStatus.duplicate),
      ]).attention.single;
      expect(item.title, switch (direction) {
        TransactionDirection.incoming => 'واریز',
        TransactionDirection.outgoing => 'برداشت',
        TransactionDirection.unknown => 'نوع نامشخص',
      });
      expect(item.attentionItem!.inboxDraft, same(source.draft));
      expect(item.sourceReference, source.id.value);
    }
    expect(
      center([suggestion(0, status: SuggestionStatus.edited)]).attention,
      hasLength(1),
    );
  });

  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$brightness scale $scale collapsed bounded RTL preview', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var opened = 0;
        var reviewed = 0;
        final sources = List.generate(8, (index) => suggestion(index));
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
                  body: TodayPage(
                    commitments: const [],
                    scheduledDates: const {},
                    actionCenter: center(sources),
                    onAdd: () {},
                    onCommitmentTap: (_) {},
                    onCommitmentArchive: (_) {},
                    onReview: (_) => reviewed++,
                    onOpenInbox: () => opened++,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('برداشت'), findsNothing);
        final tile = find.byType(ExpansionTile);
        expect(tester.widget<ExpansionTile>(tile).initiallyExpanded, isFalse);
        final subtitle = tester.widget<ExpansionTile>(tile).subtitle! as Text;
        expect(subtitle.data, contains('۸'));
        await tester.tap(find.text('بازبینی تراکنش'));
        await tester.pumpAndSettle();
        expect(find.text('برداشت'), findsNWidgets(3));
        expect(
          find.ancestor(of: tile, matching: find.byType(Card)),
          findsNothing,
        );
        final transactionCards = find.descendant(
          of: tile,
          matching: find.byType(Card),
        );
        expect(transactionCards, findsNWidgets(3));
        for (var index = 0; index < 3; index++) {
          final card = transactionCards.at(index);
          expect(
            find.descendant(of: card, matching: find.text('برداشت')),
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
        expect(find.textContaining('BANK0'), findsOneWidget);
        expect(find.textContaining('BANK3'), findsNothing);
        expect(find.textContaining('بانک ملی'), findsNWidgets(3));
        expect(
          find.textContaining(
            PersianDateFormatter.date(JalaliDate.fromDateTime(_date)),
          ),
          findsOneWidget,
        );
        expect(find.textContaining('expense'), findsNothing);
        expect(find.byTooltip('نمایش جزئیات'), findsNothing);
        final all = find.byKey(const ValueKey('today-inbox-view-all'));
        await tester.dragUntilVisible(
          all.hitTestable(),
          find.byType(ListView),
          const Offset(0, -250),
        );
        await tester.pumpAndSettle();
        await tester.tap(all);
        await tester.pumpAndSettle();
        expect(opened, 1);
        expect(reviewed, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final dateSource in [
    TransactionDateSource.receipt,
    TransactionDateSource.unknown,
    TransactionDateSource.reviewer,
  ]) {
    testWidgets('$dateSource does not pretend to be an extracted date', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TodayPage(
              commitments: const [],
              scheduledDates: const {},
              actionCenter: center([
                suggestion(
                  0,
                  dateSource: dateSource,
                  metadata: false,
                  unresolvedUnit: true,
                ),
              ]),
              onAdd: () {},
              onCommitmentTap: (_) {},
              onCommitmentArchive: (_) {},
              onReview: (_) {},
            ),
          ),
        ),
      );
      await tester.tap(find.text('بازبینی تراکنش'));
      await tester.pumpAndSettle();
      expect(find.textContaining('تاریخ استخراج'), findsNothing);
      expect(find.textContaining('فرستنده'), findsNothing);
      expect(find.textContaining('بانک:'), findsNothing);
      expect(find.textContaining('۱۲۳,۴۵۶ (واحد نامشخص)'), findsOneWidget);
      expect(find.byKey(const ValueKey('today-inbox-view-all')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
