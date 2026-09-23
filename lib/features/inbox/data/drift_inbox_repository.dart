import 'package:drift/drift.dart';
import 'package:planact/core/database/app_database.dart' as db;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

class DriftInboxRepository implements InboxRepository {
  DriftInboxRepository(this.database);

  final db.AppDatabase database;

  @override
  Future<List<StagedImport>> listImports() async {
    final rows = await database.select(database.stagedImports).get();
    return rows
        .map(
          (row) => StagedImport(
            id: StableId.parse(row.id),
            rawText: row.rawText,
            fingerprint: row.fingerprint,
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
  }

  @override
  Future<List<InboxSuggestion>> listSuggestions() async {
    final rows = await database.select(database.inboxSuggestions).get();
    return rows
        .map(
          (row) => InboxSuggestion(
            id: StableId.parse(row.id),
            stagedImportId: StableId.parse(row.stagedImportId),
            status: SuggestionStatus.values[row.status],
            draft: TransactionDraft(
              id: StableId.parse(row.draftId),
              stagedImportId: StableId.parse(row.stagedImportId),
              amount: Money(minorUnits: row.minorUnits, currency: row.currency),
              occurredAt: row.occurredAt.toUtc(),
              type: row.type,
              merchant: row.merchant,
              reference: row.reference,
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> saveImport(StagedImport item) async {
    await database.into(database.stagedImports).insertOnConflictUpdate(
          db.StagedImportsCompanion(
            id: Value(item.id.value),
            rawText: Value(item.rawText),
            fingerprint: Value(item.fingerprint),
            source: Value(item.provenance.source.index),
            sourceKey: Value(item.provenance.sourceKey),
            importedAt: Value(item.provenance.importedAt.toUtc()),
            adapterVersion: Value(item.provenance.adapterVersion),
            status: Value(item.status.index),
          ),
        );
  }

  @override
  Future<void> saveSuggestion(InboxSuggestion suggestion) async {
    await database.into(database.inboxSuggestions).insertOnConflictUpdate(
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
  }
}
