import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/application/command_gate.dart';

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

import 'package:planact/features/inbox/application/real_bank_sms_parser.dart';

abstract interface class InboxRepository {
  Future<List<StagedImport>> listImports();
  Future<List<InboxSuggestion>> listSuggestions();
  Future<void> saveImport(StagedImport item);
  Future<void> saveSuggestion(InboxSuggestion suggestion);
}

/// Implementations with a shared durable database must commit all three writes
/// in one transaction. The entry ID is stable across retries and restarts.
abstract interface class AtomicInboxStaging {
  Future<InboxSuggestion> stageAtomically({
    required StagedImport staged,
    required InboxSuggestion suggestion,
  });

  Future<void> rejectAtomically(StableId suggestionId);
}

abstract interface class AtomicInboxReview {
  Future<void> reviewAtomically(
    InboxSuggestion suggestion, {
    required bool recover,
  });
}

abstract interface class AtomicInboxConfirmation {
  Future<AccountEntry> confirmAtomically({
    required StableId suggestionId,
    required AccountEntry entry,
    int? expectedRevision,
    SmsMoneyUnit? selectedUnit,
  });
}

/// Normalizes an external source into a staged import. Adapters must not write
/// to finance repositories or any final ledger.
abstract interface class ImportSourceAdapter {
  ImportSource get source;
  Future<InboxSuggestion> stage({
    required InboxUseCases useCases,
    required String rawText,
    required String sourceKey,
    required String currency,
    DateTime? importedAt,
  });
}

class SmsImportAdapter implements ImportSourceAdapter {
  const SmsImportAdapter();

  @override
  ImportSource get source => ImportSource.sms;

  @override
  Future<InboxSuggestion> stage({
    required InboxUseCases useCases,
    required String rawText,
    required String sourceKey,
    required String currency,
    DateTime? importedAt,
  }) => useCases.stageSms(
    rawText: rawText,
    sourceKey: sourceKey,
    currency: currency,
    importedAt: importedAt,
  );
}

class InMemoryInboxRepository implements InboxRepository {
  final Map<StableId, StagedImport> _imports = {};
  final Map<StableId, InboxSuggestion> _suggestions = {};

  @override
  Future<List<StagedImport>> listImports() async =>
      List.unmodifiable(_imports.values);

  @override
  Future<List<InboxSuggestion>> listSuggestions() async =>
      List.unmodifiable(_suggestions.values);

  @override
  Future<void> saveImport(StagedImport item) async => _imports[item.id] = item;

  @override
  Future<void> saveSuggestion(InboxSuggestion suggestion) async =>
      _suggestions[suggestion.id] = suggestion;
}

class UnsupportedSmsFormat extends ValidationError {
  const UnsupportedSmsFormat() : super(PersianCopy.inboxUseCasesMessage);
}

class DuplicateSmsImport extends ValidationError {
  const DuplicateSmsImport() : super(PersianCopy.inboxUseCasesMessage2);
}

class ParsedSms {
  const ParsedSms({
    required this.amount,
    required this.occurredAt,
    required this.direction,
    required this.quality,
    required this.confidence,
    this.merchant,
    this.reference,
    this.bank,
    this.sourceAddress,
    this.accountHint,
    this.balance,
    this.currencyEvidence,
    this.sourceDate,
    this.sourceTime,
    this.isTransfer = false,
  });

  /// Validated original calendar date/time, not a receipt fallback or instant.
  final String? sourceDate;
  final String? sourceTime;
  final bool isTransfer;

  final Money amount;
  final DateTime? occurredAt;
  final TransactionDirection direction;
  final ParseQuality quality;
  final int confidence;
  final String? merchant;
  final String? reference;
  final String? bank;
  final String? sourceAddress;
  final String? accountHint;
  final Money? balance;
  final SmsCurrencyEvidence? currencyEvidence;
}

abstract interface class SmsFormatParser {
  ParsedSms? tryParse({required String text, required String currency});
}

class LocalSmsParser implements SmsFormatParser {
  const LocalSmsParser({
    this.parsers = const [GenericBankSmsParser(), RealBankSmsParser()],
  });

