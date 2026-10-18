import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

void main() {
  test(
    'clearing package credit rejects saving and leaves schedule count intact',
    () {
      const draft = CommitmentDraft(
        entitlement: EntitlementDraft.fixedUnits,
        entitlementUnits: 4,
        occurrenceCount: 10,
      );
      final cleared = draft.copyWith(clearEntitlementUnits: true);
      expect(cleared.entitlementUnits, isNull);
      expect(cleared.occurrenceCount, 10);
      expect(cleared.validateForStep(3), 'تعداد جلسهٔ معتبر را وارد کنید.');
      expect(cleared.copyWith(entitlementUnits: 6).validateForStep(3), isNull);
    },
  );
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
    expect(draft.reviewSummary(), contains('۴ جلسه'));
  });

  test('counted recurrence summary does not imply a session package', () {
    final draft = CommitmentDraft(
      title: 'مطالعه',
      kind: CommitmentKind.recurring,
      startAt: DateTime(2026, 10, 1, 18),
      frequency: RecurrenceFrequency.daily,
      termination: RecurrenceTermination.count,
      occurrenceCount: 8,
    );
    expect(draft.reviewSummary(), contains('۸ نوبت'));
    expect(draft.reviewSummary(), isNot(contains('بسته')));
    expect(draft.reviewSummary(), isNot(contains('جلسه')));
    expect(draft.entitlement, EntitlementDraft.none);
    expect(draft.entitlementUnits, isNull);
  });

  test('draft preserves multiple reminder offsets independently', () {
    const first = Duration(minutes: 15);
    const second = Duration(hours: 1);
    final draft = const CommitmentDraft().copyWith(
      title: 'جلسه',
      reminderOffsets: [first, second],
    );

    expect(draft.reminderOffsets, [first, second]);
    expect(draft.copyWith(reminderOffsets: const []).reminderOffsets, isEmpty);
  });
}
