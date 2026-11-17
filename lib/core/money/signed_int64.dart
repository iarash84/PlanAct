import 'package:planact/core/errors/app_error.dart';

final _minimum = BigInt.parse('-9223372036854775808');
final _maximum = BigInt.parse('9223372036854775807');

/// Checks before conversion: BigInt.toInt otherwise clamps out-of-range values.
int? trySignedInt64(BigInt value) =>
    value < _minimum || value > _maximum ? null : value.toInt();

int checkedSignedInt64(BigInt value) {
  final result = trySignedInt64(value);
  if (result == null) {
    throw const ValidationError('Integer monetary result is outside int64');
  }
  return result;
}
