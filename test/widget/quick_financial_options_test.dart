import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/quick_add/presentation/quick_add_sheet.dart';

import 'tagged_creation_test.dart' show addTag;

final accounts = [
  for (final name in ['حساب اول', 'حساب دوم'])
    FinancialAccount(
      id: StableId.generate(),
      name: name,
      currency: 'IRR',
      type: FinancialAccountType.bank,
    ),
];
Finder key(String name) => find.byKey(ValueKey('quick-financial-$name'));
Future<void> tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final income in [false, true]) {
    for (final dark in [false, true]) {
      for (final textScale in [1.0, 2.0]) {
        testWidgets(
          'date and time have a small vertical gap: $income $dark $textScale',
          (tester) async {
            tester.view.physicalSize = const Size(360, 900);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(textScale)),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: child!,
                  ),
                ),
                home: Scaffold(
                  body: QuickFinancialEntrySheet(
                    accounts: accounts,
                    income: income,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tap(tester, key('more-options'));
            await tester.ensureVisible(key('time'));
            await tester.pumpAndSettle();
            expect(find.text('تاریخ: روز ثبت نهایی'), findsOneWidget);
            expect(find.text('ساعت: زمان ثبت نهایی'), findsOneWidget);
            final date = tester.getRect(key('date'));
            final time = tester.getRect(key('time'));
            expect(time.top - date.bottom, closeTo(PlanActSpacing.sm, 0.01));
            expect(tester.takeException(), isNull);
          },
        );
      }
      testWidgets(
        'inline draft retains all fields and retries: $income $dark',
        (tester) async {
          final tags = InMemoryTagRepository();
          final attempts = <QuickFinancialEntry>[];
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => QuickFinancialEntrySheet(
                        accounts: accounts,
                        income: income,
                        tagRepository: tags,
                        onSave: (entry) async {
                          attempts.add(entry);
                          if (attempts.length == 1) {
                            throw StateError('injected');
                          }
                        },
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          );
          await tap(tester, find.text('open'));
          await tester.enterText(key('amount'), '1200');
          await tap(tester, key('account'));
          await tap(tester, find.text('حساب دوم').last);
          await tester.enterText(key('note'), 'یادداشت آزمون');
          await addTag(tester, 'خانه');
          await tap(tester, key('more-options'));
          expect(attempts, isEmpty);
          expect(await tags.list(), isEmpty);
          // Picker cancellation must leave the date implicit.
          await tap(tester, key('date'));
          Navigator.of(tester.element(find.byType(PlanActJalaliDatePicker)))
              .pop();
          await tester.pumpAndSettle();
          expect(find.text('تاریخ: روز ثبت نهایی'), findsOneWidget);
          await tap(tester, key('date'));
          final selected = DateTime(2027, 3, 24);
          Navigator.of(tester.element(find.byType(PlanActJalaliDatePicker)))
              .pop(selected);
          await tester.pumpAndSettle();
          await tap(tester, key('time'));
          Navigator.of(tester.element(find.byType(TimePickerDialog)))
              .pop(const TimeOfDay(hour: 13, minute: 47));
          await tester.pumpAndSettle();
          await tap(tester, key('more-options'));
          expect(key('date'), findsNothing);
          expect(find.textContaining('۱۳:۴۷'), findsOneWidget);
          await tap(tester, key('more-options'));
          expect(attempts, isEmpty);
          await tap(tester, key('save'));
          expect(attempts, hasLength(1));
          expect(
            find.byKey(const ValueKey('planact-form-error')),
            findsOneWidget,
          );
          expect(await tags.list(), isEmpty);
          expect(
            tester.widget<TextField>(key('amount')).controller!.text,
            '1,200',
          );
          expect(
            tester.widget<TextField>(key('note')).controller!.text,
            'یادداشت آزمون',
          );
          await tap(tester, key('save'));
          expect(attempts, hasLength(2));
          for (final entry in attempts) {
            expect(entry.income, income);
            expect(entry.amount, 1200);
            expect(entry.account.id, accounts.last.id);
            expect(entry.note, 'یادداشت آزمون');
            expect(entry.tags, {'خانه'});
            expect(
              entry.resolveOccurredAt(DateTime(2030)),
              DateTime(2027, 3, 24, 13, 47),
            );
          }
          expect(find.byType(QuickFinancialEntrySheet), findsNothing);
          // Reopening and cancelling after disclosure must never call save.
          await tap(tester, find.text('open'));
          await tap(tester, key('more-options'));
          await tap(tester, key('more-options'));
          await tap(tester, find.text('انصراف'));
          expect(attempts, hasLength(2));
          expect(await tags.list(), isEmpty);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  test('implicit components resolve from final save, not disclosure time', () {
    QuickFinancialEntry draft({DateTime? date, TimeOfDay? time}) =>
        QuickFinancialEntry(
          account: accounts.first,
          amount: 1,
          note: null,
          income: false,
          selectedDate: date,
          selectedTime: time,
        );
    final now = DateTime(2028, 4, 6, 23, 58, 31, 123, 456);
    expect(draft().resolveOccurredAt(now), now);
    expect(
      draft(date: DateTime(2027, 2, 3)).resolveOccurredAt(now),
      DateTime(2027, 2, 3, 23, 58, 31, 123, 456),
    );
    expect(
      draft(time: const TimeOfDay(hour: 5, minute: 7)).resolveOccurredAt(now),
      DateTime(2028, 4, 6, 5, 7),
    );
    expect(
      draft().resolveOccurredAt(now.add(const Duration(days: 1))),
      now.add(const Duration(days: 1)),
    );
  });
}
