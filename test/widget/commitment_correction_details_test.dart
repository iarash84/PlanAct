import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';
import 'package:planact/features/sessions/data/drift_session_repositories.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';

import '../repository/commitment_correction_test.dart' as fixtures;

void main() {
  testWidgets(
    'Details retains input on preview cancellation/error and confirms independent credit',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final fixture = await fixtures.seed(database, consumed: true);
      final plans = DriftCommitmentPlanRepository(database);
      var refreshes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: CommitmentDetailsPage(
              commitment: fixture.commitment,
              repository: DriftCommitmentRepository(database),
              planRepository: plans,
              expectationRepository: DriftFinancialExpectationRepository(
                database,
              ),
              occurrenceExecutor: PersistedOccurrenceActionExecutor(
                plans: plans,
              ),
              onSaved: () async {
                refreshes++;
              },
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final title = find.text('اصلاح تعداد برنامه أو اعتبار بسته');
      final actualTitle = find.text('اصلاح تعداد برنامه یا اعتبار بسته');
      expect(title, findsNothing);
      await tester.scrollUntilVisible(
        actualTitle,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(actualTitle);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(DropdownButtonFormField<bool>));
      await tester.tap(find.byType(DropdownButtonFormField<bool>));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('افزایش یا کاهش اعتبار بسته').last);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final reason = find.widgetWithText(TextField, 'دلیل اصلاح');
      final value = find.widgetWithText(
        TextField,
        'تغییر اعتبار (مثلاً ۲ یا ۲-)',
      );
      await tester.enterText(value, '2');
      await tester.enterText(reason, 'اصلاح خرید');
      await tester.ensureVisible(find.text('بررسی اثر اصلاح'));
      await tester.tap(find.text('بررسی اثر اصلاح'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('پیش‌نمایش اصلاح'), findsOneWidget);
      await tester.tap(find.text('ادامهٔ ویرایش'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.widget<TextField>(value).controller!.text, '2');
      expect(
        (await DriftEntitlementLedgerRepository(database)
                .listByPlan(fixture.entitlement.id))
            .length,
        2,
      );
      await tester.enterText(value, '-4');
      await tester.tap(find.text('بررسی اثر اصلاح'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.textContaining('از اعتبار باقی‌مانده بیشتر'), findsOneWidget);
      expect(tester.widget<TextField>(value).controller!.text, '-4');
      await tester.enterText(value, '-1');
      await tester.tap(find.text('بررسی اثر اصلاح'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('تأیید اصلاح'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump(const Duration(milliseconds: 500));
      final entries = await DriftEntitlementLedgerRepository(database)
          .listByPlan(fixture.entitlement.id);
      expect(const EntitlementLedger().remaining(entries), 2);
      expect(
        (await plans.findByCommitmentId(fixture.commitment.id))!
            .schedule
            .occurrenceCount,
        4,
      );
      expect(refreshes, 1);
      expect(find.text('اصلاح ثبت شد؛ سوابق قبلی محفوظ است.'), findsOneWidget);
    },
  );
}
