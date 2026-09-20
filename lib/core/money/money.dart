/// Integer minor-unit money value. Floating-point values are intentionally not used.
class Money {
  const Money({required this.minorUnits, required this.currency});

  final int minorUnits;
  final String currency;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits: minorUnits + other.minorUnits, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(minorUnits: minorUnits - other.minorUnits, currency: currency);
  }

  Money operator -() => Money(minorUnits: -minorUnits, currency: currency);

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError('Cannot combine different currencies');
    }
  }

  @override
  String toString() => '$minorUnits $currency';

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.minorUnits == minorUnits &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);
}
