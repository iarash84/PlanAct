import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

void main() {
  final createdAt = DateTime.utc(2026, 9, 20, 12);

  test('creates an active commitment with a normalized title', () {
    final commitment = Commitment.create(
      title: '  کلاس موسیقی  ',
      now: createdAt,
    );

    expect(commitment.title, 'کلاس موسیقی');
    expect(commitment.status, CommitmentStatus.active);
    expect(commitment.createdAt, createdAt);
  });

  test('allows active to paused to active transitions', () {
    final commitment = Commitment.create(title: 'مطالعه', now: createdAt);

    expect(commitment.pause().status, CommitmentStatus.paused);
    expect(commitment.pause().resume().status, CommitmentStatus.active);
  });

  test('rejects invalid state transitions', () {
    final commitment = Commitment.create(title: 'قبض', now: createdAt);

    expect(() => commitment.resume(), throwsA(isA<ValidationError>()));
    expect(
      () => commitment.archive().archive(),
      throwsA(isA<ValidationError>()),
    );
    expect(
      () => commitment.pause().archive().resume(),
      throwsA(isA<ValidationError>()),
    );
  });

  test('rejects blank titles', () {
    expect(
      () => Commitment.create(title: '   '),
      throwsA(isA<ValidationError>()),
    );
  });
}