  final List<SmsFormatParser> parsers;

  ParsedSms parse({required String text, required String currency}) {
    for (final parser in parsers) {
      final result = parser.tryParse(text: text, currency: currency);
      if (result != null) return result;
    }
    throw const UnsupportedSmsFormat();
  }

  @override
  ParsedSms? tryParse({required String text, required String currency}) {
    try {
      return parse(text: text, currency: currency);
    } on ValidationError {
      return null;
    }
  }
}

/// Conservative synthetic labelled templates only; not actual-bank coverage.
/// See docs/SMS_VERIFICATION.md for the exact grammar and integration gates.
class GenericBankSmsParser implements SmsFormatParser {
  const GenericBankSmsParser();

  static const _labels = {
    'مبلغ': 'amount',
    'amount': 'amount',
    'مانده': 'balance',
    'موجودی': 'balance',
    'balance': 'balance',
    'نوع': 'type',
    'type': 'type',
    'بانک': 'bank',
    'bank': 'bank',
    'حساب': 'account',
    'کارت': 'account',
    'account': 'account',
    'card': 'account',
    'پیگیری': 'reference',
    'شناسه': 'reference',
    'ref': 'reference',
    'reference': 'reference',
    'پذیرنده': 'merchant',
    'فروشگاه': 'merchant',
    'merchant': 'merchant',
    'تاریخ': 'date',
    'date': 'date',
    'ساعت': 'time',
    'time': 'time',
  };
  static const _incoming = {'واریز', 'deposit', 'credit'};
  static const _outgoing = {
    'برداشت',
    'خرید',
    'پرداخت',
    'withdrawal',
    'purchase',
    'debit',
  };
  static const _transfers = {'انتقال', 'کارت به کارت', 'transfer'};

  @override
  ParsedSms? tryParse({required String text, required String currency}) {
    if (text.length > 4096) return null;
    final normalized = _normalizeDigits(text).trim();
    // Reject these anywhere, including an otherwise valid labelled message.
    if (RegExp(
      r'رمز|ناموفق|لغو|خطا|اعلان|otp|password|failed|failure|declined|unsuccessful|notification',
      caseSensitive: false,
    ).hasMatch(normalized)) {
      return null;
    }
    final fields = <String, String>{};
    for (final line in normalized.split(RegExp(r'[\r\n;؛]+'))) {
      if (line.trim().isEmpty) continue;
      final compact = RegExp(
        r'^(برداشت|واریز|خرید|پرداخت|withdrawal|deposit|purchase)\s+(?:مبلغ|amount)\s*[:：]?\s*(.+)$',
        caseSensitive: false,
      ).firstMatch(line.trim());
      if (compact != null) {
        if (fields.containsKey('type') || fields.containsKey('amount')) {
          return null;
        }
        fields['type'] = compact.group(1)!.toLowerCase();
        fields['amount'] = compact.group(2)!;
        continue;
      }
      final label = RegExp(r'^([^:：]+)[:：]\s*(.+)$').firstMatch(line.trim());
      if (label == null) return null;
      final key = _labels[label.group(1)!.trim().toLowerCase()];
      if (key == null || fields.containsKey(key)) return null;
      fields[key] = label.group(2)!.trim();
    }
    final amount = _amount(fields['amount']);
    if (amount == null || amount.$1 <= 0) return null;
    final type = fields['type']?.toLowerCase();
    if (type != null &&
        !_incoming.contains(type) &&
        !_outgoing.contains(type) &&
        !_transfers.contains(type) &&
        type != 'unknown' &&
        type != 'نامعلوم') {
      return null;
    }
    final direction = _incoming.contains(type)
        ? TransactionDirection.incoming
        : _outgoing.contains(type)
        ? TransactionDirection.outgoing
        : TransactionDirection.unknown;
    final balance = _amount(fields['balance']);
    if (fields.containsKey('balance') &&
        (balance == null || balance.$2 == null)) {
      return null;
    }
    final date = _date(fields['date']);
    final time = _time(fields['time']);
    if ((fields.containsKey('date') && date == null) ||
        (fields.containsKey('time') && time == null)) {
      return null;
    }
    final account = fields['account'];
    if (account != null &&
        !RegExp(r'^(?:[0-9*]{4,32}|IR[0-9]{24})$').hasMatch(account)) {
      return null;
    }
    final reference = fields['reference'];
    if (reference != null &&
        !RegExp(r'^[a-zA-Z0-9_-]{1,64}$').hasMatch(reference)) {
      return null;
    }
    for (final key in ['bank', 'merchant']) {
      final value = fields[key];
      if (value != null &&
          (value.length > (key == 'bank' ? 40 : 80) ||
              !RegExp(r'^[a-zA-Z\u0600-\u06ff\u200c ]+$').hasMatch(value))) {
        return null;
      }
    }
    final evidence = SmsCurrencyEvidence(
      sourceAmount: amount.$1,
      detectedUnit: amount.$2,
    );
    return ParsedSms(
      amount: Money(
        minorUnits: amount.$2?.canonicalIrr(amount.$1) ?? amount.$1,
        currency: 'IRR',
      ),
      currencyEvidence: evidence,
      balance: balance == null
          ? null
          : Money(
              minorUnits: balance.$2!.canonicalIrr(balance.$1),
              currency: 'IRR',
            ),
      occurredAt: date == null || time == null
          ? null
          : DateTime(
              date.year,
              date.month,
              date.day,
              time.$1,
              time.$2,
              time.$3,
            ),
      sourceDate: fields['date'],
      sourceTime: fields['time'],
      isTransfer: _transfers.contains(type),
      direction: direction,
      quality:
          direction == TransactionDirection.unknown ||
              evidence.requiresSelection ||
              date == null ||
              time == null
          ? ParseQuality.medium
          : ParseQuality.high,
      confidence: direction == TransactionDirection.unknown ? 55 : 80,
      merchant: fields['merchant'],
      reference: reference,
      accountHint: account,
      bank: fields['bank'],
    );
  }

