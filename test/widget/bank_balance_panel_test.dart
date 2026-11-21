import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/bank_balance_panel.dart';

class _Repository implements BankBalanceRepository, BankRecoveryRepository {
  int writes = 0;
  @override
  Future<BankRecoveryPreview> previewBankRecovery(Set<String> accountIds) =>
      throw UnimplementedError();
  @override
  Future<void> recoverBankReconciliations(BankRecoveryPreview expected) =>
      throw UnimplementedError();
  @override
  Future<BankBalanceSnapshot> bankBalance(String id) =>
      throw UnimplementedError();
  @override
  Future<AccountEntry> reconcileBankBalance(
    BankBalanceSnapshot expected,
    BankReconciliationReason reason,
  ) async {
    writes++;
    throw StateError('injected failure');
  }
}

void main() {
  for (final state in ['missing', 'ambiguous', 'equal', 'active', 'higher']) {
    testWidgets('bank comparison state $state at narrow RTL large text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Repository();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: BankBalancePanel(
                snapshot: BankBalanceSnapshot(
                  accountId: 'account',
                  latest: state == 'missing'
                      ? null
                      : BankBalanceObservation(
                          id: 'sms',
                          entryId: 'entry',
                          accountId: 'account',
                          irr: state == 'higher' ? 1100 : 1000,
                          sourceAmount: 1000,
                          sourceUnit: 'rial',
                          transactionTime: DateTime(2026, 1, 1, 12),
                        ),
                  ambiguous: state == 'ambiguous',
                  ledgerAtReport: 1000,
                  token: 'token',
                  activeReconciliation: state == 'active',
                ),
                repository: repository,
                onChanged: () async {},
                enabled: true,
              ),
            ),
          ),
        ),
      );
      final compare = find.widgetWithText(TextButton, 'مقایسه با موجودی بانک');
      expect(
        tester.widget<TextButton>(compare).onPressed,
        state == 'higher' ? isNotNull : isNull,
      );
      expect(
        find.text('بررسی تطبیق‌های قبلی'),
        state == 'active' ? findsOneWidget : findsNothing,
      );
      if (state == 'higher') {
        expect(find.textContaining('بیشتر از دفتر است'), findsOneWidget);
        await tester.ensureVisible(compare);
        await tester.tap(compare);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byType(DropdownButton<BankReconciliationReason>),
        );
        await tester.tap(find.byType(DropdownButton<BankReconciliationReason>));
        await tester.pumpAndSettle();
        expect(find.text('کارمزد مشخص بانک'), findsNothing);
        await tester.tap(find.text('تعدیل اختلاف نامعلوم حساب').last);
        await tester.pumpAndSettle();
        expect(find.text('ثبت تعدیل موجودی'), findsOneWidget);
        await tester.tap(find.text('انصراف'));
        await tester.pumpAndSettle();
      }
      expect(repository.writes, 0);
      expect(tester.takeException(), isNull);
    });
  }
  for (final brightness in Brightness.values) {
    testWidgets(
      'explicit reason, cancel and failure retain review $brightness',
      (tester) async {
        final repository = _Repository();
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(brightness: brightness),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: BankBalancePanel(
                  snapshot: BankBalanceSnapshot(
                    accountId: 'account',
                    latest: BankBalanceObservation(
                      id: 'sms',
                      entryId: 'entry',
                      accountId: 'account',
                      irr: 900,
                      sourceAmount: 900,
                      sourceUnit: 'rial',
                      transactionTime: DateTime(2026, 1, 1, 12),
                    ),
                    ambiguous: false,
                    ledgerAtReport: 1000,
                    token: 'token',
                    activeReconciliation: false,
                  ),
                  repository: repository,
                  onChanged: () async {},
                  enabled: true,
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('مقایسه با موجودی بانک'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'تأیید ثبت اختلاف'),
              )
              .onPressed,
          isNull,
        );
        expect(find.text('بررسی تطبیق‌های قبلی'), findsNothing);
        await tester.tap(find.text('تراکنشی جا افتاده یا اشتباه ثبت شده'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('این انتخاب هیچ تعدیلی ثبت نمی‌کند'),
          findsOneWidget,
        );
        expect(
          find.byType(DropdownButton<BankReconciliationReason>),
          findsNothing,
        );
        expect(repository.writes, 0);
        await tester.tap(find.text('انصراف'));
        await tester.pumpAndSettle();
        expect(repository.writes, 0);
        await tester.tap(find.text('مقایسه با موجودی بانک'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButton<BankReconciliationReason>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('کارمزد مشخص بانک').last);
        await tester.pumpAndSettle();
        expect(find.text('ثبت کارمزد'), findsOneWidget);
        expect(repository.writes, 0);
        await tester.tap(find.byType(DropdownButton<BankReconciliationReason>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تعدیل اختلاف نامعلوم حساب').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('ثبت تعدیل موجودی'));
        await tester.pumpAndSettle();
        expect(repository.writes, 1);
        expect(find.textContaining('ثبت تطبیق انجام نشد'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
