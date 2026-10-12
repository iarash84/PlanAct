import 'dart:convert';

import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/finance/domain/account_identifiers.dart';
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
        AtomicAccountEditing,
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
        return Future.wait(rows.map(_readAccount));
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

  Future<FinancialAccount> _readAccount(db.FinancialAccount row) async {
    final raw = await database.readMetadata('account_identifiers_v1:${row.id}');
    var identifiers = AccountIdentifiers.empty;
    if (raw != null) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      if (data['version'] != 1) {
        throw const ValidationError('Unsupported account metadata');
      }
      identifiers = AccountIdentifiers(
        cardNumber: data['cardNumber'] as String?,
        iban: data['iban'] as String?,
        accountNumber: data['accountNumber'] as String?,
      );
    }
    return FinancialAccount(
      id: StableId.parse(row.id),
      name: row.name,
      currency: row.currency,
      type: FinancialAccountType.values[row.type],
      bank: IranianBank.fromCode(row.bankCode),
      status: FinancialAccountStatus.values[row.status],
      identifiers: identifiers,
    );
  }

  Future<void> _writeIdentifiers(FinancialAccount account) =>
      database.writeMetadata(
        'account_identifiers_v1:${account.id.value}',
        jsonEncode({
          'version': 1,
          'cardNumber': account.identifiers.cardNumber,
          'iban': account.identifiers.iban,
          'accountNumber': account.identifiers.accountNumber,
        }),
      );

  @override
  Future<void> editAccount({
    required FinancialAccount original,
    required FinancialAccount replacement,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final row = await (database.select(
        database.financialAccounts,
      )..where((t) => t.id.equals(original.id.value))).getSingleOrNull();
      if (row == null || original.id != replacement.id) {
        throw const ValidationError('Account missing');
      }
      final fresh = await _readAccount(row);
      if (!fresh.sameEditableFields(original)) {
        throw const ValidationError('Account edit conflict');
      }
      await (database.update(
        database.financialAccounts,
      )..where((t) => t.id.equals(row.id))).write(
        db.FinancialAccountsCompanion(
          name: Value(replacement.name),
          type: Value(replacement.type.index),
          bankCode: Value(replacement.bank?.code),
        ),
      );
      await _writeIdentifiers(replacement);
    }),
  );

  @override
  Future<void> setAccountStatus(StableId id, FinancialAccountStatus status) =>
      CommandGate.runFor(
        this,
        () => database.transaction(() async {
          final count =
              await (database.update(
                database.financialAccounts,
              )..where((t) => t.id.equals(id.value))).write(
                db.FinancialAccountsCompanion(status: Value(status.index)),
              );
          if (count != 1) throw const ValidationError('Account missing');
        }),
      );

  @override
  Future<void> saveAccount(FinancialAccount account) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final row = await (database.select(
        database.financialAccounts,
      )..where((t) => t.id.equals(account.id.value))).getSingleOrNull();
      if (row != null) {
        throw const ValidationError(
          'Existing accounts require fresh edit admission',
        );
      }
      await database
          .into(database.financialAccounts)
          .insert(_accountCompanion(account));
      await _writeIdentifiers(account);
    }),
  );

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
      await _writeIdentifiers(account);
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
  Future<void> saveEntry(AccountEntry entry) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
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
      final account =
          await (database.select(database.financialAccounts)
                ..where((table) => table.id.equals(entry.accountId.value)))
              .getSingleOrNull();
      if (account == null ||
          account.currency != entry.amount.currency ||
          (account.status != FinancialAccountStatus.active.index &&
              entry.type != AccountEntryType.reversal &&
              entry.type != AccountEntryType.refund)) {
        throw StateError('Account is unavailable for this entry');
      }
      await database
          .into(database.accountEntries)
          .insert(_entryCompanion(entry));
    }),
  );

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
