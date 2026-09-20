/// Abstraction over the current instant, making time-dependent logic testable.
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now().toUtc();
}

class FixedClock implements Clock {
  FixedClock(DateTime instant) : _instant = instant.toUtc();

  DateTime _instant;

  @override
  DateTime now() => _instant;

  void set(DateTime instant) {
    _instant = instant.toUtc();
  }
}
