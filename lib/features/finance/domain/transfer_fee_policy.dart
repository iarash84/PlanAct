import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/finance.dart';

/// Explicit fee rule for a transfer method. A zero fee is the documented
/// default when no institution-specific rule has been configured.
abstract interface class TransferFeePolicy {
  Money feeFor({required TransferFeeContext context});
}

class TransferFeeContext {
  const TransferFeeContext({required this.amount, required this.method});

  final Money amount;
  final TransferMethod method;
}

class FixedTransferFeePolicy implements TransferFeePolicy {
  const FixedTransferFeePolicy(this.fees);

  final Map<TransferMethod, Money> fees;

  @override
  Money feeFor({required TransferFeeContext context}) {
    final fee = fees[context.method];
    if (fee == null) {
      return Money(minorUnits: 0, currency: context.amount.currency);
    }
    if (fee.currency != context.amount.currency || fee.minorUnits < 0) {
      throw const ValidationError(
        'Transfer fee must use a valid account currency',
      );
    }
    return fee;
  }
}

class NoTransferFeePolicy implements TransferFeePolicy {
  const NoTransferFeePolicy();

  @override
  Money feeFor({required TransferFeeContext context}) =>
      Money(minorUnits: 0, currency: context.amount.currency);
}
