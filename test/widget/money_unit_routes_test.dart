import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/presentation/financial_expectation_editor.dart';

class _Amount extends StatelessWidget {
  const _Amount();
  @override
  Widget build(BuildContext context) => Text(
    PersianMoneyText.amount(-11, 'IRR', unit: MoneyUnitScope.of(context)),
  );
}

void main() {
  testWidgets('production root scope reaches pushed routes and modal sheets', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(
      PlanActApp(repository: DriftCommitmentRepository(db)),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(HomeShell));
    final controller = MoneyUnitScope.controllerOf(context)!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const Scaffold(body: _Amount())),
    );
    await tester.pumpAndSettle();
    expect(find.text('-۱۱ ریال'), findsOneWidget);
    await tester.runAsync(() => controller.select(IranianMoneyUnit.toman));
    await tester.pumpAndSettle();
    expect(find.text('-۱٫۱ تومان'), findsOneWidget);
    final routeContext = tester.element(find.byType(_Amount));
    showModalBottomSheet<void>(
      context: routeContext,
      builder: (_) => const _Amount(),
    );
    await tester.pumpAndSettle();
    expect(find.text('-۱٫۱ تومان'), findsNWidgets(2));
    await tester.runAsync(() => controller.select(IranianMoneyUnit.rial));
    await tester.pumpAndSettle();
    expect(find.text('-۱۱ ریال'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets(
    'open expectation form retains text and pinned toman conversion',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final controller = MoneyUnitController(AppSettings(db));
      await controller.load();
      await controller.select(IranianMoneyUnit.toman);
      final useCases = FinancialExpectationUseCases(
        DriftFinancialExpectationRepository(db),
      );
      final plan = await CreateCommitmentPlan(
        commitments: DriftCommitmentRepository(db),
        plans: DriftCommitmentPlanRepository(db),
      )(title: 'آزمون', startAt: DateTime(2026, 10, 11));
      final id = plan.occurrences.single.id;
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) =>
              MoneyUnitScope(controller: controller, child: child!),
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinancialExpectationEditor(
                occurrenceId: id,
                useCases: useCases,
                accounts: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('انتظار مالی این نوبت'));
      await tester.pumpAndSettle();
      final amount = find.widgetWithText(TextField, 'مبلغ به تومان');
      await tester.enterText(amount, '12.3');
      await tester.runAsync(() => controller.select(IranianMoneyUnit.rial));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(amount).controller!.text, '12.3');
      await tester.ensureVisible(find.text('ذخیرهٔ انتظار'));
      await tester.tap(find.text('ذخیرهٔ انتظار'));
      await tester.pumpAndSettle();
      final saved = await useCases.getByOccurrence(id);
      expect(saved!.amount, 123);
      expect(saved.currency, 'IRR');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      await db.close();
    },
  );
}
