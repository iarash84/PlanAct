import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/today/presentation/today_page.dart';
import 'package:shamsi_date/shamsi_date.dart';

// Acceptance: actual root Add -> wizard controls -> review -> durable save ->
// Today/Calendar. Explicit calendars are independent of Jalali display; count
// and inclusive end dates are independent of frequency. Invalid/cancelled
// drafts do not write. File reopen checks authoring durability, not backup or
// native reminder delivery. No draft injection or direct production mutation.
void main() {
  for (final frequency in [
    RecurrenceFrequency.monthly,
    RecurrenceFrequency.yearly,
  ]) {
    for (final calendar in RecurrenceCalendar.values) {
      for (final termination in [
        RecurrenceTermination.count,
        RecurrenceTermination.endDate,
      ]) {
        final dark = termination == RecurrenceTermination.endDate;
        testWidgets(
          'root capture ${frequency.name} ${calendar.name} ${termination.name} '
          '${dark ? 'Dark' : 'Light'} narrow enlarged text persists and refreshes',
          (tester) async {
            final directory = (await tester.runAsync(
              () => Directory.systemTemp.createTemp('planact-capture-route-'),
            ))!;
            final file = File('${directory.path}/personal.sqlite');
            var database = AppDatabase.forTesting(NativeDatabase(file));
            final commitments = DriftCommitmentRepository(database);
            final plans = DriftCommitmentPlanRepository(database);
            tester.view.physicalSize = const Size(360, 1000);
            tester.view.devicePixelRatio = 1;
            addTearDown(() async {
              tester.view.resetPhysicalSize();
              tester.view.resetDevicePixelRatio();
              await tester.runAsync(() async {
                await database.close();
                await directory.delete(recursive: true);
              });
            });
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.5)),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: child!,
                  ),
                ),
                home: HomeShell(repository: commitments, planRepository: plans),
              ),
            );
            await _drainDatabase(tester);
            await _openCapture(tester);
            await tester.enterText(
              find.byKey(const ValueKey('commitment-title-field')),
              'تعهد ${frequency.name} ${calendar.name}',
            );
            await _choose<CommitmentKind>(
              tester,
              find.byKey(const ValueKey('commitment-kind-dropdown')),
              'تکرارشونده',
            );
            await _choose<RecurrenceFrequency>(
              tester,
              find.byType(DropdownButtonFormField<RecurrenceFrequency>),
              frequency == RecurrenceFrequency.monthly ? 'ماهانه' : 'سالانه',
            );
            await _choose<RecurrenceCalendar>(
              tester,
              find.byKey(const ValueKey('recurrence-calendar')),
              calendar == RecurrenceCalendar.jalali ? 'شمسی' : 'میلادی',
            );
            // Read the current picker month, then explicitly choose its day 19.
            final now = DateTime.now();
            final month = Gregorian(now.year, now.month, now.day).toJalali();
            final start = Jalali(month.year, month.month, 19).toGregorian();
            await _tap(tester, find.text('انتخاب تاریخ'));
            await _pickDay19(tester);
            await _tap(tester, find.text('انتخاب زمان'));
            await tester.tap(find.byType(TextButton).last);
            await tester.pumpAndSettle();
            await _choose<RecurrenceTermination>(
              tester,
              find.byKey(const ValueKey('recurrence-termination')),
              termination == RecurrenceTermination.count
                  ? 'تعداد مشخص'
                  : 'تا تاریخ مشخص',
            );
            final expected = <DateTime>[];
            for (var slot = 0; slot < 3; slot++) {
              if (calendar == RecurrenceCalendar.jalali) {
                final date = frequency == RecurrenceFrequency.monthly
                    ? Jalali(month.year, month.month, 19).addMonths(slot)
                    : Jalali(month.year + slot, month.month, 19);
                final g = date.toGregorian();
                expected.add(DateTime(g.year, g.month, g.day));
              } else {
                expected.add(
                  frequency == RecurrenceFrequency.monthly
                      ? DateTime(start.year, start.month + slot, start.day)
                      : DateTime(start.year + slot, start.month, start.day),
                );
              }
            }
            DateTime? end;
            if (termination == RecurrenceTermination.count) {
              // Validation failure leaves all explicit selections intact.
              await _tap(tester, find.text('ثبت تعهد'));
              expect(find.byType(QuickCaptureSheet), findsOneWidget);
              await tester.runAsync(() async {
                expect(await commitments.list(), isEmpty);
              });
              await tester.ensureVisible(
                find.byKey(const ValueKey('recurrence-count')),
              );
              await tester.enterText(
                find.byKey(const ValueKey('recurrence-count')),
                '۳',
              );
            } else {
              await _tap(
                tester,
                find.byKey(const ValueKey('recurrence-end-date')),
              );
              // Cancellation must not invent an end date.
              await _tap(tester, find.text('انصراف').last);
              expect(find.text('انتخاب تاریخ پایان'), findsOneWidget);
              await _tap(tester, find.text('ثبت تعهد'));
              expect(find.byType(QuickCaptureSheet), findsOneWidget);
              await _tap(
                tester,
                find.byKey(const ValueKey('recurrence-end-date')),
              );
              final endJalali = Gregorian(
                expected[1].year,
                expected[1].month,
                expected[1].day,
              ).toJalali();
              final months =
                  (endJalali.year - month.year) * 12 +
                  endJalali.month -
                  month.month;
              for (var i = 0; i < months; i++) {
                await _tap(tester, find.byTooltip('ماه بعد'));
              }
              await _tap(
                tester,
                find.byKey(ValueKey('capture-date-${endJalali.day}')),
              );
              await _tap(tester, find.text('تأیید تاریخ'));
              end = expected[1];
              expected.removeLast();
            }
            // Selections remain editable in place, preserving calendar and termination.
            expect(
              tester
                  .widget<DropdownButtonFormField<RecurrenceCalendar>>(
                    find.byKey(const ValueKey('recurrence-calendar')),
                  )
                  .initialValue,
              calendar,
            );
            await _tap(tester, find.text('ثبت تعهد'));
            await _drainDatabase(tester);
            expect(find.byType(QuickCaptureSheet), findsNothing);
            late CommitmentPlan saved;
            await tester.runAsync(() async {
              final items = await commitments.list();
              expect(items, hasLength(1));
              saved = (await plans.findByCommitmentId(items.single.id))!;
            });
            _expectPlan(saved, frequency, calendar, termination, end, expected);
            final today = tester.widget<TodayPage>(find.byType(TodayPage));
            expect(
              today.scheduledDates[saved.commitment.id.value]!
                  .map(_date)
                  .toSet(),
              expected.toSet(),
            );
            await _tap(tester, find.text('تقویم').last);
            final page = tester.widget<CalendarPage>(
              find.byType(CalendarPage, skipOffstage: false),
            );
            expect(
              page.scheduledDates[saved.commitment.id.value]!
                  .map(_date)
                  .toSet(),
              expected.toSet(),
            );
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.runAsync(() async {
              await database.close();
              database = AppDatabase.forTesting(NativeDatabase(file));
              final reopened = await DriftCommitmentPlanRepository(database)
                  .findByCommitmentId(saved.commitment.id);
              _expectPlan(
                reopened!,
                frequency,
                calendar,
                termination,
                end,
                expected,
              );
            });
          },
        );
      }
    }
  }

  testWidgets(
    'root cancelling configured monthly draft leaves no durable plan',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final commitments = DriftCommitmentRepository(database);
      final plans = DriftCommitmentPlanRepository(database);
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: HomeShell(repository: commitments, planRepository: plans),
          ),
        ),
      );
      await _drainDatabase(tester);
      await _openCapture(tester);
      await tester.enterText(
        find.byKey(const ValueKey('commitment-title-field')),
        'پیش‌نویس لغوشده',
      );
      await _choose<CommitmentKind>(
        tester,
        find.byKey(const ValueKey('commitment-kind-dropdown')),
        'تکرارشونده',
      );
      await _choose<RecurrenceFrequency>(
        tester,
        find.byType(DropdownButtonFormField<RecurrenceFrequency>),
        'ماهانه',
      );
      await _choose<RecurrenceCalendar>(
        tester,
        find.byKey(const ValueKey('recurrence-calendar')),
        'میلادی',
      );
      await _tap(tester, find.text('انصراف'));
      expect(find.byType(QuickCaptureSheet), findsNothing);
      await tester.runAsync(() async {
        expect(await commitments.list(), isEmpty);
        expect(
          await database.select(database.scheduleDefinitions).get(),
          isEmpty,
        );
        expect(await database.select(database.occurrences).get(), isEmpty);
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(database.close);
      expect(tester.takeException(), isNull);
    },
  );
}

