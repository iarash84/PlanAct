import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';

class _Platform implements ReminderPlatformAdapter {
  @override
  Future<void> cancel(ReminderInstance instance) async {}
  @override
  Future<void> schedule(ReminderInstance instance) async {}
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Details reminder edit persists day presets and refreshes its row',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async {
        await tester.runAsync(db.close);
      });
      final commitments = DriftCommitmentRepository(db);
      final plans = DriftCommitmentPlanRepository(db);
      final repository = DriftReminderRepository(db);
      final service = ReminderService(
        repository: repository,
        platform: _Platform(),
      );
      late CommitmentPlan plan;
      await tester.runAsync(() async {
        plan =
            await CreateCommitmentPlan(
              commitments: commitments,
              plans: plans,
              reminderService: service,
            )(
              title: 'تمدید بیمه',
              startAt: DateTime.now(),
              reminderOffsets: [const Duration(minutes: 15)],
            );
      });
      var refreshes = 0;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: CommitmentDetailsPage(
            commitment: plan.commitment,
            repository: commitments,
            planRepository: plans,
            expectationRepository: DriftFinancialExpectationRepository(db),
            occurrenceExecutor: PersistedOccurrenceActionExecutor(
              plans: plans,
              reminders: service,
            ),
            onSaved: () async {
              refreshes++;
            },
          ),
        ),
      );
      await _settle(tester);
      final edit = find.byTooltip('ویرایش یادآوری‌ها');
      await tester.scrollUntilVisible(
        edit,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await _settle(tester);
      await tester.ensureVisible(edit);
      await tester.pumpAndSettle();
      await tester.tap(edit);
      await _settle(tester);
      for (final label in ['۳ روز قبل', '۱۰ روز قبل']) {
        final chip = find.widgetWithText(ActionChip, label);
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('ذخیرهٔ یادآوری‌ها'));
      await _settle(tester);
      expect(refreshes, 1);
      expect(find.textContaining('۳ روز قبل از شروع'), findsOneWidget);
      expect(find.textContaining('۱۰ روز قبل از شروع'), findsOneWidget);
      await tester.runAsync(() async {
        expect(
          (await repository.listRules())
              .where((r) => r.enabled)
              .map((r) => r.offset),
          unorderedEquals([
            const Duration(minutes: -15),
            const Duration(days: -3),
            const Duration(days: -10),
          ]),
        );
      });
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