  String _normalizeDigits(String text) =>
      text.replaceAllMapped(RegExp(r'[۰-۹٠-٩]'), (m) {
        final code = m.group(0)!.codeUnitAt(0);
        return String.fromCharCode(code - (code >= 0x6f0 ? 0x6f0 : 0x660) + 48);
      });

  (int, SmsMoneyUnit?)? _amount(String? text) {
    if (text == null) return null;
    final match = RegExp(
      r'^(?:(ریال|تومان|rials?|tomans?|irr)\s+)?([0-9]+|[0-9]{1,3}(?:[,،٬][0-9]{3})+)(?:\s+(ریال|تومان|rials?|tomans?|irr))?$',
      caseSensitive: false,
    ).firstMatch(text);
    if (match == null) return null;
    final value = BigInt.tryParse(
      match.group(2)!.replaceAll(RegExp(r'[,،٬]'), ''),
    );
    if (value == null || value > BigInt.from(9223372036854775807)) return null;
    SmsMoneyUnit? unit(String? label) => label == null
        ? null
        : RegExp(r'تومان|toman', caseSensitive: false).hasMatch(label)
        ? SmsMoneyUnit.toman
        : SmsMoneyUnit.rial;
    final prefix = unit(match.group(1));
    final suffix = unit(match.group(3));
    final detected = prefix != null && suffix != null && prefix != suffix
        ? null
        : prefix ?? suffix;
    // Both interpretations must be safe if conflicting/missing unit needs review.
    if ((detected == null || detected == SmsMoneyUnit.toman) &&
        value * BigInt.from(10) > BigInt.from(9223372036854775807)) {
      return null;
    }
    return (value.toInt(), detected);
  }

  DateTime? _date(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{4})([-/])(\d{2})\2(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(3)!);
    final day = int.parse(match.group(4)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    if (year >= 1300 && year <= 1499) {
      try {
        final jalali = Jalali(year, month, day);
        final gregorian = jalali.toGregorian();
        return DateTime(gregorian.year, gregorian.month, gregorian.day);
      } on DateException {
        return null;
      }
    }
    if (year < 2000 || year > 2099) return null;
    final date = DateTime(year, month, day);
    return date.year == year && date.month == month && date.day == day
        ? date
        : null;
  }

