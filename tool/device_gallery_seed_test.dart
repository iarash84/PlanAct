// Explicit local operator tool; never included in application startup.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/sessions/data/drift_session_repositories.dart';

void main() {
  test('append explicit synthetic gallery data to an operator-owned copy', () async {
    final path = Platform.environment['PLANACT_GALLERY_DATABASE'];
    final date = Platform.environment['PLANACT_GALLERY_DATE'];
    if (path == null || date == null) {
      throw StateError(
        'Set PLANACT_GALLERY_DATABASE and PLANACT_GALLERY_DATE explicitly.',
      );
    }
    if (!path
        .replaceAll('\\', '/')
        .contains('/build/verification/device-gallery/')) {
      throw StateError('Only a local gallery working copy is permitted.');
    }
    final day = DateTime.parse(date);
    final database = AppDatabase(NativeDatabase(File(path)));
    try {
      final commitments = DriftCommitmentRepository(database);
      final financeRepository = DriftFinanceRepository(database);
      final finance = FinanceUseCases(financeRepository);
      final create = CreateCommitmentPlan(
        commitments: commitments,
        plans: DriftCommitmentPlanRepository(database),
        entitlements: DriftEntitlementPlanRepository(database),
        financialExpectations: FinancialExpectationUseCases(
          DriftFinancialExpectationRepository(database),
        ),
      );
      final existing = await commitments.list();
      // One atomic dataset; retries never append a second set.
      if (existing.any((item) => item.title == 'آزمایشی: کلاس زبان')) return;
      await database.transaction(() async {
        for (final item in [
          ('کلاس زبان', 0, 18, RecurrenceFrequency.weekly, 8, 2400000),
          ('تمرین موسیقی', 1, 17, RecurrenceFrequency.weekly, 4, 1500000),
          ('جلسه شنا', 2, 16, RecurrenceFrequency.weekly, 10, 900000),
          ('پرداخت اینترنت', -2, 12, RecurrenceFrequency.monthly, 3, 450000),
        ]) {
          await create(
            title: 'آزمایشی: ${item.$1}',
            description:
                'اطلاعات ساختگی برای تست و تصاویر مستندات؛ فاقد اطلاعات شخصی.',
            startAt: day.add(Duration(days: item.$2, hours: item.$3)),
            kind: CommitmentKind.recurring,
            frequency: item.$4,
            occurrenceCount: item.$5,
            entitlementUnits: item.$4 == RecurrenceFrequency.weekly
                ? item.$5
                : null,
            financialDirection: FinancialExpectationDirection.outgoing,
            financialAmount: item.$6,
          );
        }
        for (final item in [
          ('مطالعه کتاب', 0, 20),
          ('ویزیت دندان‌پزشکی', 3, 11),
          ('تحویل پروژه', -1, 9),
        ]) {
          await create(
            title: 'آزمایشی: ${item.$1}',
            startAt: day.add(Duration(days: item.$2, hours: item.$3)),
          );
        }
        final bank = FinancialAccount(
          id: StableId.generate(),
          name: 'آزمایشی: بانک ملت',
          currency: 'IRR',
          type: FinancialAccountType.bank,
          bank: IranianBank.mellat,
        );
        final cash = FinancialAccount(
          id: StableId.generate(),
          name: 'آزمایشی: کیف پول نقد',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        );
        await finance.createAccount(
          bank,
          openingBalance: const Money(minorUnits: 80000000, currency: 'IRR'),
          occurredAt: day.subtract(const Duration(days: 20)),
        );
        await finance.createAccount(
          cash,
          openingBalance: const Money(minorUnits: 5000000, currency: 'IRR'),
          occurredAt: day.subtract(const Duration(days: 20)),
        );
        for (var i = 0; i < 12; i++) {
          await finance.record(
            account: bank,
            type: i % 4 == 0
                ? AccountEntryType.income
                : AccountEntryType.expense,
            amount: Money(
              minorUnits: i % 4 == 0 ? 18000000 : (i + 1) * 350000,
              currency: 'IRR',
            ),
            occurredAt: day.subtract(Duration(days: 12 - i)),
            note: 'آزمایشی: تراکنش ساختگی ${i + 1}',
            category: i % 4 == 0
                ? 'درآمد آزمایشی'
                : ['آموزش', 'خرید', 'رفت‌وآمد'][i % 3],
          );
        }
        await finance.transfer(
          from: bank,
          to: cash,
          amount: const Money(minorUnits: 2000000, currency: 'IRR'),
          occurredAt: day.subtract(const Duration(days: 1)),
        );
      });
      expect((await commitments.list()).length, existing.length + 7);
      expect(
        (await database.customSelect('PRAGMA foreign_key_check').get()),
        isEmpty,
      );
      expect(
        (await database.customSelect('PRAGMA integrity_check').get())
            .single
            .data
            .values
            .single,
        'ok',
      );
    } finally {
      await database.close();
    }
  });
}
