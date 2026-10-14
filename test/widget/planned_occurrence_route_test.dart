import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' hide Commitment;
import 'package:planact/features/calendar/presentation/planned_occurrence_widgets.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

// Inject a root refresh read failure, not a fake Details onSaved callback.
class _RefreshFailingCommitments extends DriftCommitmentRepository {
  _RefreshFailingCommitments(super.database);
  bool failRefresh = false;
  int failedReads = 0;

  @override
  Future<List<Commitment>> list() async {
    if (failRefresh) {
      failedReads++;
      throw StateError('Injected root refresh read failure');
    }
    return super.list();
  }
}

// Acceptance: actual root Add -> durable monthly count -> pushed Details ->
// far preview -> cancel / transactional failure / retry -> recorded refresh.
// Calendar Month and Week browse a separate far slot without writing it.
// Native delivery, backup, scale budgets and independent review are separate.
void main() {
  for (final dark in [false, true]) {
    testWidgets('root hybrid preview journey ${dark ? 'Dark' : 'Light'}', (
      tester,
    ) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final commitments = _RefreshFailingCommitments(db);
      final plans = DriftCommitmentPlanRepository(db);
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(() async {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        await tester.runAsync(db.close);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
          builder: (context, child) => Directionality(
            textDirection: TextDirection.rtl,
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
          ),
          home: HomeShell(repository: commitments, planRepository: plans),
        ),
      );
      await _drain(tester);
      await _tap(tester, find.byTooltip('افزودن سریع'));
      await _tap(tester, find.byKey(const ValueKey('quick-add-commitment')));
      await tester.enterText(
        find.byKey(const ValueKey('commitment-title-field')),
        'برنامه بلندمدت',
      );
      await _choose(
        tester,
        find.byKey(const ValueKey('commitment-kind-dropdown')),
        'تکرارشونده',
      );
      await _choose(
        tester,
        find.byType(DropdownButtonFormField<RecurrenceFrequency>),
        'ماهانه',
      );
      await _choose(
        tester,
        find.byKey(const ValueKey('recurrence-calendar')),
        'شمسی',
      );
      await _tap(tester, find.text('انتخاب تاریخ'));
      await _tap(tester, find.byKey(const ValueKey('capture-date-19')));
      await _tap(tester, find.text('تأیید تاریخ'));
      await _tap(tester, find.text('انتخاب زمان'));
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();
      await _choose(
        tester,
        find.byKey(const ValueKey('recurrence-termination')),
        'تعداد مشخص',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('recurrence-count')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('recurrence-count')),
        '۶۰',
      );
      await _tap(tester, find.text('ثبت تعهد'));
      await _drain(tester);
      late Commitment item;
      late int initial;
      await tester.runAsync(() async {
        item = (await commitments.list()).single;
        initial = (await db.select(db.occurrences).get()).length;
        expect(initial, lessThan(60));
        expect(
          (await plans.findByCommitmentId(item.id))!.schedule.occurrenceCount,
          60,
        );
      });
      await _tap(tester, find.byTooltip('گزینه‌های بیشتر'));
      await _tap(tester, find.text('خط زمانی تعهدات'));
      await _tap(tester, find.widgetWithText(ListTile, item.title).last);
      await tester.scrollUntilVisible(
        find.text('جزئیات و ویرایش'),
        200,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
      );
      await _tap(tester, find.text('جزئیات و ویرایش'));
      await _drain(tester);
      await tester.scrollUntilVisible(
        find.textContaining('تعداد کل برنامه:'),
        200,
        scrollable: find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .last,
      );
      expect(find.text('تعداد کل برنامه: ۶۰ نوبت'), findsOneWidget);
      for (var i = 0; i < 24; i++) {
        await _tap(tester, find.byTooltip('ماه بعد نوبت‌ها'));
        await _drain(tester);
      }
      await tester.ensureVisible(find.byType(PlannedSlotTile));
      final slot = tester
          .widget<PlannedSlotTile>(find.byType(PlannedSlotTile))
          .slot;
      expect(find.text('پیش‌نمایش برنامه'), findsOneWidget);
      await tester.runAsync(() async {
        expect((await db.select(db.occurrences).get()).length, initial);
      });
      await _tap(tester, find.byTooltip('ثبت نوبت'));
      await _tap(tester, find.text('انصراف').last);
      await tester.runAsync(() async {
        expect((await db.select(db.occurrences).get()).length, initial);
        await db.customStatement(
          "CREATE TRIGGER fail_preview BEFORE INSERT ON occurrences BEGIN SELECT RAISE(ABORT, 'injected'); END",
        );
      });
      await _tap(tester, find.byTooltip('ثبت نوبت'));
      await _tap(tester, find.text('تأیید و ثبت نوبت'));
      await _drain(tester);
      expect(find.textContaining('ثبت نوبت انجام نشد'), findsOneWidget);
      expect(find.byType(PlannedSlotTile), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        expect((await db.select(db.occurrences).get()).length, initial);
        await db.customStatement('DROP TRIGGER fail_preview');
      });
      commitments.failRefresh = true;
      await _tap(tester, find.byTooltip('ثبت نوبت'));
      await _tap(tester, find.text('تأیید و ثبت نوبت'));
      await _drain(tester);
      expect(find.byType(PlannedSlotTile), findsNothing);
      expect(commitments.failedReads, 1);
      expect(
        find.text(
          'نوبت ثبت شد؛ تازه‌سازی انجام نشد. دوباره فهرست را بارگذاری کنید.',
        ),
        findsOneWidget,
      );
      expect(find.text('نوبت ثبت شد.'), findsNothing);
      expect(find.textContaining('ثبت نوبت انجام نشد'), findsNothing);
      await tester.runAsync(() async {
        expect((await db.select(db.occurrences).get()).length, initial + 1);
        final saved = (await plans.findByCommitmentId(item.id))!;
        expect(
          saved.occurrences.any((o) => o.occurrenceKey == slot.occurrenceKey),
          isTrue,
        );
        expect(saved.schedule.occurrenceCount, 60);
      });
      await _tap(tester, find.byType(BackButton));
      await tester.binding.handlePopRoute();
      await _drain(tester);
      await _tap(tester, find.text('امروز').last);
      await _drain(tester);
      expect(
        find.text('بارگذاری اقدامات انجام نشد؛ دوباره تلاش کنید.'),
        findsOneWidget,
      );
      commitments.failRefresh = false;
      // Recover through the real root retry action, without preparing again.
      await _tap(tester, find.text('تلاش دوباره'));
      expect(
        find.text('بارگذاری اقدامات انجام نشد؛ دوباره تلاش کنید.'),
        findsNothing,
      );
      await tester.runAsync(() async {
        expect((await db.select(db.occurrences).get()).length, initial + 1);
      });
      await _tap(tester, find.text('تقویم').last);
      expect(find.byKey(const ValueKey('calendar-pick-date')), findsNothing);
      await _tap(tester, find.text('هفته'));
      await _tap(tester, find.byKey(const ValueKey('calendar-pick-date')));
      // A different, still-unrecorded date 25 months away.
      for (var i = 0; i < 25; i++) {
        await _tap(tester, find.byTooltip('ماه بعد').last);
      }
      await _tap(tester, find.byKey(const ValueKey('capture-date-19')));
      await _tap(tester, find.text('تأیید تاریخ'));
      await _drain(tester);
      await _tap(tester, find.text('ماه'));
      await tester.scrollUntilVisible(
        find.byType(PlannedSlotTile),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(PlannedSlotTile), findsWidgets);
      expect(find.textContaining('پیش‌نمایش برنامه'), findsWidgets);
      await tester.drag(find.byType(ListView).last, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await _tap(tester, find.text('هفته'));
      await _drain(tester);
      await tester.scrollUntilVisible(
        find.byType(PlannedSlotTile),
        200,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('week-agenda-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.byType(PlannedSlotTile), findsWidgets);
      await tester.runAsync(() async {
        expect((await db.select(db.occurrences).get()).length, initial + 1);
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await _drain(tester);
}

Future<void> _choose(WidgetTester tester, Finder finder, String label) async {
  await _tap(tester, finder);
  await _tap(tester, find.text(label).last);
}

Future<void> _drain(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}
