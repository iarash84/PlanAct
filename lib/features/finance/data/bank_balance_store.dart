import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';
import 'package:planact/features/finance/domain/finance.dart' as domain;

/// Called inside the caller's admitted transaction. Metadata is append-only;
/// active protection is derived from the immutable ledger and its reversals.
class BankBalanceStore {
  BankBalanceStore(this.database);
  final AppDatabase database;

  Future<List<Map<String, dynamic>>> _values(String prefix) async => [
    for (final row in await (database.select(
      database.schemaMetadata,
    )..where((t) => t.key.like('$prefix%'))).get())
      jsonDecode(row.value) as Map<String, dynamic>,
  ];

  Future<void> observe(BankBalanceObservation observation) async {
    await database.writeMetadata(
      'bank_observation_v1:${observation.id}',
      jsonEncode(observation.toJson()),
    );
  }

  Future<List<Map<String, dynamic>>> activeDecisions(
    String accountId,
    List<domain.AccountEntry> entries,
  ) async => [
    for (final decision in await _values('bank_reconciliation_v1:'))
      if (decision['accountId'] == accountId &&
          !entries.any(
            (e) =>
                e.type == domain.AccountEntryType.reversal &&
                e.referenceId == decision['entryId'],
          ))
        decision,
  ];

  Future<void> guardWrite(
    domain.AccountEntry entry,
    List<domain.AccountEntry> entries,
  ) async {
    final active = await activeDecisions(entry.accountId.value, entries);
    for (final decision in active) {
      if (decision['entryId'] == entry.id.value) continue;
      if (entry.type == domain.AccountEntryType.reversal &&
          entry.referenceId == decision['entryId']) {
        continue;
      }
      final boundary = DateTime.parse(decision['through'] as String);
      final original = entries
          .where((e) => e.id.value == entry.referenceId)
          .firstOrNull;
      if (!entry.occurredAt.isAfter(boundary) ||
          (entry.type == domain.AccountEntryType.reversal &&
              original != null &&
              !original.occurredAt.isAfter(boundary))) {
        throw const ValidationError(PersianCopy.bankBalanceBackdatedBlocked);
      }
    }
  }

  Future<BankBalanceSnapshot> snapshot(
    String accountId,
    List<domain.AccountEntry> entries,
  ) async {
    final observations =
        (await _values('bank_observation_v1:'))
            .map(BankBalanceObservation.fromJson)
            .where((o) => o.accountId == accountId)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final own = entries.where((e) => e.accountId.value == accountId).toList()
      ..sort((a, b) => a.id.value.compareTo(b.id.value));
    final active = await activeDecisions(accountId, entries);
    final token = sha256
        .convert(
          utf8.encode(
            jsonEncode({
              'observations': observations.map((o) => o.toJson()).toList(),
              'entries': [
                for (final e in own)
                  [
                    e.id.value,
                    e.type.index,
                    e.amount.minorUnits,
                    e.occurredAt.toUtc().toIso8601String(),
                    e.referenceId,
                  ],
              ],
              'active': active,
            }),
          ),
        )
        .toString();
    final dated = observations.where((o) => o.transactionTime != null).toList()
      ..sort((a, b) => b.transactionTime!.compareTo(a.transactionTime!));
    final latestTime = dated.firstOrNull?.transactionTime;
    return projectBankBalance(
      accountId: accountId,
      observations: observations,
      entries: entries,
      token: token,
      activeReconciliation:
          latestTime != null &&
          active.any(
            (decision) => !latestTime.isAfter(
              DateTime.parse(decision['through'] as String),
            ),
          ),
    );
  }

  Future<domain.AccountEntry> prepare(
    BankBalanceSnapshot expected,
    BankReconciliationReason reason,
    List<domain.AccountEntry> entries,
  ) async {
    final current = await snapshot(expected.accountId, entries);
    final account = await (database.select(
      database.financialAccounts,
    )..where((t) => t.id.equals(expected.accountId))).getSingle();
    if (account.currency != 'IRR' ||
        account.status != 0 ||
        current.token != expected.token ||
        !current.canReconcile ||
        (reason == BankReconciliationReason.knownFee &&
            current.difference! >= 0)) {
      throw const ValidationError(PersianCopy.bankBalanceStale);
    }
    final entry = domain.AccountEntry(
      id: StableId.generate(),
      accountId: StableId.parse(account.id),
      type: reason == BankReconciliationReason.knownFee
          ? domain.AccountEntryType.expense
          : domain.AccountEntryType.adjustment,
      amount: Money(
        minorUnits: reason == BankReconciliationReason.knownFee
            ? -current.difference!
            : current.difference!,
        currency: 'IRR',
      ),
      occurredAt: current.latest!.transactionTime!,
      note: reason == BankReconciliationReason.knownFee
          ? PersianCopy.bankBalanceKnownFee
          : PersianCopy.bankBalanceUnknownAdjustment,
    );
    await database.writeMetadata(
      'bank_reconciliation_v1:${entry.id.value}',
      jsonEncode({
        'version': 1,
        'accountId': account.id,
        'entryId': entry.id.value,
        'observationId': current.latest!.id,
        'through': current.latest!.transactionTime!.toUtc().toIso8601String(),
        'reason': reason.name,
        'before': current.ledgerAtReport,
        'difference': current.difference,
        'token': current.token,
      }),
    );
    return entry;
  }
}
