import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/bank_balance_panel.dart';

class _Repository implements BankBalanceRepository {
  int writes = 0;
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
        await tester.tap(find.text('بررسی و تطبیق حساب'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'تأیید ثبت اختلاف'),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.text('انصراف'));
        await tester.pumpAndSettle();
        expect(repository.writes, 0);
        await tester.tap(find.text('بررسی و تطبیق حساب'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButton<BankReconciliationReason>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تعدیل اختلاف نامعلوم حساب').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('تأیید ثبت اختلاف'));
        await tester.pumpAndSettle();
        expect(repository.writes, 1);
        expect(find.textContaining('ثبت تطبیق انجام نشد'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
