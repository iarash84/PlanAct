import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';

class DriftFinanceRepository implements FinanceRepository {
  DriftFinanceRepository(this.database);
  final db.AppDatabase database;

  @override
  Future<List<FinancialAccount>> listAccounts() async {
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
        .toList(growable: false);
  }

  @override
  Future<List<AccountEntry>> listEntries() async {
    final rows = await database.select(database.accountEntries).get();
    return rows
        .map(
          (row) => AccountEntry(
            id: StableId.parse(row.id),
            accountId: StableId.parse(row.accountId),
            type: AccountEntryType.values[row.type],
            amount: Money(minorUnits: row.minorUnits, currency: row.currency),
            occurredAt: row.occurredAt.toUtc(),
            referenceId: row.referenceId,
            note: row.note,
            transferGroupId: row.transferGroupId == null
                ? null
                : StableId.parse(row.transferGroupId!),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveAccount(FinancialAccount account) => database
      .into(database.financialAccounts)
      .insertOnConflictUpdate(
        db.FinancialAccountsCompanion(
          id: Value(account.id.value),
          name: Value(account.name),
          currency: Value(account.currency),
          type: Value(account.type.index),
          status: Value(account.status.index),
        ),
      );

  @override
  Future<void> saveEntry(AccountEntry entry) => database
      .into(database.accountEntries)
      .insertOnConflictUpdate(
        db.AccountEntriesCompanion(
          id: Value(entry.id.value),
          accountId: Value(entry.accountId.value),
          type: Value(entry.type.index),
          minorUnits: Value(entry.amount.minorUnits),
          currency: Value(entry.amount.currency),
          occurredAt: Value(entry.occurredAt.toUtc()),
          referenceId: Value(entry.referenceId),
          note: Value(entry.note),
          transferGroupId: Value(entry.transferGroupId?.value),
        ),
      );
}
