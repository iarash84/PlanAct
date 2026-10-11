import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';

import 'sms_currency_evidence.dart';

/// Origin of an imported item. Adapters normalize raw input before staging and
/// must never write directly to the ledger.
enum ImportSource { sms, file, manual }

enum StagedItemStatus { pending, confirmed, rejected, rolledBack }

enum RawTextRetentionStatus { pending, confirmed, rejected, expired }

enum SuggestionStatus { pending, confirmed, edited, rejected, duplicate }

enum TransactionDirection { incoming, outgoing, unknown }

enum ParseQuality { high, medium, low, unsupported }

/// Unknown is intentional for legacy records; never infer from saved timestamps.
enum TransactionDateSource { unknown, extracted, receipt, reviewer }

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
    this.currencyEvidence,
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
  final SmsCurrencyEvidence? currencyEvidence;

  /// Complete reviewed snapshot for append-only edit/confirmation history.
  Map<String, dynamic> toReviewJson() => {
    'id': id.value,
    'stagedImportId': stagedImportId.value,
    'minorUnits': amount.minorUnits,
    'currency': amount.currency,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'type': type,
    'merchant': merchant,
    'reference': reference,
    'direction': direction.name,
    'bank': bank,
    'accountHint': accountHint,
    'balance': balance?.minorUnits,
    'balanceCurrency': balance?.currency,
    'quality': quality.name,
    'confidence': confidence,
    'dateSource': dateSource.name,
    'receivedAt': receivedAt?.toUtc().toIso8601String(),
    'currencyEvidence': currencyEvidence?.toJson(),
  };

  factory TransactionDraft.fromReviewJson(Map<String, dynamic> json) =>
      TransactionDraft(
        id: StableId.parse(json['id'] as String),
        stagedImportId: StableId.parse(json['stagedImportId'] as String),
        amount: Money(
          minorUnits: json['minorUnits'] as int,
          currency: json['currency'] as String,
        ),
        occurredAt: DateTime.parse(json['occurredAt'] as String),
        type: json['type'] as String,
        merchant: json['merchant'] as String?,
        reference: json['reference'] as String?,
        direction: TransactionDirection.values.byName(
          json['direction'] as String? ?? 'unknown',
        ),
        bank: json['bank'] as String?,
        accountHint: json['accountHint'] as String?,
        balance: json['balance'] == null
            ? null
            : Money(
                minorUnits: json['balance'] as int,
                currency: json['balanceCurrency'] as String,
              ),
        quality: ParseQuality.values.byName(
          json['quality'] as String? ?? 'low',
        ),
        confidence: json['confidence'] as int? ?? 0,
        dateSource: TransactionDateSource.values.byName(
          json['dateSource'] as String? ?? 'unknown',
        ),
        receivedAt: json['receivedAt'] == null
            ? null
            : DateTime.parse(json['receivedAt'] as String),
        currencyEvidence: json['currencyEvidence'] == null
            ? null
            : SmsCurrencyEvidence.fromJson(
                json['currencyEvidence'] as Map<String, dynamic>,
              ),
      );

  void validateConfirmation({SmsExtractionEvidence? extractedEvidence}) {
    if (extractedEvidence?.isTransfer == true || type == 'transfer') {
      throw const ValidationError(
        'ثبت انتقال از پیامک در این مسیر پشتیبانی نمی‌شود.',
      );
    }
    if (type != 'income' && type != 'expense') {
      throw const ValidationError('نوع تراکنش را صریحاً انتخاب کنید.');
    }
    if (amount.minorUnits <= 0 ||
        BigInt.from(amount.minorUnits) > BigInt.parse('9223372036854775807')) {
      throw const ValidationError('مبلغ معتبر و مثبت وارد کنید.');
    }
    final evidence = currencyEvidence;
    if (evidence != null) {
      final unit = evidence.effectiveUnit;
      if (unit == null) {
        throw const ValidationError('واحد مبلغ پیامک را صریحاً انتخاب کنید.');
      }
      if (amount.currency != 'IRR' ||
          unit.canonicalIrr(evidence.sourceAmount) != amount.minorUnits) {
        throw const ValidationError(
          'مبلغ و واحد بررسی‌شده با هم سازگار نیستند.',
        );
      }
    }
  }
}

class InboxSuggestion {
  InboxSuggestion({
    required this.id,
    required this.stagedImportId,
    required this.draft,
    this.status = SuggestionStatus.pending,
    this.revision = 0,
    this.extractedEvidence,
  });

  final StableId id;
  final StableId stagedImportId;
  final TransactionDraft draft;
  final SuggestionStatus status;
  final int revision;

  /// Original parser output. Null means legacy unknown, never reparsed evidence.
  final SmsExtractionEvidence? extractedEvidence;

  InboxSuggestion withDraft(TransactionDraft next) => InboxSuggestion(
    id: id,
    stagedImportId: stagedImportId,
    draft: next,
    status: SuggestionStatus.edited,
    revision: revision + 1,
    extractedEvidence: extractedEvidence,
  );

  InboxSuggestion withStatus(SuggestionStatus next) => InboxSuggestion(
    id: id,
    stagedImportId: stagedImportId,
    draft: draft,
    status: next,
    revision: revision + 1,
    extractedEvidence: extractedEvidence,
  );
}

/// Immutable original extracted values, separate from all reviewed corrections.
class SmsExtractionEvidence {
  const SmsExtractionEvidence({
    required this.draft,
    this.sourceDate,
    this.sourceTime,
    this.occurredAt,
    this.isTransfer = false,
  });

  final TransactionDraft draft;
  final String? sourceDate;
  final String? sourceTime;

  /// Original complete parsed timestamp only; never the draft receipt fallback.
  final DateTime? occurredAt;
  final bool isTransfer;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'draft': draft.toReviewJson(),
    'sourceDate': sourceDate,
    'sourceTime': sourceTime,
    'occurredAt': occurredAt?.toIso8601String(),
    'isTransfer': isTransfer,
  };

  factory SmsExtractionEvidence.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const ValidationError('نسخهٔ شواهد پیامک پشتیبانی نمی‌شود.');
    }
    return SmsExtractionEvidence(
      draft: TransactionDraft.fromReviewJson(
        json['draft'] as Map<String, dynamic>,
      ),
      sourceDate: json['sourceDate'] as String?,
      sourceTime: json['sourceTime'] as String?,
      occurredAt: json['occurredAt'] == null
          ? null
          : DateTime.parse(json['occurredAt'] as String),
      isTransfer: json['isTransfer'] as bool? ?? false,
    );
  }
}
