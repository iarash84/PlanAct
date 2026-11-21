import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/transaction_history.dart';

void main() {
  final account = StableId.generate();
  AccountEntry entry({
    AccountEntryType type = AccountEntryType.expense,
    int amount = 100,
    String? reference,
  }) => AccountEntry(
    id: StableId.generate(),
    accountId: account,
    type: type,
    amount: Money(minorUnits: amount, currency: 'IRR'),
    occurredAt: DateTime.utc(2026),
    referenceId: reference,
    note: 'یادداشت کاربر',
  );
  test('references and SMS evidence alone never imply correction', () {
    final original = entry();
    final sms = entry(reference: original.id.value);
    final result = projectTransactionHistory([original, sms], []);
    expect(
      result.every(
        (e) =>
            !e.history!.role.replacement &&
            !e.history!.role.corrected &&
            e.history!.chain.isEmpty,
      ),
      isTrue,
    );
  });
  test('reversal without journal purpose remains unknown', () {
    final original = entry();
    final reversal = entry(
      type: AccountEntryType.reversal,
      reference: original.id.value,
    );
    final result = projectTransactionHistory([original, reversal], []);
    expect(result.first.history!.role.reversed, isTrue);
    expect(result.last.history!.role.reversalPurpose, ReversalPurpose.unknown);
  });
  test(
    'only complete exact reversal and replacement evidence is classified',
    () {
      final original = entry();
      final reversal = entry(
        type: AccountEntryType.reversal,
        reference: original.id.value,
      );
      final replacement = entry(amount: 200, reference: original.id.value);
      final operation = FinanceHistoryOperation(
        before: [original.id.value],
        after: [reversal.id.value, replacement.id.value],
      );
      final result = projectTransactionHistory(
        [original, reversal, replacement],
        [operation],
      );
      expect(result.first.history!.role.corrected, isTrue);
      expect(
        result[1].history!.role.reversalPurpose,
        ReversalPurpose.correction,
      );
      expect(result.last.history!.role.replacement, isTrue);
      expect(result.last.history!.role.reversed, isFalse);
      expect(result.every((e) => e.history!.chain.length == 3), isTrue);
      final incomplete = projectTransactionHistory(
        [original, replacement],
        [operation],
      );
      expect(
        incomplete.every(
          (e) => !e.history!.role.replacement && !e.history!.role.corrected,
        ),
        isTrue,
      );
      final wrong = entry(
        type: AccountEntryType.reversal,
        amount: 99,
        reference: original.id.value,
      );
      final invalid = projectTransactionHistory(
        [original, wrong, replacement],
        [
          FinanceHistoryOperation(
            before: [original.id.value],
            after: [wrong.id.value, replacement.id.value],
          ),
        ],
      );
      expect(invalid.first.history!.role.corrected, isFalse);
      expect(invalid.last.history!.role.replacement, isFalse);
    },
  );
}
