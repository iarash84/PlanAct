import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

CreateCommitmentPlan command(AppDatabase db) => CreateCommitmentPlan(
  commitments: DriftCommitmentRepository(db),
  plans: DriftCommitmentPlanRepository(db),
  financialExpectations: FinancialExpectationUseCases(
    DriftFinancialExpectationRepository(db),
  ),
);

void main() {
  for (final direction in FinancialExpectationDirection.values) {
    test('explicit $direction account survives reopen and rolling', () async {
      final directory = await Directory.systemTemp.createTemp(
        'creation-account-',
      );
      final file = File('${directory.path}/live.sqlite');
      var db = AppDatabase.forTesting(NativeDatabase(file));
      try {
        final first = StableId.generate();
        final selected = StableId.generate();
        for (final id in [first, selected]) {
          await db.customStatement(
            "INSERT INTO financial_accounts (id, name, currency, type, status) VALUES (?, 'حساب', 'IRR', 0, 0)",
            [id.value],
          );
        }
        final plan = await command(db)(
          title: 'انتظار مالی',
          startAt: DateTime(2025, 1, 1, 18),
          kind: CommitmentKind.recurring,
          frequency: RecurrenceFrequency.monthly,
          financialDirection: direction,
          financialAmount: 12345,
          financialAccountId: selected,
        );
        final old = await db.select(db.financialExpectations).get();
        expect(old, isNotEmpty);
        expect(old.every((row) => row.accountId == selected.value), isTrue);
        await db.close();
        db = AppDatabase.forTesting(NativeDatabase(file));
        final repository = DriftCommitmentPlanRepository(db);
        final restored = (await repository.findByCommitmentId(
          plan.commitment.id,
        ))!;
        expect(
          restored.schedule.generationFinancialExpectation!.accountId,
          selected,
        );
        final added = await repository.extendRecurringSchedules(
          LocalDate(2026, 1, 1),
        );
        expect(added, greaterThan(0));
        final all = await db.select(db.financialExpectations).get();
        expect(all, hasLength(old.length + added));
        expect(
          all.every(
            (row) =>
                row.accountId == selected.value &&
                row.direction == direction.index &&
                row.minorUnits == 12345,
          ),
          isTrue,
        );
        for (final row in old) {
          expect(all.singleWhere((item) => item.id == row.id), row);
        }
        expect(await db.select(db.accountEntries).get(), isEmpty);
      } finally {
        await db.close();
        await directory.delete(recursive: true);
      }
    });
  }

  test('accountless expectation remains valid', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    try {
      await command(db)(
        title: 'پرداخت',
        startAt: DateTime(2026, 1, 1),
        financialDirection: FinancialExpectationDirection.outgoing,
        financialAmount: 100,
      );
      expect(
        (await db.select(db.financialExpectations).get()).single.accountId,
        isNull,
      );
      expect(await db.select(db.accountEntries).get(), isEmpty);
    } finally {
      await db.close();
    }
  });

  for (final invalid in ['missing', 'archived', 'currency']) {
    test('$invalid account rejects creation atomically', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      try {
        final id = StableId.generate();
        if (invalid != 'missing') {
          await db.customStatement(
            "INSERT INTO financial_accounts (id, name, currency, type, status) VALUES (?, 'حساب', ?, 0, ?)",
            [
              id.value,
              invalid == 'currency' ? 'USD' : 'IRR',
              invalid == 'archived' ? 1 : 0,
            ],
          );
        }
        await expectLater(
          command(db)(
            title: 'پرداخت',
            startAt: DateTime(2026, 1, 1),
            financialDirection: FinancialExpectationDirection.outgoing,
            financialAmount: 100,
            financialAccountId: id,
          ),
          throwsA(anything),
        );
        expect(await db.select(db.commitments).get(), isEmpty);
        expect(await db.select(db.occurrences).get(), isEmpty);
        expect(await db.select(db.financialExpectations).get(), isEmpty);
      } finally {
        await db.close();
      }
    });
  }
}
