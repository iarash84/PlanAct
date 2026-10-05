/// Canonical identifiers used by the domain for monetary units.
///
/// User-facing labels such as «تومان» are presentation concerns and must not
/// be persisted as currency identifiers.
abstract final class CurrencyCodes {
  static const irr = 'IRR';

  /// Legacy «تومان» balances have a different unit and are never silently
  /// treated as rials. They require an explicit migration before matching IRR.
  static String canonicalize(String value) => value.trim().toUpperCase();

  static bool same(String left, String right) =>
      canonicalize(left) == canonicalize(right);

  static String label(String currency) =>
      same(currency, irr) ? 'ریال' : currency;
}
