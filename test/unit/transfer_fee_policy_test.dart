import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/transfer_fee_policy.dart';

void main() {
  final from = FinancialAccount(
    id: StableId.generate(),
    name: 'بانک مبدأ',
    currency: 'IRR',
    type: FinancialAccountType.bank,
  );
  final to = FinancialAccount(
    id: StableId.generate(),
    name: 'کیف مقصد',
    currency: 'IRR',
    type: FinancialAccountType.digitalWallet,
  );

  test(
    'fixed policy returns configured fee and zero for unconfigured methods',
    () {
      const policy = FixedTransferFeePolicy({
        TransferMethod.sheba: Money(minorUnits: 2500, currency: 'IRR'),
      });

      expect(
        policy
            .feeFor(
              context: const TransferFeeContext(
                amount: Money(minorUnits: 100000, currency: 'IRR'),
                method: TransferMethod.sheba,
              ),
            )
            .minorUnits,
        2500,
      );
      expect(
        policy
            .feeFor(
              context: const TransferFeeContext(
                amount: Money(minorUnits: 100000, currency: 'IRR'),
                method: TransferMethod.paya,
              ),
            )
            .minorUnits,
        0,
      );
    },
  );

  test(
    'transfer fee is a source-account expense and does not inflate destination',
    () async {
      final repository = InMemoryFinanceRepository();
      final feePolicy = FixedTransferFeePolicy({
        TransferMethod.sheba: const Money(minorUnits: 2500, currency: 'IRR'),
      });
      final useCases = FinanceUseCases(repository);

      await useCases.transfer(
        from: from,
        to: to,
        amount: const Money(minorUnits: 100000, currency: 'IRR'),
        occurredAt: DateTime(2026, 1, 1),
        method: TransferMethod.sheba,
        feePolicy: feePolicy,
      );

      final entries = await repository.listEntries();
      expect(rebuildBalance(from, entries).minorUnits, -102500);
      expect(rebuildBalance(to, entries).minorUnits, 100000);
      expect(
        entries
            .singleWhere((entry) => entry.note == 'کارمزد انتقال')
            .amount
            .minorUnits,
        2500,
      );
    },
  );
}
