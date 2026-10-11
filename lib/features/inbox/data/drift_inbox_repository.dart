import 'dart:convert';

import 'package:planact/core/application/command_gate.dart';
import 'package:drift/drift.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

class DriftInboxRepository
    implements
        CommandGateProvider,
        InboxRepository,
        AtomicInboxConfirmation,
        AtomicInboxStaging,
        AtomicInboxReview,
        SmsScanStore {
  DriftInboxRepository(this.database);

  @override
  CommandGate? get commandGate => CommandGate.forOwner(database);

  final db.AppDatabase database;
  static const smsScanMetadataKey = 'sms_scan_v1';

  String _key(String id) => 'inbox_review_v1:$id';

  Future<Map<String, dynamic>> _metadata(String id) async {
    final value = await database.readMetadata(_key(id));
    if (value == null) {
      return {'version': 1, 'revision': 0, 'history': <dynamic>[]};
    }
    final result = jsonDecode(value) as Map<String, dynamic>;
    if (result['version'] != 1) throw StateError('Unsupported Inbox metadata');
    return result;
  }

  Future<void> _decision(
    String id,
    Map<String, dynamic> metadata,
    String action,
  ) async {
    metadata['revision'] = (metadata['revision'] as int) + 1;
    metadata['history'] = [
      ...metadata['history'] as List<dynamic>,
      {
        'revision': metadata['revision'],
        'action': action,
        'at': DateTime.now().toUtc().toIso8601String(),
      },
    ];
    await database.writeMetadata(_key(id), jsonEncode(metadata));
  }

  @override
  Future<void> reviewAtomically(
    InboxSuggestion suggestion, {
    required bool recover,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final row = await (database.select(
        database.inboxSuggestions,
      )..where((t) => t.id.equals(suggestion.id.value))).getSingle();
      final metadata = await _metadata(row.id);
      if (metadata['revision'] != suggestion.revision ||
          row.status != suggestion.status.index) {
        throw const ValidationError(
          'تغییر جدیدی ثبت شده است؛ ابتدا بازخوانی کنید.',
        );
      }
      if (recover
          ? row.status != SuggestionStatus.rejected.index
          : row.status != SuggestionStatus.pending.index &&
                row.status != SuggestionStatus.edited.index) {
        throw const ValidationError(
          'تراکنش تأییدشده را از بخش مالی اصلاح کنید.',
        );
      }
      await (database.update(
        database.inboxSuggestions,
      )..where((t) => t.id.equals(row.id))).write(
        db.InboxSuggestionsCompanion(
          status: Value(
            (recover ? SuggestionStatus.pending : SuggestionStatus.rejected)
                .index,
          ),
        ),
      );
      final staged = await (database.select(
        database.stagedImports,
      )..where((t) => t.id.equals(row.stagedImportId))).getSingle();
      await (database.update(
        database.stagedImports,
      )..where((t) => t.id.equals(staged.id))).write(
        db.StagedImportsCompanion(
          status: Value(
            (recover ? StagedItemStatus.rolledBack : StagedItemStatus.rejected)
                .index,
          ),
          retentionStatus: Value(
            staged.retentionStatus == RawTextRetentionStatus.expired.index
                ? staged.retentionStatus
                : (recover
                          ? RawTextRetentionStatus.pending
                          : RawTextRetentionStatus.rejected)
                      .index,
          ),
          lastDecisionAt: Value(DateTime.now().toUtc()),
        ),
      );
      await _decision(row.id, metadata, recover ? 'reopened' : 'rejected');
    }),
  );

  @override
  Future<String?> readSmsScan() =>
      CommandGate.runFor(this, () => database.readMetadata(smsScanMetadataKey));

  @override
  Future<void> writeSmsScan(String? expected, String value) =>
      CommandGate.runFor(
        this,
        () => database.transaction(() async {
          if (await database.readMetadata(smsScanMetadataKey) != expected) {
            throw StateError('SMS scan changed; reload before retrying');
          }
          await database.writeMetadata(smsScanMetadataKey, value);
        }),
      );

  @override
  Future<InboxSuggestion> stageAtomically({
    required StagedImport staged,
    required InboxSuggestion suggestion,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final imports = await listImports();
      final sourceDuplicate = imports.where(
        (item) =>
            item.provenance.source == staged.provenance.source &&
            item.provenance.sourceKey == staged.provenance.sourceKey,
      );
      if (sourceDuplicate.isNotEmpty) {
        if (sourceDuplicate.first.fingerprint != staged.fingerprint) {
          throw const ValidationError(
            'Source key belongs to different content',
          );
        }
        final suggestions = await listSuggestions();
        return suggestions.firstWhere(
          (item) => item.stagedImportId == sourceDuplicate.first.id,
        );
      }
      if (imports.any((item) => item.fingerprint == staged.fingerprint)) {
        throw const DuplicateSmsImport();
      }
      await saveImport(staged);
      await saveSuggestion(suggestion);
      return suggestion;
    }),
  );

  @override
  Future<void> rejectAtomically(StableId suggestionId) async {
    final suggestion = (await listSuggestions()).firstWhere(
      (s) => s.id == suggestionId,
    );
    await reviewAtomically(suggestion, recover: false);
  }

  @override
  Future<AccountEntry> confirmAtomically({
    required StableId suggestionId,
    required AccountEntry entry,
    int? expectedRevision,
  }) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final suggestion =
          await (database.select(database.inboxSuggestions)
                ..where((table) => table.id.equals(suggestionId.value)))
              .getSingleOrNull();
      if (suggestion == null) throw StateError('Suggestion was not found');
      final staged =
          await (database.select(database.stagedImports)
                ..where((table) => table.id.equals(suggestion.stagedImportId)))
              .getSingleOrNull();
      if (staged == null) throw StateError('Import was not found');
      if (suggestion.status == SuggestionStatus.rejected.index ||
          staged.status == StagedItemStatus.rejected.index) {
        throw StateError('Rejected imports cannot be confirmed');
      }
      if (suggestion.status == SuggestionStatus.confirmed.index) {
        final entries = await DriftFinanceRepository(database).listEntries();
        final persisted = entries.where((item) => item.id == entry.id);
        if (persisted.isEmpty ||
            persisted.single.accountId != entry.accountId ||
            persisted.single.amount != entry.amount ||
            persisted.single.type != entry.type ||
            persisted.single.occurredAt != entry.occurredAt ||
            persisted.single.referenceId != entry.referenceId ||
            persisted.single.note != entry.note) {
          throw StateError('Import already confirmed with different details');
        }
        return persisted.single;
      }
      final metadata = await _metadata(suggestion.id);
      if (expectedRevision != null &&
          metadata['revision'] != expectedRevision) {
        throw const ValidationError(
          'پیشنهاد تغییر کرده است؛ ابتدا بازخوانی کنید.',
        );
      }
      if (suggestion.status != SuggestionStatus.confirmed.index) {
        if (suggestion.minorUnits != entry.amount.minorUnits ||
            suggestion.currency != entry.amount.currency ||
            suggestion.occurredAt.toUtc() != entry.occurredAt.toUtc() ||
            suggestion.reference != entry.referenceId ||
            suggestion.merchant != entry.note ||
            (suggestion.type == 'income') !=
                (entry.type == AccountEntryType.income)) {
          throw StateError('Suggestion changed; reload before confirming');
        }
        final account =
            await (database.select(database.financialAccounts)
                  ..where((table) => table.id.equals(entry.accountId.value)))
                .getSingleOrNull();
        if (account == null ||
            account.status != FinancialAccountStatus.active.index ||
            account.currency != entry.amount.currency) {
          throw StateError('Account is unavailable for this import');
        }
        await DriftFinanceRepository(database).saveEntry(entry);
        await _decision(suggestion.id, metadata, 'confirmed');
        await (database.update(
          database.inboxSuggestions,
        )..where((table) => table.id.equals(suggestionId.value))).write(
          db.InboxSuggestionsCompanion(
            status: Value(SuggestionStatus.confirmed.index),
          ),
        );
        await (database.update(
          database.stagedImports,
        )..where((table) => table.id.equals(staged.id))).write(
          db.StagedImportsCompanion(
            status: Value(StagedItemStatus.confirmed.index),
          ),
        );
      }
      final entries = await DriftFinanceRepository(database).listEntries();
      return entries.firstWhere((item) => item.id == entry.id);
    }),
  );

  @override
  Future<List<StagedImport>> listImports() =>
      CommandGate.runFor(this, () async {
        final rows = await database.select(database.stagedImports).get();
        return rows
            .map(
              (row) => StagedImport(
                id: StableId.parse(row.id),
                rawText: row.rawText,
                fingerprint: row.fingerprint,
                retentionStatus:
                    RawTextRetentionStatus.values[row.retentionStatus],
                retentionUntil: row.retentionUntil?.toUtc(),
                lastDecisionAt: row.lastDecisionAt?.toUtc(),
                provenance: ImportProvenance(
                  source: ImportSource.values[row.source],
                  sourceKey: row.sourceKey,
                  importedAt: row.importedAt.toUtc(),
                  adapterVersion: row.adapterVersion,
                ),
                status: StagedItemStatus.values[row.status],
              ),
            )
            .toList(growable: false);
      });

  @override
  Future<List<InboxSuggestion>> listSuggestions() => CommandGate.runFor(
    this,
    () async {
      final rows = await database.select(database.inboxSuggestions).get();
      final metadataRows = await (database.select(
        database.schemaMetadata,
      )..where((t) => t.key.like('inbox_review_v1:%'))).get();
      final byId = {for (final row in metadataRows) row.key: row.value};
      final result = <InboxSuggestion>[];
      for (final row in rows) {
        final value = byId[_key(row.id)];
        final metadata = value == null
            ? <String, dynamic>{'version': 1, 'revision': 0}
            : jsonDecode(value) as Map<String, dynamic>;
        if (metadata['version'] != 1) {
          throw StateError('Unsupported Inbox metadata');
        }
        result.add(
          InboxSuggestion(
            id: StableId.parse(row.id),
            stagedImportId: StableId.parse(row.stagedImportId),
            status: SuggestionStatus.values[row.status],
            revision: metadata['revision'] as int,
            draft: TransactionDraft(
              id: StableId.parse(row.draftId),
              stagedImportId: StableId.parse(row.stagedImportId),
              amount: Money(minorUnits: row.minorUnits, currency: row.currency),
              occurredAt: row.occurredAt.toUtc(),
              type: row.type,
              merchant: row.merchant,
              reference: row.reference,
              bank: metadata['bank'] as String?,
              receivedAt: metadata['receivedAt'] == null
                  ? null
                  : DateTime.parse(metadata['receivedAt'] as String),
              direction: TransactionDirection.values.byName(
                metadata['direction'] as String? ?? 'unknown',
              ),
              quality: ParseQuality.values.byName(
                metadata['quality'] as String? ?? 'low',
              ),
              confidence: metadata['confidence'] as int? ?? 0,
              balance: metadata['balance'] == null
                  ? null
                  : Money(
                      minorUnits: metadata['balance'] as int,
                      currency: metadata['balanceCurrency'] as String,
                    ),
              accountHint: metadata['accountHint'] as String?,
              dateSource: TransactionDateSource.values.byName(
                metadata['dateSource'] as String? ?? 'unknown',
              ),
            ),
          ),
        );
      }
      return result;
    },
  );

  @override
  Future<void> saveImport(StagedImport item) =>
      CommandGate.runFor(this, () async {
        await database
            .into(database.stagedImports)
            .insertOnConflictUpdate(
              db.StagedImportsCompanion(
                id: Value(item.id.value),
                rawText: Value(item.rawText),
                fingerprint: Value(item.fingerprint),
                source: Value(item.provenance.source.index),
                sourceKey: Value(item.provenance.sourceKey),
                importedAt: Value(item.provenance.importedAt.toUtc()),
                adapterVersion: Value(item.provenance.adapterVersion),
                status: Value(item.status.index),
                retentionStatus: Value(item.retentionStatus.index),
                retentionUntil: Value(item.retentionUntil?.toUtc()),
                lastDecisionAt: Value(item.lastDecisionAt?.toUtc()),
              ),
            );
      });

  @override
  Future<void> saveSuggestion(InboxSuggestion suggestion) => CommandGate.runFor(
    this,
    () => database.transaction(() async {
      final stored =
          await (database.select(database.inboxSuggestions)
                ..where((table) => table.id.equals(suggestion.id.value)))
              .getSingleOrNull();
      if (stored != null &&
          (stored.status == SuggestionStatus.confirmed.index ||
              stored.status == SuggestionStatus.rejected.index)) {
        throw const ValidationError('پیشنهاد بررسی‌شده قابل بازنویسی نیست.');
      }
      final metadata = await _metadata(suggestion.id.value);
      if (stored != null &&
          suggestion.revision != (metadata['revision'] as int) + 1) {
        throw const ValidationError(
          'پیشنهاد تغییر کرده است؛ ابتدا بازخوانی کنید.',
        );
      }
      metadata.addAll({
        'bank': suggestion.draft.bank,
        'direction': suggestion.draft.direction.name,
        'quality': suggestion.draft.quality.name,
        'confidence': suggestion.draft.confidence,
        'accountHint': suggestion.draft.accountHint,
        'dateSource': suggestion.draft.dateSource.name,
        'receivedAt': suggestion.draft.receivedAt?.toIso8601String(),
        'balance': suggestion.draft.balance?.minorUnits,
        'balanceCurrency': suggestion.draft.balance?.currency,
      });
      if (stored == null) {
        await database.writeMetadata(
          _key(suggestion.id.value),
          jsonEncode(metadata),
        );
      } else {
        await _decision(suggestion.id.value, metadata, 'edited');
      }
      await database
          .into(database.inboxSuggestions)
          .insertOnConflictUpdate(
            db.InboxSuggestionsCompanion(
              id: Value(suggestion.id.value),
              stagedImportId: Value(suggestion.stagedImportId.value),
              draftId: Value(suggestion.draft.id.value),
              minorUnits: Value(suggestion.draft.amount.minorUnits),
              currency: Value(suggestion.draft.amount.currency),
              occurredAt: Value(suggestion.draft.occurredAt.toUtc()),
              type: Value(suggestion.draft.type),
              merchant: Value(suggestion.draft.merchant),
              reference: Value(suggestion.draft.reference),
              status: Value(suggestion.status.index),
            ),
          );
    }),
  );
}
