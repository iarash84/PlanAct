import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/domain/tag.dart';
import 'package:planact/features/reports/presentation/report_movement_list.dart';
import 'package:planact/features/finance/presentation/transaction_direction.dart';
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
  ReportSnapshot snapshot = const ReportSnapshot();
  @override
  Future<ReportSnapshot> read(
    ReportFilter filter, {
    required DateTime now,
    bool includePreviews = false,
  }) async {
    reads++;
    if (fail) throw StateError('injected');
    return snapshot;
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
  for (final dark in [false, true]) {
    testWidgets(
      'report cards show direct tags, ledger direction and section gaps ($dark)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب نقدی خانواده با نام طولانی برای بررسی شکست متن',
          currency: 'IRR',
          type: FinancialAccountType.cash,
        );
        final tags = [
          Tag(
            id: StableId.generate(),
            label: 'ورزش',
            createdAt: DateTime(2026, 10, 13),
          ),
          Tag(
            id: StableId.generate(),
            label: 'خانواده',
            createdAt: DateTime(2026, 10, 13),
          ),
        ];
        final entries = [
          for (final type in [
            AccountEntryType.income,
            AccountEntryType.expense,
            AccountEntryType.transferIn,
            AccountEntryType.transferOut,
            AccountEntryType.reversal,
          ])
            AccountEntry(
              id: StableId.generate(),
              accountId: account.id,
              type: type,
              amount: Money(
                minorUnits: type == AccountEntryType.reversal ? -100 : 100,
                currency: 'IRR',
              ),
              occurredAt: DateTime(2026, 10, 13),
              note: type == AccountEntryType.reversal
                  ? null
                  : 'عنوان بلند تراکنش برای بررسی شکست طبیعی متن',
            ),
        ];
        final reader = _Reader()
          ..fail = false
          ..snapshot = ReportSnapshot(
            accounts: [account],
            entries: entries,
            tags: tags,
            entryTags: {entries.first.id: tags.map((t) => t.id).toSet()},
          );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.8)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
            ),
            home: ReportsPage(reader: reader, now: DateTime(2026, 10, 13)),
          ),
        );
        await tester.pumpAndSettle();
        await chooseReport(tester, PersonalReportKind.accounts);
        final scroll = find
            .descendant(
              of: find.byType(ReportsPage),
              matching: find.byType(Scrollable),
            )
            .first;
        final list = find.byType(ReportMovementList);
        await tester.scrollUntilVisible(list, 220, scrollable: scroll);
        final cards = find.descendant(of: list, matching: find.byType(Card));
        expect(cards, findsNWidgets(5));
        expect(
          find.descendant(of: cards, matching: find.text('#ورزش')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: cards, matching: find.text('#خانواده')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: cards,
            matching: find.byType(TransactionDirectionIcon),
          ),
          findsNWidgets(5),
        );
        expect(
          find.descendant(of: cards, matching: find.byIcon(Icons.south_west)),
          findsNWidgets(2),
        );
        expect(
          find.descendant(of: cards, matching: find.byIcon(Icons.north_east)),
          findsNWidgets(3),
        );
        expect(
          find.descendant(
            of: cards,
            matching: find.byIcon(Icons.account_balance_wallet_outlined),
          ),
          findsNWidgets(5),
        );
        expect(
          find.descendant(
            of: cards,
            matching: find.byIcon(Icons.calendar_today_outlined),
          ),
          findsNWidgets(5),
        );
        expect(
          find.descendant(of: cards, matching: find.byType(Divider)),
          findsNWidgets(5),
        );
        for (final entry in entries) {
          final card = find.byKey(ValueKey('report-transaction:${entry.id}'));
          final type = find.descendant(
            of: card,
            matching: find.text(transactionLabel(entry)),
          );
          expect(type, findsOneWidget);
          final accountText = find.descendant(
            of: card,
            matching: find.text(account.name),
          );
          expect(accountText, findsOneWidget);
          final amount = find.descendant(
            of: card,
            matching: find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  widget.style ==
                      Theme.of(tester.element(card)).textTheme.titleLarge,
            ),
          );
          expect(amount, findsOneWidget);
          expect(
            tester.getTopLeft(amount).dy,
            greaterThan(tester.getTopLeft(type).dy),
          );
          expect(
            tester.getTopLeft(accountText).dy,
            greaterThan(tester.getTopLeft(amount).dy),
          );
        }
        expect(tester.takeException(), isNull);
        await chooseReport(tester, PersonalReportKind.cashFlow);
        final grouping = find.byType(DropdownButtonFormField<ReportGrouping>);
        await tester.scrollUntilVisible(grouping, 220, scrollable: scroll);
        final element = tester.element(grouping);
        final parent = element.findAncestorWidgetOfExactType<ListView>()!;
        final children =
            (parent.childrenDelegate as SliverChildListDelegate).children;
        final index = children.indexWhere(
          (w) => w is DropdownButtonFormField<ReportGrouping>,
        );
        expect((children[index - 1] as SizedBox).height, PlanActSpacing.lg);
        expect((children[index + 1] as SizedBox).height, PlanActSpacing.lg);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'movement details paginate 41 rows without changing complete totals and reset on refresh',
    (tester) async {
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'کیف',
        currency: 'IRR',
        type: FinancialAccountType.cash,
      );
      final entries = [
        for (var i = 0; i < 41; i++)
          AccountEntry(
            id: StableId.generate(),
            accountId: account.id,
            type: AccountEntryType.expense,
            amount: Money(minorUnits: 100, currency: 'IRR'),
            occurredAt: DateTime(2026, 10, 13, 0, i),
            note: 'ردیف $i',
          ),
      ];
      final reader = _Reader()
        ..fail = false
        ..snapshot = ReportSnapshot(accounts: [account], entries: entries);
      await tester.pumpWidget(
        MaterialApp(
          theme: PlanActTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ReportsPage(reader: reader, now: DateTime(2026, 10, 13)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await chooseReport(tester, PersonalReportKind.accounts);
      final scroll = find
          .descendant(
            of: find.byType(ReportsPage),
            matching: find.byType(Scrollable),
          )
          .first;
      final list = find.byType(ReportMovementList);
      await tester.scrollUntilVisible(list, 250, scrollable: scroll);
      Finder cards() => find.descendant(of: list, matching: find.byType(Card));
      expect(cards(), findsNWidgets(20));
      expect(find.text('ردیف 40'), findsOneWidget);
      expect(find.text('ردیف 20'), findsNothing);
      Future<void> next() async {
        final button = find
            .descendant(
              of: list,
              matching: find.widgetWithText(OutlinedButton, 'صفحهٔ بعد'),
            )
            .first;
        await tester.ensureVisible(button);
        await tester.pumpAndSettle();
        await tester.tap(button);
        await tester.pumpAndSettle();
      }

      await next();
      expect(cards(), findsNWidgets(20));
      expect(find.text('ردیف 20'), findsOneWidget);
      expect(find.text('ردیف 40'), findsNothing);
      await next();
      expect(cards(), findsOneWidget);
      expect(find.text('ردیف 0'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find
                  .descendant(
                    of: list,
                    matching: find.widgetWithText(OutlinedButton, 'صفحهٔ بعد'),
                  )
                  .first,
            )
            .onPressed,
        isNull,
      );
      final report = buildPersonalReport(
        reader.snapshot,
        ReportFilter(from: DateTime(2026, 10, 1), to: DateTime(2026, 10, 31)),
        kind: PersonalReportKind.accounts,
        now: DateTime(2026, 10, 13),
      );
      expect(report.accounts.single.closing, -4100);
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(list, -250, scrollable: scroll);
      expect(cards(), findsNWidgets(20));
      expect(find.text('ردیف 40'), findsOneWidget);
      expect(reader.reads, 3);
      expect(tester.takeException(), isNull);
    },
  );
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
      await tester.tap(find.byIcon(Icons.more_horiz).last);
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
        await tester.tap(find.byIcon(Icons.more_horiz).last);
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
        final open = find.descendant(
          of: find.byKey(const ValueKey('report-included-tags')),
          matching: find.byKey(const ValueKey('tag-selection-open')),
        );
        await tester.ensureVisible(open);
        await tester.pumpAndSettle();
        await tester.tap(open);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(CheckboxListTile, '#ورزش'));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('بستن').last);
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
        expect(
          find.descendant(
            of: find.byType(ReportMovementList),
            matching: find.text('#ورزش'),
          ),
          findsWidgets,
        );
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
        Future<void> selectTag(String key) async {
          final button = find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byKey(const ValueKey('tag-selection-open')),
          );
          await tester.scrollUntilVisible(button, -180, scrollable: scroll);
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          await tester.tap(button);
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(CheckboxListTile, '#ورزش'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip('بستن').last);
          await tester.pumpAndSettle();
        }

        Finder summary(String key) => find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.widgetWithText(Chip, '#ورزش'),
        );
        await selectTag('report-excluded-tags');
        expect(summary('report-included-tags'), findsNothing);
        expect(summary('report-excluded-tags'), findsOneWidget);
        await selectTag('report-included-tags');
        expect(summary('report-included-tags'), findsOneWidget);
        expect(summary('report-excluded-tags'), findsNothing);
        expect(
          (await tags.tagsFor(tagged.id.value, TaggableType.accountEntry)),
          {tag.id},
        );
        expect((await finance.listEntries()).length, 3);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  for (final dark in [false, true]) {
    testWidgets('report filters have uniform spacing, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.8)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: ReportsPage(
            reader: _Reader()..fail = false,
            now: DateTime(2026, 10, 13),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final kind in PersonalReportKind.values) {
        await chooseReport(tester, kind);
        final header = find.text('فیلترهای گزارش');
        await tester.ensureVisible(header);
        await tester.pumpAndSettle();
        final tile = tester.widget<ExpansionTile>(
          find.byKey(const PageStorageKey('report-filters')),
        );
        final controls = find.byKey(const ValueKey('report-filter-controls'));
        if (controls.evaluate().isEmpty) {
          await tester.tap(header);
          await tester.pumpAndSettle();
        }
        final column = tester.widget<Column>(controls);
        expect(tile.childrenPadding, const EdgeInsets.all(PlanActSpacing.lg));
        expect(column.children.length, greaterThan(5));
        for (var i = 1; i < column.children.length; i++) {
          final previous = tester.getRect(
            find.byWidget(column.children[i - 1]),
          );
          final current = tester.getRect(find.byWidget(column.children[i]));
          expect(
            current.top - previous.bottom,
            closeTo(16, 0.01),
            reason: '${kind.name}, controls ${i - 1} and $i',
          );
        }
        final excluded = tester.getRect(
          find.byKey(const ValueKey('report-excluded-tags')),
        );
        final index = column.children.indexWhere(
          (child) => child.key == const ValueKey('report-excluded-tags'),
        );
        expect(
          tester.getRect(find.byWidget(column.children[index + 1])).top -
              excluded.bottom,
          closeTo(16, 0.01),
        );
        expect(tester.takeException(), isNull, reason: kind.name);
      }
    });
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
