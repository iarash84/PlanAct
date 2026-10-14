import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reports/application/reports_reader.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';
import 'package:planact/features/reports/presentation/reports_page.dart';
import 'package:planact/features/reports/presentation/report_bar_chart.dart';
import 'package:planact/features/reports/presentation/financial_report_chart.dart';
import 'package:planact/features/reports/data/drift_reports_reader.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

class _Reader implements ReportsReader {
  bool fail = true;
  int reads = 0;
  @override
  Future<ReportSnapshot> read(
    ReportFilter filter, {
    required DateTime now,
    bool includePreviews = false,
  }) async {
    reads++;
    if (fail) throw StateError('injected');
    return const ReportSnapshot();
  }
}

Future<void> chooseReport(WidgetTester tester, PersonalReportKind kind) async {
  final selector = find.byType(DropdownButtonFormField<PersonalReportKind>);
  if (selector.evaluate().isEmpty) {
    final scroll = find
        .descendant(
          of: find.byType(ReportsPage),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(selector, -180, scrollable: scroll);
  }
  if (tester
          .widget<DropdownButtonFormField<PersonalReportKind>>(selector)
          .initialValue ==
      kind) {
    return;
  }
  await tester.ensureVisible(selector);
  await tester.pumpAndSettle();
  await tester.tap(selector);
  await tester.pumpAndSettle();
  final label = find.text(personalReportLabel(kind));
  await tester.scrollUntilVisible(
    label,
    100,
    scrollable: find.byType(Scrollable).last,
  );
  final item = label.last;
  await Scrollable.ensureVisible(tester.element(item), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'SQLite recurring report excludes one-off expense and classifies due time independently',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final expectations = DriftFinancialExpectationRepository(database);
      final create = CreateCommitmentPlan(
        commitments: DriftCommitmentRepository(database),
        plans: DriftCommitmentPlanRepository(database),
        financialExpectations: FinancialExpectationUseCases(expectations),
      );
      await create(
        title: 'اقساط',
        startAt: DateTime(2026, 10, 12, 10),
        kind: CommitmentKind.recurring,
        frequency: RecurrenceFrequency.weekly,
        occurrenceCount: 2,
        financialDirection: FinancialExpectationDirection.outgoing,
        financialAmount: 100,
      );
      await create(
        title: 'خرید یک‌باره',
        startAt: DateTime(2026, 10, 12, 10),
        financialDirection: FinancialExpectationDirection.outgoing,
        financialAmount: 900,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ReportsPage(
              reader: DriftReportsReader(database),
              now: DateTime(2026, 10, 13, 12),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await chooseReport(tester, PersonalReportKind.recurringFinance);
      final scroll = find
          .descendant(
            of: find.byType(ReportsPage),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('روند هزینه‌های تکرارشونده و اقساط'),
        180,
        scrollable: scroll,
      );
      final trend = tester
          .widgetList<FinancialReportChart>(find.byType(FinancialReportChart))
          .firstWhere((chart) => chart.style == FinancialChartStyle.line);
      expect(trend.series.first.values, [200]);
      expect(trend.series.last.values, [0]);
      await tester.scrollUntilVisible(
        find.text('مبلغ تسویه‌شده و باقی‌ماندهٔ تعهدات'),
        -180,
        scrollable: scroll,
      );
      final status = tester
          .widgetList<FinancialReportChart>(find.byType(FinancialReportChart))
          .firstWhere((chart) => chart.style == FinancialChartStyle.stacked);
      expect(status.series.map((s) => s.values.single), [0, 0, 100, 100]);
      expect((await expectations.listExpectations()).length, 3);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'report opens Details directly and rereads durable edits on return',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final commitments = DriftCommitmentRepository(database);
      await CreateCommitmentPlan(
        commitments: commitments,
        plans: DriftCommitmentPlanRepository(database),
      )(title: 'عنوان قبلی', startAt: DateTime.now());
      await tester.pumpWidget(PlanActApp(repository: commitments));
      await tester.pumpAndSettle();
      await tester.tap(find.text('بیشتر'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('گزارش‌ها'));
      await tester.pumpAndSettle();
      final scroll = find
          .descendant(
            of: find.byType(ReportsPage),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('برنامه‌ریزی‌شده: ۱'),
        150,
        scrollable: scroll,
      );
      await Scrollable.ensureVisible(
        tester.element(find.text('برنامه‌ریزی‌شده: ۱')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('برنامه‌ریزی‌شده: ۱'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('عنوان قبلی'),
        100,
        scrollable: scroll,
      );
      await tester.tap(find.text('عنوان قبلی'));
      await tester.pumpAndSettle();
      expect(find.byType(CommitmentDetailsPage), findsOneWidget);
      expect(find.text('جزئیات و ویرایش'), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, 'عنوان'),
        'عنوان تازه',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'ذخیره'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.widgetWithText(FilledButton, 'ذخیره'));
      await tester.pumpAndSettle();
      if (find.byType(CommitmentDetailsPage).evaluate().isNotEmpty) {
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
      }
      expect(find.byType(ReportsPage), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('عنوان تازه'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(ReportsPage),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('عنوان تازه'), findsOneWidget);
      expect(find.text('عنوان قبلی'), findsNothing);
      expect((await commitments.list()).single.title, 'عنوان تازه');
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
  testWidgets(
    'loading failure is distinct from empty; retry and date cancellation do not write',
    (tester) async {
      final reader = _Reader();
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          builder: (_, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: ReportsPage(reader: reader, now: DateTime(2026, 10, 13)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('گزارش بارگیری نشد؛ دوباره تلاش کنید.'), findsOneWidget);
      expect(
        find.text('نوبت ثبت‌شده‌ای با این فیلترها وجود ندارد.'),
        findsNothing,
      );
      reader.fail = false;
      await tester.tap(find.text('تلاش دوباره'));
      await tester.pumpAndSettle();
      expect(
        find.text('نوبت ثبت‌شده‌ای با این فیلترها وجود ندارد.'),
        findsOneWidget,
      );
      final reads = reader.reads;
      await tester.tap(find.byType(OutlinedButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(reader.reads, reads);
    },
  );
  for (final dark in [false, true]) {
    testWidgets(
      'More reports route uses SQLite; tag filters totals and details; refresh ($dark)',
      (tester) async {
        final database = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(database.close);
        final finance = DriftFinanceRepository(database),
            tags = DriftTagRepository(database);
        await AppSettings(database)
            .writeThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'نقدی',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        );
        await finance.saveAccount(account);
        Future<AccountEntry> add(int amount, String note) async {
          final entry = AccountEntry(
            id: StableId.generate(),
            accountId: account.id,
            type: AccountEntryType.expense,
            amount: Money(minorUnits: amount, currency: 'IRR'),
            occurredAt: DateTime.now(),
            note: note,
          );
          await finance.saveEntry(entry);
          return entry;
        }

        final tagged = await add(100, 'هزینهٔ ورزش');
        await add(900, 'هزینهٔ دیگر');
        final tag = await tags.getOrCreate('ورزش');
        await tags.attach(
          recordId: tagged.id.value,
          tag: tag,
          type: TaggableType.accountEntry,
        );
        await tester.pumpWidget(
          PlanActApp(repository: DriftCommitmentRepository(database)),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('بیشتر'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('گزارش‌ها'));
        await tester.pumpAndSettle();
        expect(find.byType(ReportsPage), findsOneWidget);
        expect(
          Directionality.of(tester.element(find.byType(ReportsPage))),
          TextDirection.rtl,
        );
        await chooseReport(tester, PersonalReportKind.cashFlow);
        final scroll = find
            .descendant(
              of: find.byType(ReportsPage),
              matching: find.byType(Scrollable),
            )
            .first;
        await tester.scrollUntilVisible(
          find.text('خروجی: ۱,۰۰۰ ریال'),
          180,
          scrollable: scroll,
        );
        expect(find.text('خروجی: ۱,۰۰۰ ریال'), findsOneWidget);
        ReportBarChart cashChart() => tester
            .widgetList<ReportBarChart>(find.byType(ReportBarChart))
            .firstWhere((chart) => chart.title == 'مقایسهٔ دخل‌وخرج');
        expect(cashChart().data.map((d) => d.value), [0, 1000, -1000]);
        FinancialReportChart sharesChart() => tester
            .widgetList<FinancialReportChart>(find.byType(FinancialReportChart))
            .firstWhere((chart) => chart.style == FinancialChartStyle.donut);
        Future<void> expectShares(int amount) async {
          await tester.scrollUntilVisible(
            find.text('سهم دسته‌های هزینه — IRR'),
            -180,
            scrollable: scroll,
          );
          expect(sharesChart().series.single.values, [amount]);
        }

        await expectShares(1000);
        await tester.scrollUntilVisible(
          find.text('مقایسهٔ دوره‌ها — IRR'),
          -180,
          scrollable: scroll,
        );
        final periods = tester
            .widgetList<FinancialReportChart>(find.byType(FinancialReportChart))
            .firstWhere((chart) => chart.title.startsWith('مقایسهٔ دوره‌ها'));
        expect(periods.series[1].values, [0, 1000]);
        await tester.scrollUntilVisible(
          find.text('فیلترهای گزارش'),
          -180,
          scrollable: scroll,
        );
        await tester.tap(find.text('فیلترهای گزارش'));
        await tester.pumpAndSettle();
        final chip = find.widgetWithText(FilterChip, '#ورزش');
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('خروجی: ۱۰۰ ریال'),
          180,
          scrollable: scroll,
        );
        expect(find.text('خروجی: ۱۰۰ ریال'), findsOneWidget);
        expect(cashChart().data.map((d) => d.value), [0, 100, -100]);
        expect(find.text('هزینهٔ دیگر'), findsNothing);
        expect(find.text('هزینهٔ ورزش'), findsWidgets);
        await expectShares(100);
        final extra = await add(50, 'ورزش دوم');
        await tags.attach(
          recordId: extra.id.value,
          tag: tag,
          type: TaggableType.accountEntry,
        );
        await tester.tap(find.byTooltip('تازه‌کردن گزارش'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('خروجی: ۱۵۰ ریال'),
          180,
          scrollable: scroll,
        );
        expect(find.text('خروجی: ۱۵۰ ریال'), findsOneWidget);
        expect(cashChart().data.map((d) => d.value), [0, 150, -150]);
        await expectShares(150);
        await chooseReport(tester, PersonalReportKind.accounts);
        await tester.scrollUntilVisible(
          find.text('روند موجودی پایان روز از کل دفتر'),
          180,
          scrollable: scroll,
        );
        final balanceLine = tester
            .widgetList<FinancialReportChart>(find.byType(FinancialReportChart))
            .firstWhere((chart) => chart.style == FinancialChartStyle.line);
        expect(balanceLine.series.single.values.last, -1050);
        expect((await finance.listEntries()).length, 3);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  testWidgets('all report types support narrow large text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final reader = _Reader()..fail = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: PlanActTheme.dark(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.8)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
        home: ReportsPage(reader: reader, now: DateTime(2026, 10, 13)),
      ),
    );
    await tester.pumpAndSettle();
    for (final kind in PersonalReportKind.values) {
      await chooseReport(tester, kind);
      expect(tester.takeException(), isNull, reason: kind.name);
    }
  });
}
