import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/account_identifiers.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/account_form_sheet.dart';
import 'package:planact/features/finance/presentation/account_information_card.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';

class FailingAccounts extends InMemoryFinanceRepository {
  bool fail = true;
  bool failEdit = false;
  @override
  Future<void> createAccount(
    FinancialAccount account, {
    AccountEntry? openingBalance,
  }) async {
    if (fail) throw StateError('injected');
    await super.createAccount(account, openingBalance: openingBalance);
  }

  @override
  Future<void> editAccount({
    required FinancialAccount original,
    required FinancialAccount replacement,
  }) async {
    if (failEdit) throw StateError('injected');
    await super.editAccount(original: original, replacement: replacement);
  }
}

Widget host(Widget child, {bool dark = false, double scale = 1}) => MaterialApp(
  theme: PlanActTheme.light(),
  darkTheme: PlanActTheme.dark(),
  themeMode: dark ? ThemeMode.dark : ThemeMode.light,
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: MediaQuery(
      data: MediaQueryData(
        size: const Size(320, 800),
        textScaler: TextScaler.linear(scale),
      ),
      child: Scaffold(body: child),
    ),
  ),
);

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'masked informational card reveal/hide/background, narrow large text dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final account = FinancialAccount(
          id: StableId.generate(),
          name: 'حساب شخصی با نام طولانی برای خوانایی',
          currency: 'IRR',
          type: FinancialAccountType.bank,
          bank: IranianBank.melli,
          identifiers: AccountIdentifiers(
            cardNumber: '0000000000000018',
            iban: 'IR820540102680020817909002',
            accountNumber: '000123',
          ),
        );
        await tester.pumpWidget(
          host(
            SingleChildScrollView(
              child: AccountInformationCard(
                account: account,
                balance: const Money(minorUnits: -123456789, currency: 'IRR'),
                operations: const SizedBox(),
              ),
            ),
            dark: dark,
            scale: 2,
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(PersianNumbers.format('0000000000000018')),
          findsNothing,
        );
        expect(find.text(PersianNumbers.format('•••• 0018')), findsOneWidget);
        expect(find.text('بانکی · بانک ملی'), findsOneWidget);
        expect(
          find.text('−۱۲۳,۴۵۶,۷۸۹ ریال'),
          findsNothing,
        ); // Formatter uses exact ASCII sign, not an invented value.
        expect(find.text('-۱۲۳,۴۵۶,۷۸۹ ریال'), findsOneWidget);
        final semantics = tester.ensureSemantics();
        expect(
          tester
              .getSemantics(find.text(PersianNumbers.format('•••• 0018')))
              .label,
          isNot(contains('0000000000000018')),
        );
        await tester.ensureVisible(find.text('نمایش شماره کارت'));
        await tester.tap(find.text('نمایش شماره کارت'));
        await tester.pumpAndSettle();
        expect(
          find.text(PersianNumbers.format('0000000000000018')),
          findsOneWidget,
        );
        await tester.tap(find.text('پنهان کردن شماره کارت'));
        await tester.pumpAndSettle();
        expect(
          find.text(PersianNumbers.format('0000000000000018')),
          findsNothing,
        );
        await tester.tap(find.text('نمایش شماره کارت'));
        await tester.pumpAndSettle();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
        await tester.pump();
        expect(
          find.text(PersianNumbers.format('0000000000000018')),
          findsNothing,
        );
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        semantics.dispose();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'clipboard explicit confirmation cancellation success failure and retry',
    (tester) async {
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب',
        currency: 'IRR',
        type: FinancialAccountType.cash,
        identifiers: AccountIdentifiers(accountNumber: '000123'),
      );
      var writes = 0;
      var fail = false;
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            writes++;
            if (fail) throw PlatformException(code: 'denied');
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await tester.pumpWidget(
        host(
          AccountInformationCard(
            account: account,
            balance: const Money(minorUnits: 0, currency: 'IRR'),
            operations: const SizedBox(),
          ),
        ),
      );
      expect(writes, 0);
      await tester.tap(find.text('کپی شماره حساب'));
      await tester.pumpAndSettle();
      expect(find.textContaining('برنامه‌های دیگر'), findsOneWidget);
      expect(writes, 0);
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(writes, 0);
      await tester.tap(find.text('کپی شماره حساب'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید کپی'));
      await tester.pumpAndSettle();
      expect(copied, '000123');
      expect(find.textContaining('شناسه کپی شد'), findsOneWidget);
      fail = true;
      await tester.tap(find.text('کپی شماره حساب'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید کپی'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('کپی انجام نشد؛ دوباره تلاش کنید.'), findsOneWidget);
      expect(writes, 2);
      expect(find.text(PersianNumbers.format('000123')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Finance create validates opening inside sheet, preserves draft on failure and refreshes',
    (tester) async {
      final repository = FailingAccounts();
      final key = GlobalKey<FinancePageState>();
      var refreshes = 0;
      await tester.pumpWidget(
        host(
          FinancePage(
            key: key,
            repository: repository,
            onDataChanged: () async {
              refreshes++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      final pending = key.currentState!.openAccountForm();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'نام حساب'),
        'حساب بانک ملت',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'موجودی اولیه (اختیاری)'),
        'abc',
      );
      await tester.tap(find.text('افزودن').last);
      await tester.pumpAndSettle();
      expect(find.text('موجودی اولیه معتبر نیست.'), findsOneWidget);
      expect(await repository.listAccounts(), isEmpty);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'موجودی اولیه (اختیاری)'),
        '۱۰۱',
      );
      await tester.tap(find.text('افزودن').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('ورودی‌ها حفظ شدند'), findsOneWidget);
      expect(find.text('حساب بانک ملت'), findsOneWidget);
      repository.fail = false;
      await tester.tap(find.text('افزودن').last);
      await tester.pumpAndSettle();
      await pending;
      final created = (await repository.listAccounts()).single;
      expect(created.name, 'حساب بانک ملت');
      expect(created.type, FinancialAccountType.cash);
      expect(created.bank, isNull);
      expect(created.identifiers, AccountIdentifiers.empty);
      expect((await repository.listEntries()).single.amount.minorUnits, 101);
      expect(refreshes, 1);
      expect(find.text('حساب افزوده شد.'), findsOneWidget);
      expect(find.text('۱۰۱ ریال'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Finance metadata edit clears details, retries failure, refreshes and preserves ledger',
    (tester) async {
      final repository = FailingAccounts()..fail = false;
      final account = FinancialAccount(
        id: StableId.generate(),
        name: 'حساب قدیمی',
        currency: 'IRR',
        type: FinancialAccountType.bank,
        bank: IranianBank.mellat,
        identifiers: AccountIdentifiers(accountNumber: '000123'),
      );
      await FinanceUseCases(repository).createAccount(
        account,
        openingBalance: const Money(minorUnits: 87, currency: 'IRR'),
      );
      await tester.pumpWidget(host(FinancePage(repository: repository)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('ویرایش حساب'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'نام حساب'),
        'نام اصلاح‌شده',
      );
      await tester.ensureVisible(find.byKey(const ValueKey('account-number')));
      EditableText numberField() => tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('account-number')),
          matching: find.byType(EditableText),
        ),
      );
      expect(numberField().obscureText, isTrue);
      await tester.tap(find.byTooltip('نمایش شماره حساب (اختیاری)'));
      await tester.pumpAndSettle();
      expect(numberField().obscureText, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(numberField().obscureText, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.enterText(find.byKey(const ValueKey('account-number')), '');
      repository.failEdit = true;
      await tester.tap(find.text('ذخیره'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ویرایش انجام نشد'), findsOneWidget);
      expect((await repository.listAccounts()).single.name, 'حساب قدیمی');
      repository.failEdit = false;
      await tester.tap(find.text('ذخیره'));
      await tester.pumpAndSettle();
      expect(find.text('نام اصلاح‌شده'), findsOneWidget);
      expect(
        (await repository.listAccounts()).single.identifiers,
        AccountIdentifiers.empty,
      );
      expect((await repository.listEntries()).single.amount.minorUnits, 87);
      expect(find.text('اطلاعات حساب ذخیره شد.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('field errors preserve inputs and cancellation writes nothing', (
    tester,
  ) async {
    final repository = InMemoryFinanceRepository();
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showAccountForm(context, FinanceUseCases(repository)),
            child: const Text('باز کردن'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('باز کردن'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'نام حساب'),
      'بانک',
    );
    await tester.tap(find.text('جزئیات حساب (اختیاری)'));
    await tester.pumpAndSettle();
    for (final key in ['account-card', 'account-iban', 'account-number']) {
      await tester.ensureVisible(find.byKey(ValueKey(key)));
      await tester.enterText(find.byKey(ValueKey(key)), 'abc');
    }
    await tester.tap(find.text('افزودن'));
    await tester.pumpAndSettle();
    expect(find.text('شماره کارت باید ۱۶ رقم باشد.'), findsOneWidget);
    expect(find.text('شبا باید IR و ۲۴ رقم داشته باشد.'), findsOneWidget);
    expect(find.text('شماره حساب باید بین ۱ تا ۳۰ رقم باشد.'), findsOneWidget);
    await tester.tap(find.text('انصراف'));
    await tester.pumpAndSettle();
    expect(await repository.listAccounts(), isEmpty);
    expect(await repository.listEntries(), isEmpty);
    expect(tester.takeException(), isNull);
  });
}
