import 'package:planact/features/commitments/domain/commitment_color.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';
import 'package:planact/features/quick_add/presentation/quick_add_sheet.dart';

Future<void> addTag(WidgetTester tester, String label) async {
  final field = find.byKey(const ValueKey('draft-tag-label'));
  await tester.ensureVisible(field);
  await tester.enterText(field, label);
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  final button = find.text('افزودن برچسب به پیش‌نویس');
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Widget host(Widget child, bool dark) => MaterialApp(
  theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
  builder: (context, child) =>
      Directionality(textDirection: TextDirection.rtl, child: child!),
  home: Scaffold(body: child),
);

void main() {
  for (final dark in [false, true]) {
    testWidgets('capture carries draft tags through review and retry ($dark)', (
      tester,
    ) async {
      final tags = InMemoryTagRepository();
      var calls = 0;
      await tester.pumpWidget(
        host(
          QuickCaptureSheet(
            tagRepository: tags,
            onSave: (draft) async {
              expect(draft.tags, {'خانه'});
              expect(draft.color, CommitmentColor.blue);
              calls++;
              if (calls == 1) throw StateError('injected');
            },
          ),
          dark,
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('commitment-title-field')),
        'جلسه',
      );
      final color = find.byKey(const ValueKey('commitment-color-blue'));
      await tester.ensureVisible(color);
      await tester.tap(color);
      await tester.pumpAndSettle();
      await addTag(tester, 'خانه');
      await tester.ensureVisible(find.text('ادامه'));
      await tester.tap(find.text('ادامه'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('انتخاب تاریخ'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('capture-date-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('انتخاب زمان'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('ادامه'));
      await tester.pumpAndSettle();
      expect(find.text('#خانه'), findsOneWidget);
      await tester.tap(find.text('ثبت تعهد'));
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.textContaining('اطلاعات شما حفظ شده است'), findsOneWidget);
      expect(await tags.list(), isEmpty);
      await tester.tap(find.text('ثبت تعهد'));
      await tester.pumpAndSettle();
      expect(calls, 2);
    });
    testWidgets(
      'capture draft reuses, deduplicates and removes tags without writes ($dark)',
      (tester) async {
        final tags = InMemoryTagRepository();
        await tags.getOrCreate('Work');
        await tester.pumpWidget(
          host(QuickCaptureSheet(tagRepository: tags), dark),
        );
        await tester.pumpAndSettle();
        await addTag(tester, ' #work ');
        final chip = find.widgetWithText(FilterChip, '#Work');
        expect(tester.widget<FilterChip>(chip).selected, isTrue);
        await addTag(tester, 'خانه');
        await addTag(tester, '#خانه');
        expect(find.widgetWithText(FilterChip, '#خانه'), findsOneWidget);
        expect(await tags.list(), hasLength(1));
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(tester.widget<FilterChip>(chip).selected, isFalse);
        await tester.pumpWidget(const SizedBox());
        expect(await tags.list(), hasLength(1));
      },
    );

    for (final income in [false, true]) {
      testWidgets(
        'quick entry retains tags on failure and retries once ($dark/$income)',
        (tester) async {
          final tags = InMemoryTagRepository();
          final account = FinancialAccount(
            id: StableId.generate(),
            name: 'نقد',
            currency: 'IRR',
            type: FinancialAccountType.cash,
          );
          var calls = 0;
          QuickFinancialEntry? saved;
          await tester.pumpWidget(
            host(
              QuickFinancialEntrySheet(
                accounts: [account],
                income: income,
                tagRepository: tags,
                onSave: (entry) async {
                  calls++;
                  if (calls == 1) throw StateError('injected');
                  saved = entry;
                },
              ),
              dark,
            ),
          );
          await tester.enterText(
            find.byKey(const ValueKey('quick-financial-amount')),
            '100',
          );
          await addTag(tester, 'خانه');
          final save = find.byKey(const ValueKey('quick-financial-save'));
          await tester.ensureVisible(save);
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(
            find.textContaining('اطلاعات و برچسب‌های شما حفظ شده'),
            findsOneWidget,
          );
          expect(
            tester
                .widget<FilterChip>(find.widgetWithText(FilterChip, '#خانه'))
                .selected,
            isTrue,
          );
          expect(await tags.list(), isEmpty);
          await tester.ensureVisible(save);
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(calls, 2);
          expect(saved!.tags, {'خانه'});
          expect(saved!.income, income);
          expect(saved!.amount, 100);
        },
      );

      testWidgets(
        'full finance creates entry and links together ($dark/$income)',
        (tester) async {
          final database = AppDatabase.forTesting(NativeDatabase.memory());
          addTearDown(database.close);
          final finance = DriftFinanceRepository(database);
          final tags = DriftTagRepository(database);
          final account = FinancialAccount(
            id: StableId.generate(),
            name: 'نقد',
            currency: 'IRR',
            type: FinancialAccountType.cash,
          );
          await finance.saveAccount(account);
          final key = GlobalKey<FinancePageState>();
          await tester.pumpWidget(
            host(
              FinancePage(key: key, repository: finance, tagRepository: tags),
              dark,
            ),
          );
          await tester.pumpAndSettle();
          key.currentState!.openTransactionForm(
            income: income,
            initialTags: {'قبلی'},
          );
          await tester.pumpAndSettle();
          expect(find.byType(DraftTagPicker), findsOneWidget);
          await tester.enterText(
            find.widgetWithText(TextField, 'مبلغ به ریال'),
            '100',
          );
          await addTag(tester, 'خانه');
          expect(await tags.list(), isEmpty);
          final save = find.widgetWithText(FilledButton, 'ثبت');
          await tester.ensureVisible(save);
          await tester.tap(save);
          await tester.pumpAndSettle();
          final entry = (await finance.listEntries()).single;
          expect(
            entry.type,
            income ? AccountEntryType.income : AccountEntryType.expense,
          );
          expect(
            await tags.tagsFor(entry.id.value, TaggableType.accountEntry),
            hasLength(2),
          );
          expect(await tags.list(), hasLength(2));
        },
      );
    }
  }
}