  (int, int, int)? _time(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{2}):(\d{2})(?::(\d{2}))?$').firstMatch(value);
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final second = int.parse(match.group(3) ?? '0');
    return hour < 24 && minute < 60 && second < 60
        ? (hour, minute, second)
        : null;
  }
}

class InboxUseCases {
  InboxUseCases(this.repository, {this.parser = const LocalSmsParser()});

  final InboxRepository repository;
  final LocalSmsParser parser;

  Future<List<InboxSuggestion>> listPendingSuggestions() =>
      CommandGate.runFor(repository, () async {
        await expireRawText();
        return (await repository.listSuggestions())
            .where(
              (item) =>
                  item.status == SuggestionStatus.pending ||
                  item.status == SuggestionStatus.edited,
            )
            .toList(growable: false);
      });

  Future<void> expireRawText({DateTime? now}) =>
      CommandGate.runFor(repository, () async {
        final at = (now ?? DateTime.now()).toUtc();
        for (final item in await repository.listImports()) {
          if (item.retentionStatus == RawTextRetentionStatus.expired) continue;
          final deadline = item.retentionUntil;
          if (deadline != null && !at.isBefore(deadline)) {
            await repository.saveImport(item.expireRawText());
          }
        }
      });

  Future<InboxSuggestion> stageSms({
    required String rawText,
    required String sourceKey,
    required String currency,
    String? sourceAddress,
    DateTime? importedAt,
  }) => CommandGate.runFor(repository, () async {
    final normalized = rawText.trim();
    final fingerprint = sha256.convert(utf8.encode(normalized)).toString();
    if (repository is! AtomicInboxStaging) {
      final existing = await repository.listImports();
      final sourceDuplicate = existing.where(
        (item) =>
            item.provenance.source == ImportSource.sms &&
            item.provenance.sourceKey == sourceKey,
      );
      if (sourceDuplicate.isNotEmpty) {
        if (sourceDuplicate.first.fingerprint != fingerprint) {
          throw const ValidationError(
            'Source key belongs to different content',
          );
        }
        final stagedId = sourceDuplicate.first.id;
        return (await repository.listSuggestions()).firstWhere(
          (item) => item.stagedImportId == stagedId,
        );
      }
      if (existing.any(
        (item) =>
            item.fingerprint == fingerprint &&
            !(item.provenance.source == ImportSource.sms &&
                item.provenance.sourceKey != sourceKey),
      )) {
        throw const DuplicateSmsImport();
      }
    }
    if (normalized.isEmpty ||
        normalized.length > 100000 ||
        sourceKey.trim().isEmpty) {
      throw const ValidationError(PersianCopy.inboxUseCasesStageSmsMessage);
    }
    final ParsedSms parsed;
    try {
      parsed = parser.parse(text: normalized, currency: currency);
    } on ValidationError {
      throw const UnsupportedSmsFormat();
    }
    final imported = (importedAt ?? DateTime.now()).toUtc();
    // Provider receipt time is the explicit fallback for undated bank messages,
    // not the time at which an old message happens to be imported.
    final sourceOccurredAt = parsed.occurredAt ?? imported;
    final occurredAt = DateTime.fromMillisecondsSinceEpoch(
      (sourceOccurredAt.millisecondsSinceEpoch ~/ 1000) * 1000,
      isUtc: true,
    );
    final retentionUntil = imported.add(const Duration(days: 30));
    final identity = '$fingerprint:sms:$sourceKey';
    final staged = StagedImport(
      id: _stableImportId(identity, importedAt),
      rawText: normalized,
      fingerprint: fingerprint,
      provenance: ImportProvenance(
        source: ImportSource.sms,
        sourceKey: sourceKey,
        importedAt: imported,
      ),
      retentionUntil: retentionUntil,
    );
    final draft = TransactionDraft(
      id: _stableImportId('$identity:draft', occurredAt),
      stagedImportId: staged.id,
      amount: parsed.amount,
      currencyEvidence: parsed.currencyEvidence,
      occurredAt: occurredAt,
      type: parsed.direction == TransactionDirection.incoming
          ? 'income'
          : parsed.direction == TransactionDirection.outgoing
          ? 'expense'
          : 'unknown',
      merchant: parsed.merchant,
      reference: parsed.reference,
      direction: parsed.direction,
      bank: parsed.bank,
      sourceAddress: sourceAddress,
      accountHint: parsed.accountHint,
      balance: parsed.balance,
      quality: parsed.quality,
      confidence: parsed.confidence,
      receivedAt: importedAt?.toUtc(),
      dateSource: parsed.occurredAt != null
          ? TransactionDateSource.extracted
          : importedAt != null
          ? TransactionDateSource.receipt
          : TransactionDateSource.unknown,
    );
    final suggestion = InboxSuggestion(
      id: _stableImportId('$identity:suggestion', importedAt),
      stagedImportId: staged.id,
      draft: draft,
      extractedEvidence: SmsExtractionEvidence(
        draft: draft,
        sourceDate: parsed.sourceDate,
        sourceTime: parsed.sourceTime,
        occurredAt: parsed.occurredAt,
        isTransfer: parsed.isTransfer,
      ),
    );
    if (repository case final AtomicInboxStaging atomic) {
      return atomic.stageAtomically(staged: staged, suggestion: suggestion);
    }
    await repository.saveImport(staged);
    await repository.saveSuggestion(suggestion);
    return suggestion;
  });

