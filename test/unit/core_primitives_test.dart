import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/time/clock.dart';

void main() {
  test('UUIDv7 stable IDs are parseable, unique, and time ordered', () {
    final first = StableId.generate(timestamp: DateTime.utc(2026, 9, 20));
    final second = StableId.generate(timestamp: DateTime.utc(2026, 9, 21));

    expect(first, isNot(equals(second)));
    expect(StableId.parse(first.value), first);
    expect(first.value.substring(14, 15), '7');
    expect(first.value.compareTo(second.value), lessThan(0));
  });

  test('money uses integer minor units and rejects currency mixing', () {
    const one = Money(minorUnits: 100, currency: 'USD');
    const two = Money(minorUnits: 25, currency: 'USD');

    expect(one + two, const Money(minorUnits: 125, currency: 'USD'));
    expect(one - two, const Money(minorUnits: 75, currency: 'USD'));
    expect(
      () => one + const Money(minorUnits: 1, currency: 'EUR'),
      throwsArgumentError,
    );
  });

  test('fixed clock provides deterministic UTC time', () {
    final clock = FixedClock(DateTime.parse('2026-09-20T12:00:00-07:00'));

    expect(clock.now(), DateTime.parse('2026-09-20T19:00:00Z'));
  });
}
