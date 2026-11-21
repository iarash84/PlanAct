import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/l10n/generated/app_localizations_fa.dart';
import 'package:planact/core/presentation/planact_state_message.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';
import 'package:planact/features/inbox/presentation/sms_review_editor.dart';

class _FailingInbox extends InMemoryInboxRepository {
  @override
  Future<List<InboxSuggestion>> listSuggestions() async =>
      throw StateError('injected read failure');
}

Widget _app(
  InboxUseCases inbox,
  InMemoryFinanceRepository finance, {
  bool dark = false,
  double scale = 1,
}) => MaterialApp(
  theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: Directionality(textDirection: TextDirection.rtl, child: child!),
  ),
  home: Scaffold(
    body: InboxPage(inbox: inbox, finance: finance),
  ),
);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<List<InboxSuggestion>> _populate(InboxUseCases inbox) async {
  final result = <InboxSuggestion>[];
  for (var index = 0; index < 3; index++) {
    final original = await inbox.stageSms(
      rawText:
          'بانک: نمونه\nبرداشت مبلغ ${1250000 + index}\n'
          'حساب: 1234567890123456\nپیگیری: 9876543210987654',
      sourceKey: 'presentation-$index',
      currency: 'IRR',
      importedAt: DateTime.now().toUtc(),
    );
    final edited = original.withDraft(
      TransactionDraft.fromReviewJson({
        ...original.draft.toReviewJson(),
        'merchant': 'فروشگاه لوازم خانه و خریدهای روزانه خانواده $index',
        'bank': 'بانک نمونه برای بررسی شواهد',
        'sourceAddress': 'BANK-SAMPLE-LONG-SENDER',
        'accountHint': '1234567890123456',
        'reference': '9876543210987654',
      }),
    );
    await inbox.repository.saveSuggestion(edited);
    result.add(edited);
  }
  return result.reversed.toList();
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('populated evidence disclosure at 320 / 2x, dark=$dark', (
      tester,
    ) async {
      tester.view.resetPhysicalSize();
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = InMemoryInboxRepository();
      final inbox = InboxUseCases(repository);
      final finance = InMemoryFinanceRepository();
      final suggestions = await _populate(inbox);
      final before = await repository.listSuggestions();
      await tester.pumpWidget(_app(inbox, finance, dark: dark, scale: 2));
      await tester.pumpAndSettle();
      final list = find.byKey(const PageStorageKey('inbox-review'));
      expect(
        tester.widget<ListView>(list).padding,
        const EdgeInsets.all(PlanActSpacing.page),
      );
      final first = suggestions.first;
      final card = find.byKey(ValueKey(first.id));
      await tester.scrollUntilVisible(
        card,
        400,
        scrollable: find.byType(Scrollable).first,
      );
      Finder inside(Finder target) =>
          find.descendant(of: card, matching: target);
      expect(inside(find.byType(SmsOriginalEvidence)), findsNothing);
      expect(inside(find.textContaining('BANK-SAMPLE')), findsNothing);
      expect(
        inside(find.text(AppLocalizationsFa().inboxDefaultUnitReviewNotice)),
        findsOneWidget,
      );
      expect(
        inside(find.text(AppLocalizationsFa().inboxPageBuildChildren9)),
        findsOneWidget,
      );
      expect(inside(find.textContaining('هشدار:')), findsWidgets);
      expect(inside(find.byType(CheckboxListTile)), findsOneWidget);
      expect(
        inside(find.text(AppLocalizationsFa().inboxPageBuildLabel4)),
        findsOneWidget,
      );
      expect(
        inside(find.text(AppLocalizationsFa().inboxPageBuildLabel5)),
        findsOneWidget,
      );
      expect(
        inside(find.text(AppLocalizationsFa().inboxPageBuildLabel6)),
        findsOneWidget,
      );
      final title = inside(find.text(first.draft.merchant!));
      final amount = inside(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.style ==
                  Theme.of(tester.element(card)).textTheme.titleLarge,
        ),
      );
      expect(amount, findsOneWidget);
      expect(
        tester.getTopLeft(title).dy,
        lessThan(tester.getTopLeft(amount).dy),
      );
      await _tap(
        tester,
        inside(find.text(AppLocalizationsFa().inboxPageBuildLabel2)),
      );
      expect(inside(find.byType(SmsOriginalEvidence)), findsOneWidget);
      expect(
        inside(find.textContaining('BANK-SAMPLE-LONG-SENDER')),
        findsOneWidget,
      );
      expect(
        inside(find.text(AppLocalizationsFa().inboxPageBuildChildren20)),
        findsOneWidget,
      );
      expect(
        inside(find.textContaining(maskedSmsEvidence('1234567890123456'))),
        findsWidgets,
      );
      expect(inside(find.textContaining('1234567890123456')), findsNothing);
      expect(inside(find.textContaining('9876543210987654')), findsNothing);
      await _tap(
        tester,
        inside(find.text(AppLocalizationsFa().inboxPageBuildLabel)),
      );
      expect(inside(find.byType(SmsOriginalEvidence)), findsNothing);
      expect(
        inside(find.text(AppLocalizationsFa().inboxDefaultUnitReviewNotice)),
        findsOneWidget,
      );
      // Expanding and collapsing evidence must not accept units or edit history.
      final after = await repository.listSuggestions();
      for (var index = 0; index < before.length; index++) {
        expect(after[index].revision, before[index].revision);
        expect(after[index].status, before[index].status);
        expect(
          after[index].draft.toReviewJson(),
          before[index].draft.toReviewJson(),
        );
        expect(
          after[index].extractedEvidence,
          same(before[index].extractedEvidence),
        );
      }
      expect(await finance.listEntries(), isEmpty);
      // All three realistic cards remain reachable after reviewing the first.
      final lastCard = find.byKey(ValueKey(suggestions.last.id));
      await tester.scrollUntilVisible(
        lastCard,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await _tap(
        tester,
        find.descendant(
          of: lastCard,
          matching: find.text(AppLocalizationsFa().inboxPageBuildLabel2),
        ),
      );
      expect(
        find.descendant(
          of: lastCard,
          matching: find.byType(SmsOriginalEvidence),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('empty and retry feedback retain title/action, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final finance = InMemoryFinanceRepository();
      await tester.pumpWidget(
        _app(
          InboxUseCases(InMemoryInboxRepository()),
          finance,
          dark: dark,
          scale: 2,
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(PlanActStateMessage),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        tester
            .widget<PlanActStateMessage>(find.byType(PlanActStateMessage))
            .kind,
        PlanActMessageKind.empty,
      );
      expect(
        find.text(AppLocalizationsFa().inboxPageHeaderTitle),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        _app(InboxUseCases(_FailingInbox()), finance, dark: dark, scale: 2),
      );
      await tester.pumpAndSettle();
      final feedback = tester.widget<PlanActStateMessage>(
        find.byType(PlanActStateMessage),
      );
      expect(feedback.kind, PlanActMessageKind.error);
      expect(feedback.title, AppLocalizationsFa().inboxPageBuildTitle);
      expect(feedback.action, isNotNull);
      await _tap(tester, find.text(AppLocalizationsFa().commonRetry));
      expect(find.byType(PlanActStateMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
