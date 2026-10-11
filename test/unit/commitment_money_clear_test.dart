import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';

void main() {
  test(
    'invalid or cleared monetary text cannot reuse a previous valid amount',
    () {
      const draft = CommitmentDraft(
        financialMeaning: CommitmentFinancialMeaning.paymentRequired,
        financialAmount: 123,
      );
      final cleared = draft.copyWith(clearFinancialAmount: true);
      expect(cleared.financialAmount, isNull);
      expect(cleared.validateForStep(3), isNotNull);
      expect(draft.financialAmount, 123);
      expect(cleared.copyWith(financialAmount: 45).financialAmount, 45);
    },
  );
}