  Future<InboxSuggestion> edit(
    InboxSuggestion suggestion,
    TransactionDraft draft,
  ) => CommandGate.runFor(repository, () async {
    if (suggestion.status == SuggestionStatus.confirmed ||
        suggestion.status == SuggestionStatus.rejected) {
      throw const ValidationError('Resolved suggestions cannot be edited');
    }
    if (draft.stagedImportId != suggestion.stagedImportId ||
        draft.id != suggestion.draft.id) {
      throw const ValidationError('Draft does not belong to this import');
    }
    final stored = (await repository.listSuggestions()).firstWhere(
      (item) => item.id == suggestion.id,
    );
    if (stored.status == SuggestionStatus.confirmed ||
        stored.status == SuggestionStatus.rejected) {
      throw const ValidationError(PersianCopy.inboxUseCasesEditMessage);
    }
    if (stored.draft.currencyEvidence != null &&
        draft.currencyEvidence == null) {
      throw const ValidationError(PersianCopy.inboxUseCasesEditMessage2);
    }
    if (stored.revision != suggestion.revision) {
      throw const ValidationError(PersianCopy.inboxUseCasesEditMessage3);
    }
    final edited = stored.withDraft(draft);
    await repository.saveSuggestion(edited);
    return edited;
  });

  Future<void> reject(InboxSuggestion suggestion) => CommandGate.runFor(
    repository,
    () async {
      if (repository case final AtomicInboxReview atomic) {
        await atomic.reviewAtomically(suggestion, recover: false);
        return;
      }
      if (suggestion.status == SuggestionStatus.confirmed) {
        throw const ValidationError('Confirmed suggestions cannot be rejected');
      }
      await repository.saveSuggestion(
        suggestion.withStatus(SuggestionStatus.rejected),
      );
      final imports = await repository.listImports();
      final staged = imports.firstWhere(
        (item) => item.id == suggestion.stagedImportId,
      );
      await repository.saveImport(staged.withStatus(StagedItemStatus.rejected));
    },
  );

