import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';

/// Whether the expected cash flow is into or out of the user's accounts.
enum FinancialExpectationDirection { outgoing, incoming }

enum FinancialExpectationStatus { active, archived }

class FinancialExpectation {
  FinancialExpectation({
    required this.id,
    required this.occurrenceId,
    required this.direction,
    required this.amount,
    this.currency,
    this.accountId,
    this.status = FinancialExpectationStatus.active,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (amount <= 0) {
      throw const ValidationError('Expectation amount must be positive');
    }
    if (currency != null && currency!.trim().isEmpty) {
      throw const ValidationError('Expectation currency cannot be empty');
    }
  }

  final StableId id;
  final StableId occurrenceId;
  final FinancialExpectationDirection direction;
  final int amount;
  final String? currency;
  final StableId? accountId;
  final FinancialExpectationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  FinancialExpectation archive(DateTime at) => FinancialExpectation(
    id: id,
    occurrenceId: occurrenceId,
    direction: direction,
    amount: amount,
    currency: currency,
    accountId: accountId,
    status: FinancialExpectationStatus.archived,
    createdAt: createdAt,
    updatedAt: at.toUtc(),
  );
}

class FinancialExpectationSettlement {
  const FinancialExpectationSettlement({
    required this.expectation,
    required this.allocatedAmount,
  });

  final FinancialExpectation expectation;
  final Money? allocatedAmount;

  bool get settled =>
      allocatedAmount != null &&
      allocatedAmount!.minorUnits >= expectation.amount;
  int get remainingMinorUnits => allocatedAmount == null
      ? expectation.amount
      : (expectation.amount - allocatedAmount!.minorUnits).clamp(
          0,
          expectation.amount,
        );
}
