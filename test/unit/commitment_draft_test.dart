import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  test('minimal draft validates only required title and schedule', () {
    const draft = CommitmentDraft();
    expect(draft.validateForStep(1), 'عنوان تعهد را وارد کنید.');
    expect(draft.copyWith(title: 'کلاس').validateForStep(1), isNull);
    expect(
      draft.copyWith(title: 'کلاس').validateForStep(2),
      'تاریخ و زمان شروع را انتخاب کنید.',
    );
  });

  test('weekly recurring draft rejects no weekdays', () {
    final draft = CommitmentDraft(
      title: 'ورزش',
      kind: CommitmentKind.recurring,
      startAt: DateTime(2026, 10, 1, 18),
      frequency: RecurrenceFrequency.weekly,
    );
    expect(draft.validateForStep(2), 'حداقل یک روز هفته را انتخاب کنید.');
  });

  test('review summary preserves typed financial meaning', () {
    final draft = CommitmentDraft(
      title: 'کلاس موسیقی',
      startAt: DateTime(2026, 10, 1, 18),
      financialMeaning: CommitmentFinancialMeaning.paymentRequired,
      entitlement: EntitlementDraft.fixedUnits,
      entitlementUnits: 4,
    );
    expect(draft.reviewSummary(), contains('نیازمند پرداخت'));
    expect(draft.reviewSummary(), contains('۴'));
  });
}