  Future<void> rollback(
    InboxSuggestion suggestion,
  ) => CommandGate.runFor(repository, () async {
    if (repository case final AtomicInboxReview atomic) {
      await atomic.reviewAtomically(suggestion, recover: true);
      return;
    }
    final storedSuggestion = (await repository.listSuggestions()).firstWhere(
      (item) => item.id == suggestion.id,
      orElse: () => suggestion,
    );
    if (storedSuggestion.status != SuggestionStatus.rejected) {
      throw const ValidationError('Only rejected imports can be rolled back');
    }
    final imports = await repository.listImports();
    final staged = imports.firstWhere(
      (item) => item.id == storedSuggestion.stagedImportId,
    );
    await repository.saveSuggestion(
      storedSuggestion.withStatus(SuggestionStatus.pending),
    );
    await repository.saveImport(staged.withStatus(StagedItemStatus.rolledBack));
  });

  Future<AccountEntry> confirm({
    required InboxSuggestion suggestion,
    required FinancialAccount account,
    required FinanceRepository finance,
    SmsMoneyUnit? selectedUnit,
  }) => CommandGate.runFor(repository, () async {
    if (suggestion.status == SuggestionStatus.rejected ||
        suggestion.status == SuggestionStatus.confirmed) {
      throw const ValidationError('Resolved suggestions cannot be confirmed');
    }
    final draft = selectedUnit == null
        ? suggestion.draft
        : suggestion.draft.selectUnresolvedCurrency(selectedUnit);
    draft.validateConfirmation(extractedEvidence: suggestion.extractedEvidence);
    if (account.status != FinancialAccountStatus.active) {
      throw const ValidationError('Archived accounts cannot receive imports');
    }
    if (account.currency != draft.amount.currency) {
      throw const ValidationError(
        'Suggestion and account currencies must match',
      );
    }
    final entry = AccountEntry(
      id: _stableImportId(
        '${suggestion.stagedImportId.value}:financial-entry',
        draft.occurredAt,
      ),
      accountId: account.id,
      type: draft.type == 'income'
          ? AccountEntryType.income
          : AccountEntryType.expense,
      amount: draft.amount,
      occurredAt: draft.occurredAt.toUtc(),
      referenceId: draft.reference,
      note: draft.merchant,
    );
    if (repository case final AtomicInboxConfirmation atomic) {
      return atomic.confirmAtomically(
        suggestionId: suggestion.id,
        entry: entry,
        expectedRevision: suggestion.revision,
        selectedUnit: selectedUnit,
      );
    }
    final stored = (await repository.listSuggestions()).firstWhere(
      (item) => item.id == suggestion.id,
    );
    if (stored.status == SuggestionStatus.confirmed) {
      return (await finance.listEntries()).firstWhere(
        (item) => item.id == entry.id,
      );
    }
    if (stored.revision != suggestion.revision ||
        stored.status == SuggestionStatus.rejected) {
      throw const ValidationError(PersianCopy.inboxUseCasesEditMessage3);
    }
    final reviewed = selectedUnit == null
        ? stored.draft
        : stored.draft.selectUnresolvedCurrency(selectedUnit);
    reviewed.validateConfirmation(extractedEvidence: stored.extractedEvidence);
    await finance.saveEntry(entry);
    await repository.saveSuggestion(
      InboxSuggestion(
        id: stored.id,
        stagedImportId: stored.stagedImportId,
        draft: reviewed,
        status: SuggestionStatus.confirmed,
        revision: stored.revision + 1,
        extractedEvidence: stored.extractedEvidence,
      ),
    );
    final staged = (await repository.listImports()).firstWhere(
      (item) => item.id == suggestion.stagedImportId,
    );
    await repository.saveImport(staged.withStatus(StagedItemStatus.confirmed));
    return entry;
  });

  StableId _stableImportId(String input, DateTime? timestamp) {
    final digest = sha256.convert(utf8.encode(input)).bytes;
    final millis = (timestamp ?? DateTime.now()).toUtc().millisecondsSinceEpoch;
    final hex =
        millis.toRadixString(16).padLeft(12, '0').substring(0, 12) +
        digest
            .take(10)
            .map((value) => value.toRadixString(16).padLeft(2, '0'))
            .join();
    final value =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-7${hex.substring(12, 15)}-8${hex.substring(15, 18)}-${hex.substring(18, 30)}';
    return StableId.parse(value);
  }
}
