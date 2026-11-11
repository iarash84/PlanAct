import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

class _Repository extends InMemoryFinanceRepository {
  bool fail = false;
  int? limit;
  @override
  Future<List<AccountEntry>> listEntries() async {
    if (fail) throw StateError('read failed');
    final entries = await super.listEntries();
    return limit == null ? entries : entries.take(limit!).toList();
  }
}

Future<_Repository> _seed(int count, {bool equalTimes = false}) async {
  final repository = _Repository();
  final account = FinancialAccount(
    id: StableId.generate(),
    name: 'نقدی',
    currency: 'IRR',
    type: FinancialAccountType.cash,
  );
  await repository.saveAccount(account);
  for (var i = 0; i < count; i++) {
    await repository.saveEntry(
      AccountEntry(
        id: StableId.parse(
          '00000000-0000-7000-8000-${i.toString().padLeft(12, '0')}',
        ),
        accountId: account.id,
        type: i.isEven ? AccountEntryType.expense : AccountEntryType.income,
        amount: const Money(minorUnits: 100, currency: 'IRR'),
        occurredAt: DateTime(
          2026,
          11,
          11,
        ).subtract(Duration(minutes: equalTimes ? 0 : i)),
        note: 'ردیف $i',
      ),
    );
  }
  return repository;
}

