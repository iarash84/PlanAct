import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';

/// Origin of an imported item. Adapters should normalize raw input before
/// creating a staged item and must never write directly to the ledger.
enum ImportSource { sms, file, manual }

enum StagedItemStatus { pending, confirmed, rejected, rolledBack }

enum SuggestionStatus { pending, confirmed, edited, rejected }

class ImportProvenance {
  ImportProvenance({
    required this.source,
    required this.sourceKey,
    required this.importedAt,
    this.adapterVersion = '1',
  }) {
    if (sourceKey.trim().isEmpty) {
      throw const ValidationError('Import source key cannot be empty');
    }
  }

  final ImportSource source;
  final String sourceKey;
  final DateTime importedAt;
  final String adapterVersion;
}

class StagedImport {
  StagedImport({
    required this.id,
    required this.rawText,
    required this.fingerprint,
    required this.provenance,
    this.status = StagedItemStatus.pending,
  });

  final StableId id;
  final String rawText;
  final String fingerprint;
  final ImportProvenance provenance;
  final StagedItemStatus status;

  StagedImport withStatus(StagedItemStatus next) => StagedImport(
    id: id,
    rawText: rawText,
    fingerprint: fingerprint,
    provenance: provenance,
    status: next,
  );
}

class TransactionDraft {
  TransactionDraft({
    required this.id,
    required this.stagedImportId,
    required this.amount,
    required this.occurredAt,
    required this.type,
    this.merchant,
    this.reference,
  });

  final StableId id;
  final StableId stagedImportId;
  final Money amount;
  final DateTime occurredAt;
  final String type;
  final String? merchant;
  final String? reference;
}

class InboxSuggestion {
  InboxSuggestion({
    required this.id,
    required this.stagedImportId,
    required this.draft,
    this.status = SuggestionStatus.pending,
  });

  final StableId id;
  final StableId stagedImportId;
  final TransactionDraft draft;
  final SuggestionStatus status;

  InboxSuggestion withDraft(TransactionDraft next) => InboxSuggestion(
    id: id,
    stagedImportId: stagedImportId,
    draft: next,
    status: SuggestionStatus.edited,
  );

  InboxSuggestion withStatus(SuggestionStatus next) => InboxSuggestion(
    id: id,
    stagedImportId: stagedImportId,
    draft: draft,
    status: next,
  );
}
