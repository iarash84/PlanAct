import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/sessions/domain/session_policy.dart';

void main() {
  const policy = SessionPolicy(
    providerCancellationConsumes: false,
    userCancellationNoticeHours: 24,
    lateCancellationConsumes: true,
    noShowConsumes: true,
    freeAbsenceQuota: 2,
    holidayConsumes: false,
    makeupRequired: true,
  );

  test('provider cancellation does not consume and requires makeup', () {
    final resolution = policy.resolve(
      outcome: SessionOutcome.providerCancelled,
    );

    expect(resolution.consumesEntitlement, isFalse);
    expect(resolution.requiresMakeup, isTrue);
  });

  test('late user cancellation consumes but does not require makeup', () {
    final resolution = policy.resolve(
      outcome: SessionOutcome.userCancelled,
      cancellationWithinNotice: false,
    );

    expect(resolution.consumesEntitlement, isTrue);
    expect(resolution.requiresMakeup, isFalse);
  });

  test('free absence quota is consumed only after quota is exhausted', () {
    final free = policy.resolve(
      outcome: SessionOutcome.absent,
      absenceCount: 1,
    );
    final charged = policy.resolve(
      outcome: SessionOutcome.absent,
      absenceCount: 2,
    );

    expect(free.consumesEntitlement, isFalse);
    expect(free.absenceQuotaUsed, isTrue);
    expect(charged.consumesEntitlement, isTrue);
  });

  test('no-show consumes and holiday preserves entitlement', () {
    expect(
      policy.resolve(outcome: SessionOutcome.noShow).consumesEntitlement,
      isTrue,
    );
    expect(
      policy.resolve(outcome: SessionOutcome.holiday).consumesEntitlement,
      isFalse,
    );
  });
}