DateTime _date(DateTime value) => DateTime(value.year, value.month, value.day);

void _expectPlan(
  CommitmentPlan plan,
  RecurrenceFrequency frequency,
  RecurrenceCalendar calendar,
  RecurrenceTermination termination,
  DateTime? end,
  List<DateTime> expected,
) {
  expect(plan.schedule.recurrenceRule!.frequency, frequency);
  expect(plan.schedule.recurrenceRule!.calendar, calendar);
  expect(
    plan.schedule.occurrenceCount,
    termination == RecurrenceTermination.count ? 3 : null,
  );
  final endDate = plan.schedule.endDate;
  expect(
    endDate == null ? null : DateTime(endDate.year, endDate.month, endDate.day),
    end,
  );
  expect(
    plan.occurrences
        .map((o) => _date(o.currentScheduledAt as DateTime))
        .toSet(),
    expected.toSet(),
  );
}

Future<void> _openCapture(WidgetTester tester) async {
  await _tap(tester, find.byTooltip('افزودن سریع'));
  await _tap(tester, find.byKey(const ValueKey('quick-add-commitment')));
  expect(find.byType(QuickCaptureSheet), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'After tapping $finder');
}

Future<void> _choose<T>(
  WidgetTester tester,
  Finder dropdown,
  String label,
) async {
  await _tap(tester, dropdown);
  await _tap(tester, find.text(label).last);
}

Future<void> _pickDay19(WidgetTester tester) async {
  await _tap(tester, find.byKey(const ValueKey('capture-date-19')));
  await _tap(tester, find.text('تأیید تاریخ'));
}

Future<void> _drainDatabase(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}
