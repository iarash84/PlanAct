import 'package:planact/core/application/command_gate.dart';
import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/data/drift_transaction_match_reader.dart';

class DriftFinancialExpectationRepository
    implements CommandGateProvider, FinancialExpectationRepository {
  DriftFinancialExpectationRepository(this.database);

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);
  final db.AppDatabase database;

  @override
  Future<List<FinancialExpectation>> listExpectations() => CommandGate.runFor(
    this,
    () async {
      final rows = await database.select(database.financialExpectations).get();
      return rows.map(_fromRow).toList(growable: false);
    },
  );

  @override
  Future<List<FinancialAccount>> listAccounts() =>
      CommandGate.runFor(this, () async {
        final rows = await database.select(database.financialAccounts).get();
        return rows
            .map(
              (row) => FinancialAccount(
                id: StableId.parse(row.id),
                name: row.name,
                currency: row.currency,
                type: FinancialAccountType.values[row.type],
                status: FinancialAccountStatus.values[row.status],
              ),
            )
            .where((account) => account.status == FinancialAccountStatus.active)
            .toList(growable: false);
      });

  @override
  Future<List<TransactionMatch>> listMatches() =>
      CommandGate.runFor(this, () => readTransactionMatches(database));

  @override
  Future<void> saveExpectation(FinancialExpectation item) => CommandGate.runFor(
    this,
    () async {
      if (item.amount <= 0) {
        throw const ValidationError('Expectation amount must be positive');
      }
      await database.transaction(() async {
        final occurrence =
            await (database.select(database.occurrences)
                  ..where((table) => table.id.equals(item.occurrenceId.value)))
                .getSingleOrNull();
        if (occurrence == null) {
          throw const ValidationError('Expectation occurrence is missing');
        }
        if (item.accountId != null) {
          final account =
              await (database.select(database.financialAccounts)
                    ..where((table) => table.id.equals(item.accountId!.value)))
                  .getSingleOrNull();
          if (account == null) {
            throw const ValidationError('Expectation account is missing');
          }
          if (item.currency != null && account.currency != item.currency) {
            throw const ValidationError(
              'Expectation and account currencies must match',
            );
          }
        }
        await database
            .into(database.financialExpectations)
            .insertOnConflictUpdate(
              db.FinancialExpectationsCompanion(
                id: Value(item.id.value),
                occurrenceId: Value(item.occurrenceId.value),
                direction: Value(item.direction.index),
                minorUnits: Value(item.amount),
                currency: Value(item.currency),
                accountId: Value(item.accountId?.value),
                status: Value(item.status.index),
                createdAt: Value(item.createdAt.toUtc()),
                updatedAt: Value(item.updatedAt.toUtc()),
              ),
            );
      });
    },
  );

  FinancialExpectation _fromRow(db.FinancialExpectation row) =>
      FinancialExpectation(
        id: StableId.parse(row.id),
        occurrenceId: StableId.parse(row.occurrenceId),
        direction: FinancialExpectationDirection.values[row.direction],
        amount: row.minorUnits,
        currency: row.currency,
        accountId: row.accountId == null
            ? null
            : StableId.parse(row.accountId!),
        status: FinancialExpectationStatus.values[row.status],
        createdAt: row.createdAt.toUtc(),
        updatedAt: row.updatedAt.toUtc(),
      );
}
