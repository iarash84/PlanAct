import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/today/presentation/today_page.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  testWidgets(
    'root startup and resume extend durable Persian schedule and refresh consumers',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final commitments = DriftCommitmentRepository(database);
      final plans = DriftCommitmentPlanRepository(database);
      final now = DateTime.now();
      final j = Gregorian(now.year, now.month, now.day).toJalali();
      final old = Jalali(j.year - 2, j.month, j.day).toGregorian();
      late CommitmentPlan plan;
      await tester.runAsync(() async {
        plan =
            await CreateCommitmentPlan(commitments: commitments, plans: plans)(
              title: 'تکرار ماهانه پایدار',
              kind: CommitmentKind.recurring,
              startAt: DateTime(old.year, old.month, old.day, 18),
              frequency: RecurrenceFrequency.monthly,
              recurrenceCalendar: RecurrenceCalendar.jalali,
            );
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: HomeShell(repository: commitments, planRepository: plans),
          ),
        ),
      );
      for (var i = 0; i < 15; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      final today = tester.widget<TodayPage>(find.byType(TodayPage));
      expect(
        today.scheduledDates[plan.commitment.id.value]!.any(
          (d) => d.year == now.year && d.month == now.month && d.day == now.day,
        ),
        isTrue,
      );
      await tester.tap(find.text('تقویم').last);
      await tester.pumpAndSettle();
      final calendar = tester.widget<CalendarPage>(
        find.byType(CalendarPage, skipOffstage: false),
      );
      expect(
        calendar.scheduledDates[plan.commitment.id.value]!.any(
          (d) => d.year == now.year && d.month == now.month && d.day == now.day,
        ),
        isTrue,
      );
      var count = 0;
      await tester.runAsync(() async {
        count = (await database.select(database.occurrences).get()).length;
      });
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.runAsync(() async {
        expect(
          await database.select(database.occurrences).get(),
          hasLength(count),
        );
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await database.close();
      });
      expect(tester.takeException(), isNull);
    },
  );
}