Future<void> _open(
  WidgetTester tester,
  _Repository repository, {
  GlobalKey<FinancePageState>? key,
  String? focusedRecordId,
  bool dark = false,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
      home: FinancePage(
        key: key,
        repository: repository,
        focusedRecordId: focusedRecordId,
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (focusedRecordId == null) {
    await tester.scrollUntilVisible(
      find.text('آخرین تراکنش‌ها'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _page(WidgetTester tester, String label) async {
  final button = find.widgetWithText(OutlinedButton, label).first;
  final position = tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position;
  position.jumpTo(0);
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('آخرین تراکنش‌ها'),
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Finder get menus => find.byWidgetPredicate(
  (widget) =>
      widget is PopupMenuButton<String> &&
      widget.key.toString().contains('entry-menu:'),
);

void main() {
  for (final count in [0, 20, 21, 45]) {
    testWidgets('bounded transaction pages for $count entries', (tester) async {
      final repository = await _seed(count);
      await _open(tester, repository);
      expect(menus, findsNWidgets(count.clamp(0, 20)));
      if (count == 0) {
        expect(find.text('صفحهٔ بعد'), findsNothing);
        return;
      }
      final previous = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'صفحهٔ قبل').first,
      );
      expect(previous.onPressed, isNull);
      if (count > 20) {
        await _page(tester, 'صفحهٔ بعد');
        expect(menus, findsNWidgets((count - 20).clamp(0, 20)));
        expect(
          find.byKey(
            const ValueKey('entry-menu:00000000-0000-7000-8000-000000000000'),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            const ValueKey('entry-menu:00000000-0000-7000-8000-000000000020'),
          ),
          findsOneWidget,
        );
        if (count > 40) {
          await _page(tester, 'صفحهٔ بعد');
          expect(menus, findsNWidgets(5));
          expect(find.textContaining('صفحهٔ ۳ از ۳'), findsNWidgets(2));
        }
        final next = tester.widget<OutlinedButton>(
          find.widgetWithText(OutlinedButton, 'صفحهٔ بعد').first,
        );
        expect(next.onPressed, isNull);
        await _page(tester, 'صفحهٔ قبل');
        expect(menus, findsNWidgets(20));
      }
      expect(await repository.listEntries(), hasLength(count));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('equal timestamps have stable ID ordering across pages', (
    tester,
  ) async {
    final repository = await _seed(21, equalTimes: true);
    await _open(tester, repository);
    expect(
      find.byKey(
        const ValueKey('entry-menu:00000000-0000-7000-8000-000000000020'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('entry-menu:00000000-0000-7000-8000-000000000000'),
      ),
      findsNothing,
    );
    await _page(tester, 'صفحهٔ بعد');
    expect(
      find.byKey(
        const ValueKey('entry-menu:00000000-0000-7000-8000-000000000000'),
      ),
      findsOneWidget,
    );
    expect(menus, findsOneWidget);
  });

  testWidgets(
    'refresh retains page and full-ledger summary; failure retains rows',
    (tester) async {
      final repository = await _seed(45);
      final key = GlobalKey<FinancePageState>();
      await _open(tester, repository, key: key);
      await tester.scrollUntilVisible(
        find.text('خروجی: ۲,۳۰۰ ریال'),
        -400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('خروجی: ۲,۳۰۰ ریال'), findsOneWidget);
      await _page(tester, 'صفحهٔ بعد');
      await key.currentState!.refreshData();
      await tester.pumpAndSettle();
      expect(find.textContaining('صفحهٔ ۲ از ۳'), findsNWidgets(2));
      await tester.scrollUntilVisible(
        find.text('خروجی: ۲,۳۰۰ ریال'),
        -400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('خروجی: ۲,۳۰۰ ریال'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('آخرین تراکنش‌ها'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      repository.fail = true;
      await key.currentState!.refreshData();
      await tester.pumpAndSettle();
      expect(find.textContaining('صفحهٔ ۲ از ۳'), findsNWidgets(2));
      expect(menus, findsNWidgets(20));
      await tester.scrollUntilVisible(
        find.text('اطلاعات نمایش‌داده‌شده ممکن است قدیمی باشد.'),
        -400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text('اطلاعات نمایش‌داده‌شده ممکن است قدیمی باشد.'),
        findsOneWidget,
      );
      repository.fail = false;
      await key.currentState!.refreshData();
      await tester.pumpAndSettle();
      expect(
        find.text('اطلاعات نمایش‌داده‌شده ممکن است قدیمی باشد.'),
        findsNothing,
      );
    },
  );

  testWidgets('type filter runs before pagination and resets the page', (
    tester,
  ) async {
    final repository = await _seed(45);
    await _open(tester, repository);
    await _page(tester, 'صفحهٔ بعد');
    final filter = find.byType(DropdownButton<AccountEntryType?>);
    await tester.scrollUntilVisible(
      filter,
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(filter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('خروجی').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('آخرین تراکنش‌ها'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('صفحهٔ ۱ از ۲'), findsNWidgets(2));
    expect(menus, findsNWidgets(20));
    expect(
      find.byKey(
        const ValueKey('entry-menu:00000000-0000-7000-8000-000000000001'),
      ),
      findsNothing,
    );
    await _page(tester, 'صفحهٔ بعد');
    expect(menus, findsNWidgets(3));
    expect(
      find.byKey(
        const ValueKey('entry-menu:00000000-0000-7000-8000-000000000044'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('focused old record bypasses transaction pagination', (
    tester,
  ) async {
    final repository = await _seed(45);
    await _open(
      tester,
      repository,
      focusedRecordId: '00000000-0000-7000-8000-000000000044',
    );
    expect(menus, findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('entry-menu:00000000-0000-7000-8000-000000000044'),
      ),
      findsOneWidget,
    );
    expect(find.text('صفحهٔ بعد'), findsNothing);
  });

  testWidgets('refresh clamps a page that no longer exists', (tester) async {
    final repository = await _seed(45);
    final key = GlobalKey<FinancePageState>();
    await _open(tester, repository, key: key);
    await _page(tester, 'صفحهٔ بعد');
    await _page(tester, 'صفحهٔ بعد');
    repository.limit = 21;
    await key.currentState!.refreshData();
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحهٔ ۲ از ۲'), findsNWidgets(2));
    expect(menus, findsOneWidget);
    repository.limit = null;
    await key.currentState!.refreshData();
    await tester.pumpAndSettle();
    expect(find.textContaining('صفحهٔ ۲ از ۳'), findsNWidgets(2));
  });

  testWidgets('reversal outside current page still disables original actions', (
    tester,
  ) async {
    final repository = await _seed(21);
    final original = (await repository.listEntries()).first;
    await repository.saveEntry(
      AccountEntry(
        id: StableId.generate(),
        accountId: original.accountId,
        type: AccountEntryType.reversal,
        amount: const Money(minorUnits: 100, currency: 'IRR'),
        occurredAt: DateTime(2020),
        referenceId: original.id.value,
      ),
    );
    await _open(tester, repository);
    final menu = tester.widget<PopupMenuButton<String>>(
      find.byKey(ValueKey('entry-menu:${original.id.value}')),
    );
    expect(menu.enabled, isFalse);
    expect(menus, findsNWidgets(20));
  });

  for (final dark in [false, true]) {
    testWidgets('pagination wraps at 320dp and large RTL text; dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await _open(tester, await _seed(21), dark: dark, scale: 2);
      await _page(tester, 'صفحهٔ بعد');
      expect(menus, findsOneWidget);
      expect(tester.takeException(), isNull);
      final previous = find.widgetWithText(OutlinedButton, 'صفحهٔ قبل').last;
      await tester.ensureVisible(previous);
      await tester.pumpAndSettle();
      expect(tester.getSize(previous).height, greaterThanOrEqualTo(48));
      await tester.tap(previous);
      await tester.pumpAndSettle();
      expect(menus, findsNWidgets(20));
      expect(tester.takeException(), isNull);
    });
  }
}
