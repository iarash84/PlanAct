import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/scheduling/application/recurrence_schedule_edit.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/scheduling/presentation/edit_schedule_dialog.dart';
import 'package:planact/l10n/generated/app_localizations.dart';

void main() {
  final date = LocalDate(2027, 1, 2);
  late ScheduleDefinition schedule;
  late Occurrence occurrence;
  setUp(() {
    schedule = ScheduleDefinition.create(
      cycleId: StableId.generate(),
      mode: ScheduleMode.openEndedRecurring,
      timeSemantics: TimeSemantics.allDayLocalDate,
      startDate: date,
      recurrenceRule: RecurrenceRule(
        frequency: RecurrenceFrequency.daily,
        calendar: RecurrenceCalendar.gregorian,
        legacyCalendarSemantics: true,
        dayOfMonth: 2,
        monthOfYear: 1,
        monthEndPolicy: MonthEndPolicy.skip,
      ),
    );
    occurrence = Occurrence(
      id: StableId.generate(),
      cycleId: schedule.cycleId,
      scheduleDefinitionId: schedule.id,
      occurrenceKey: 'anchor',
      originalScheduledAt: date,
      currentScheduledAt: date,
    );
  });

  Future<void> open(
    WidgetTester tester, {
    required SchedulePreview preview,
    required Future<void> Function(ScheduleEditSelection) confirm,
    bool dark = false,
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
        locale: const Locale('fa'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              child: const Text('open'),
              onPressed: () => showDialog<ScheduleEditSelection>(
                context: context,
                builder: (_) => EditScheduleDialog(
                  occurrence: occurrence,
                  recurring: true,
                  schedule: schedule,
                  onPreview: preview,
                  onConfirm: confirm,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String key, String label) async {
    final target = find.byKey(ValueKey(key));
    await tester.ensureVisible(target);
    await tester.tap(target);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> pattern(WidgetTester tester) async {
    await choose(tester, 'schedule-scope', 'این نوبت و نوبت‌های بعد');
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
  }

  RecurrenceEditPreview result(String token) => RecurrenceEditPreview(
    token: token,
    schedule: schedule,
    occurrences: [occurrence],
    boundary: date,
  );

  testWidgets(
    'preview retry, input invalidation, save retry and explicit confirmation preserve draft and anchors',
    (tester) async {
      var previews = 0;
      var writes = 0;
      ScheduleEditSelection? saved;
      await open(
        tester,
        preview: (draft) async {
          previews++;
          expect(draft.previewToken, isNull);
          final rule = draft.recurrenceEdit!.rule;
          expect(rule.calendar, RecurrenceCalendar.gregorian);
          expect(rule.legacyCalendarSemantics, isTrue);
          expect(rule.dayOfMonth, 2);
          expect(rule.monthOfYear, 1);
          expect(rule.monthEndPolicy, MonthEndPolicy.skip);
          if (previews == 1) throw StateError('preview');
          return result('token-$previews');
        },
        confirm: (draft) async {
          writes++;
          saved = draft;
          if (writes == 1) throw StateError('stale');
        },
      );
      expect(find.byKey(const ValueKey('schedule-frequency')), findsNothing);
      await pattern(tester);
      await tester.tap(find.text('پیش‌نمایش تغییرات'));
      await tester.pumpAndSettle();
      expect(find.textContaining('پیش‌نمایش آماده نشد'), findsOneWidget);
      expect(writes, 0);
      await tester.tap(find.text('پیش‌نمایش تغییرات'));
      await tester.pumpAndSettle();
      expect(find.text('تأیید و ثبت تغییرات'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('schedule-interval')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('schedule-interval')),
        '۲',
      );
      await tester.pumpAndSettle();
      expect(find.text('تأیید و ثبت تغییرات'), findsNothing);
      await tester.tap(find.text('پیش‌نمایش تغییرات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید و ثبت تغییرات'));
      await tester.pumpAndSettle();
      expect(find.textContaining('تغییرات ثبت نشد'), findsOneWidget);
      expect(find.byType(EditScheduleDialog), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('schedule-interval')))
            .controller!
            .text,
        '۲',
      );
      await tester.tap(find.text('پیش‌نمایش تغییرات'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید و ثبت تغییرات'));
      await tester.pumpAndSettle();
      expect(saved!.previewToken, 'token-4');
      expect(saved!.recurrenceEdit!.rule.interval, 2);
      expect(writes, 2);
      expect(find.byType(EditScheduleDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'cancel after preview never calls writer; scope change removes recurrence token',
    (tester) async {
      var writes = 0;
      var previews = 0;
      await open(
        tester,
        preview: (_) async {
          previews++;
          return result('cancel');
        },
        confirm: (_) async {
          writes++;
        },
      );
      await pattern(tester);
      await tester.tap(find.text('پیش‌نمایش تغییرات'));
      await tester.pumpAndSettle();
      await choose(tester, 'schedule-scope', 'فقط این نوبت');
      expect(find.byKey(const ValueKey('schedule-frequency')), findsNothing);
      expect(find.text('تأیید و ثبت تغییرات'), findsNothing);
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(previews, 1);
      expect(writes, 0);
    },
  );

  testWidgets(
    'weekly weekdays and total logical count are explicit, only-this stays date-only',
    (tester) async {
      ScheduleEditSelection? saved;
      await open(
        tester,
        preview: (draft) async {
          expect(
            draft.recurrenceEdit!.rule.frequency,
            RecurrenceFrequency.weekly,
          );
          expect(draft.recurrenceEdit!.rule.weekdays, {DateTime.saturday});
          expect(draft.recurrenceEdit!.totalCount, 20);
          expect(draft.recurrenceEdit!.endDate, isNull);
          return result('count');
        },
        confirm: (draft) async {
          saved = draft;
        },
      );
      await pattern(tester);
      await choose(tester, 'schedule-frequency', 'هفتگی');
      await tester.ensureVisible(find.widgetWithText(FilterChip, 'شنبه'));
      await tester.tap(find.widgetWithText(FilterChip, 'شنبه'));
      await tester.pumpAndSettle();
      await choose(tester, 'schedule-termination', 'تعداد کل نوبت‌های برنامه');
      await tester.ensureVisible(find.byKey(const ValueKey('schedule-count')));
      await tester.enterText(
        find.byKey(const ValueKey('schedule-count')),
        '۲۰',
      );
      await tester.tap(find.text('پیش‌نمایش تغییرات'));
      await tester.pumpAndSettle();
      await choose(tester, 'schedule-scope', 'فقط این نوبت');
      await tester.tap(find.text('ذخیرهٔ زمان'));
      await tester.pumpAndSettle();
      expect(saved!.recurrenceEdit, isNull);
      expect(saved!.previewToken, isNull);
      expect(saved!.scope, SeriesEditScope.onlyThis);
      expect(saved!.scheduledAt, date);
    },
  );

  testWidgets(
    'inclusive end date uses staged Jalali selection; opening and cancelling do not save',
    (tester) async {
      var writes = 0;
      ScheduleEditSelection? previewed;
      await open(
        tester,
        preview: (draft) async {
          previewed = draft;
          return result('end-date');
        },
        confirm: (_) async {
          writes++;
        },
      );
      await pattern(tester);
      await choose(
        tester,
        'schedule-termination',
        'تاریخ پایان (شامل این روز)',
      );
      final picker = find.byKey(const ValueKey('schedule-end-date'));
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('انصراف').last);
      await tester.pumpAndSettle();
      expect(previewed, isNull);
      expect(writes, 0);
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید تاریخ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('پیش‌نمایش تغییرات'));
      await tester.pumpAndSettle();
      expect(previewed!.recurrenceEdit!.endDate, date);
      expect(previewed!.recurrenceEdit!.totalCount, isNull);
      expect(writes, 0);
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'narrow RTL ${dark ? 'dark' : 'light'} enlarged text controls scroll without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await open(
          tester,
          dark: dark,
          scale: 1.6,
          preview: (_) async => result('layout'),
          confirm: (_) async {},
        );
        expect(
          Directionality.of(tester.element(find.byType(EditScheduleDialog))),
          TextDirection.rtl,
        );
        await pattern(tester);
        await choose(tester, 'schedule-frequency', 'هفتگی');
        await tester.ensureVisible(find.widgetWithText(FilterChip, 'جمعه'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('انصراف'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
