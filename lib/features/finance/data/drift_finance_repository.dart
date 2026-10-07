import 'package:planact/core/application/command_gate.dart';
import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';

class DriftFinanceRepository
    implements
        CommandGateProvider,
        FinanceRepository,
        AtomicFinanceCorrection,
        TaggedFinanceCreation {
  DriftFinanceRepository(this.database);

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);
  final db.AppDatabase database;

  @override
  Future<void> createTaggedEntry(AccountEntry entry, Set<String> tags) =>
      CommandGate.runFor(
        this,
        () => database.transaction(() async {
          await saveEntry(entry);
          final repository = DriftTagRepository(database);
          for (final label in tags) {
            final tag = await repository.getOrCreate(label);
            await repository.attach(
              recordId: entry.id.value,
              tag: tag,
              type: TaggableType.accountEntry,
            );
          }
        }),
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
                bank: IranianBank.fromCode(row.bankCode),
                status: FinancialAccountStatus.values[row.status],
              ),
            )
            .toList(growable: false);
      });

  @override
  Future<List<AccountEntry>> listEntries() => CommandGate.runFor(
    this,
    () async {
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
              category: row.category,
              source: AccountEntrySource.values[row.source],
              transferGroupId: row.transferGroupId == null
                  ? null
                  : StableId.parse(row.transferGroupId!),
            ),
          )
          .toList(growable: false);
    },
  );

  @override
  Future<void> saveAccount(FinancialAccount account) => database
      .into(database.financialAccounts)
      .insertOnConflictUpdate(_accountCompanion(account));

  @override
  Future<void> createAccount(
    FinancialAccount account, {
    AccountEntry? openingBalance,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      await database
          .into(database.financialAccounts)
          .insert(_accountCompanion(account));
      if (openingBalance != null) {
        await database
            .into(database.accountEntries)
            .insert(_entryCompanion(openingBalance));
      }
    }),
  );

  @override
  Future<void> saveTransfer({
    required AccountEntry outgoing,
    required AccountEntry incoming,
    AccountEntry? fee,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      await saveEntry(outgoing);
      await saveEntry(incoming);
      if (fee != null) await saveEntry(fee);
    }),
  );

  @override
  Future<void> saveCorrection({
    required AccountEntry reversal,
    required AccountEntry corrected,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      await saveEntry(reversal);
      await saveEntry(corrected);
    }),
  );

  @override
  Future<void> saveEntry(AccountEntry entry) =>
      CommandGate.runFor(this, () async {
        final existing = await (database.select(
          database.accountEntries,
        )..where((table) => table.id.equals(entry.id.value))).getSingleOrNull();
        if (existing != null) {
          final same =
              existing.accountId == entry.accountId.value &&
              existing.type == entry.type.index &&
              existing.minorUnits == entry.amount.minorUnits &&
              existing.currency == entry.amount.currency &&
              existing.occurredAt.toUtc() == entry.occurredAt.toUtc() &&
              existing.referenceId == entry.referenceId &&
              existing.note == entry.note &&
              existing.category == entry.category &&
              existing.source == entry.source.index &&
              existing.transferGroupId == entry.transferGroupId?.value;
          if (!same) {
            throw StateError('Financial ledger entries are immutable');
          }
          return;
        }
        await database
            .into(database.accountEntries)
            .insert(_entryCompanion(entry));
      });

  db.FinancialAccountsCompanion _accountCompanion(FinancialAccount account) =>
      db.FinancialAccountsCompanion(
        id: Value(account.id.value),
        name: Value(account.name),
        currency: Value(account.currency),
        type: Value(account.type.index),
        bankCode: Value(account.bank?.code),
        status: Value(account.status.index),
      );

  db.AccountEntriesCompanion _entryCompanion(AccountEntry entry) =>
      db.AccountEntriesCompanion(
        id: Value(entry.id.value),
        accountId: Value(entry.accountId.value),
        type: Value(entry.type.index),
        minorUnits: Value(entry.amount.minorUnits),
        currency: Value(entry.amount.currency),
        occurredAt: Value(entry.occurredAt.toUtc()),
        referenceId: Value(entry.referenceId),
        note: Value(entry.note),
        category: Value(entry.category),
        source: Value(entry.source.index),
        transferGroupId: Value(entry.transferGroupId?.value),
      );
}
