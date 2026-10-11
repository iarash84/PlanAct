import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';

/// Origin of an imported item. Adapters normalize raw input before staging and
/// must never write directly to the ledger.
enum ImportSource { sms, file, manual }

enum StagedItemStatus { pending, confirmed, rejected, rolledBack }

enum RawTextRetentionStatus { pending, confirmed, rejected, expired }

enum SuggestionStatus { pending, confirmed, edited, rejected, duplicate }

enum TransactionDirection { incoming, outgoing, unknown }

enum ParseQuality { high, medium, low, unsupported }

/// Unknown is intentional for legacy records; never infer from saved timestamps.
enum TransactionDateSource { unknown, extracted, receipt }

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
    this.retentionStatus = RawTextRetentionStatus.pending,
    this.retentionUntil,
    this.lastDecisionAt,
  });

  final StableId id;

  /// Retained locally only until retentionUntil; never log or export without consent.
  final String rawText;
  final String fingerprint;
  final ImportProvenance provenance;
  final StagedItemStatus status;
  final RawTextRetentionStatus retentionStatus;
  final DateTime? retentionUntil;
  final DateTime? lastDecisionAt;

  StagedImport withStatus(StagedItemStatus next) => StagedImport(
    id: id,
    rawText: rawText,
    fingerprint: fingerprint,
    provenance: provenance,
    status: next,
    retentionStatus: next == StagedItemStatus.confirmed
        ? RawTextRetentionStatus.confirmed
        : next == StagedItemStatus.rejected
        ? RawTextRetentionStatus.rejected
        : retentionStatus,
    retentionUntil: retentionUntil,
    lastDecisionAt: DateTime.now().toUtc(),
  );

  StagedImport expireRawText() => StagedImport(
    id: id,
    rawText: '',
    fingerprint: fingerprint,
    provenance: provenance,
    status: status,
    retentionStatus: RawTextRetentionStatus.expired,
    retentionUntil: retentionUntil,
    lastDecisionAt: lastDecisionAt,
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
    this.direction = TransactionDirection.unknown,
    this.bank,
    this.accountHint,
    this.balance,
    this.quality = ParseQuality.low,
    this.confidence = 0,
    this.dateSource = TransactionDateSource.unknown,
    this.receivedAt,
  });

  final StableId id;
  final StableId stagedImportId;
  final Money amount;
  final DateTime occurredAt;
  final String type;
  final String? merchant;
  final String? reference;
  final TransactionDirection direction;
  final String? bank;
  final String? accountHint;
  final Money? balance;
  final ParseQuality quality;
  final int confidence;
  final TransactionDateSource dateSource;
  final DateTime? receivedAt;
}

class InboxSuggestion {
  InboxSuggestion({
    required this.id,
    required this.stagedImportId,
    required this.draft,
    this.status = SuggestionStatus.pending,
    this.revision = 0,
  });

  final StableId id;
  final StableId stagedImportId;
  final TransactionDraft draft;
  final SuggestionStatus status;
  final int revision;

  InboxSuggestion withDraft(TransactionDraft next) => InboxSuggestion(
    id: id,
    stagedImportId: stagedImportId,
    draft: next,
    status: SuggestionStatus.edited,
    revision: revision + 1,
  );

  InboxSuggestion withStatus(SuggestionStatus next) => InboxSuggestion(
    id: id,
    stagedImportId: stagedImportId,
    draft: draft,
    status: next,
    revision: revision + 1,
  );
}
