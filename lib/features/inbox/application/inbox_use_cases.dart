import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

abstract interface class InboxRepository {
  Future<List<StagedImport>> listImports();
  Future<List<InboxSuggestion>> listSuggestions();
  Future<void> saveImport(StagedImport item);
  Future<void> saveSuggestion(InboxSuggestion suggestion);
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
    this.accountHint,
    this.balance,
  });

  final Money amount;
  final DateTime occurredAt;
  final TransactionDirection direction;
  final ParseQuality quality;
  final int confidence;
  final String? merchant;
  final String? reference;
  final String? bank;
  final String? accountHint;
  final Money? balance;
}

abstract interface class SmsFormatParser {
  ParsedSms? tryParse({required String text, required String currency});
}

class LocalSmsParser implements SmsFormatParser {
  const LocalSmsParser({this.parsers = const [GenericBankSmsParser()]});

  final List<SmsFormatParser> parsers;

  ParsedSms parse({required String text, required String currency}) {
    for (final parser in parsers) {
      final result = parser.tryParse(text: text, currency: currency);
      if (result != null) return result;
    }
    throw const ValidationError('SMS amount could not be parsed');
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

/// Explainable fallback for common Persian/English bank notification labels.
/// Bank-specific parsers can be added without changing staging or UI.
class GenericBankSmsParser implements SmsFormatParser {
  const GenericBankSmsParser();

  @override
  ParsedSms? tryParse({required String text, required String currency}) {
    final amountMatch = RegExp(
      r'(?:مبلغ|amount|برداشت|واریز|purchase|withdrawal|deposit)\s*[:：]?\s*([۰-۹0-9][۰-۹0-9,،]*)',
      caseSensitive: false,
    ).firstMatch(text);
    if (amountMatch == null) return null;
    final amount = _digits(amountMatch.group(1)!);
    if (amount <= 0) return null;
    final dateMatch = RegExp(r'(20\d{2})[-/]([01]?\d)[-/]([0-3]?\d)')
        .firstMatch(text);
    final occurredAt = dateMatch == null
        ? DateTime.now().toUtc()
        : DateTime.utc(
            int.parse(dateMatch.group(1)!),
            int.parse(dateMatch.group(2)!),
            int.parse(dateMatch.group(3)!),
          );
    final lower = text.toLowerCase();
    final incoming = RegExp(r'واریز|وصول|deposit|credit|received')
        .hasMatch(lower);
    final outgoing = RegExp(r'برداشت|خرید|پرداخت|withdrawal|purchase|debit')
        .hasMatch(lower);
    final direction = incoming && !outgoing
        ? TransactionDirection.incoming
        : outgoing && !incoming
        ? TransactionDirection.outgoing
        : TransactionDirection.unknown;
    final reference = RegExp(
      r'(?:پیگیری|ref|reference|شناسه)\s*[:#]?\s*([\w-]+)',
      caseSensitive: false,
    ).firstMatch(text)?.group(1);
    final card = RegExp(
      r'(?:کارت|card)\s*[:：#]?\s*([0-9۰-۹* -]{4,})',
      caseSensitive: false,
    ).firstMatch(text)?.group(1)?.trim();
    return ParsedSms(
      amount: Money(minorUnits: amount, currency: currency),
      occurredAt: occurredAt,
      direction: direction,
      quality: direction == TransactionDirection.unknown
          ? ParseQuality.medium
          : ParseQuality.high,
      confidence: direction == TransactionDirection.unknown ? 55 : 80,
      merchant: _merchant(text),
      reference: reference,
      accountHint: card,
      bank: _bank(text),
    );
  }

  int _digits(String value) => int.parse(
    value
        .replaceAll(RegExp(r'[,،]'), '')
        .replaceAllMapped(
          RegExp(r'[۰-۹]'),
          (m) => String.fromCharCode(m.group(0)!.codeUnitAt(0) - 1728),
        ),
  );
  String? _merchant(String text) => RegExp(
    r'(?:فروشگاه|merchant|پذیرنده)\s*[:：]\s*([^\n]+)',
    caseSensitive: false,
  ).firstMatch(text)?.group(1)?.trim();
  String? _bank(String text) => RegExp(
    r'(?:بانک|bank)\s*[:：]?\s*([^\n]+)',
    caseSensitive: false,
  ).firstMatch(text)?.group(1)?.trim();
}

class InboxUseCases {
  InboxUseCases(this.repository, {this.parser = const LocalSmsParser()});

  final InboxRepository repository;
  final LocalSmsParser parser;

  Future<InboxSuggestion> stageSms({
    required String rawText,
    required String sourceKey,
    required String currency,
    DateTime? importedAt,
  }) async {
    final normalized = rawText.trim();
    final fingerprint = sha256.convert(utf8.encode(normalized)).toString();
    final existing = await repository.listImports();
    final sourceDuplicate = existing.where(
      (item) => item.provenance.sourceKey == sourceKey,
    );
    if (sourceDuplicate.isNotEmpty) {
      final stagedId = sourceDuplicate.first.id;
      return (await repository.listSuggestions()).firstWhere(
        (item) => item.stagedImportId == stagedId,
      );
    }
    final fingerprintDuplicate = existing.where(
      (item) => item.fingerprint == fingerprint,
    );
    if (fingerprintDuplicate.isNotEmpty) {
      throw const ValidationError('This source item was already imported');
    }
    final parsed = parser.parse(text: normalized, currency: currency);
    final staged = StagedImport(
      id: _stableImportId(fingerprint, importedAt),
      rawText: normalized,
      fingerprint: fingerprint,
      provenance: ImportProvenance(
        source: ImportSource.sms,
        sourceKey: sourceKey,
        importedAt: (importedAt ?? DateTime.now()).toUtc(),
      ),
    );
    final draft = TransactionDraft(
      id: _stableImportId('$fingerprint:draft', parsed.occurredAt),
      stagedImportId: staged.id,
      amount: parsed.amount,
      occurredAt: parsed.occurredAt,
      type: parsed.direction == TransactionDirection.incoming
          ? 'income'
          : 'expense',
      merchant: parsed.merchant,
      reference: parsed.reference,
      direction: parsed.direction,
      bank: parsed.bank,
      accountHint: parsed.accountHint,
      balance: parsed.balance,
      quality: parsed.quality,
      confidence: parsed.confidence,
    );
    final suggestion = InboxSuggestion(
      id: _stableImportId('$fingerprint:suggestion', importedAt),
      stagedImportId: staged.id,
      draft: draft,
    );
    await repository.saveImport(staged);
    await repository.saveSuggestion(suggestion);
    return suggestion;
  }

  Future<InboxSuggestion> edit(
    InboxSuggestion suggestion,
    TransactionDraft draft,
  ) async {
    if (suggestion.status == SuggestionStatus.confirmed ||
        suggestion.status == SuggestionStatus.rejected) {
      throw const ValidationError('Resolved suggestions cannot be edited');
    }
    if (draft.stagedImportId != suggestion.stagedImportId) {
      throw const ValidationError('Draft does not belong to this import');
    }
    final edited = suggestion.withDraft(draft);
    await repository.saveSuggestion(edited);
    return edited;
  }

  Future<void> reject(InboxSuggestion suggestion) async {
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
  }

  Future<void> rollback(InboxSuggestion suggestion) async {
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
    await repository.saveImport(staged.withStatus(StagedItemStatus.rolledBack));
  }

  Future<AccountEntry> confirm({
    required InboxSuggestion suggestion,
    required FinancialAccount account,
    required FinanceRepository finance,
  }) async {
    if (suggestion.status == SuggestionStatus.rejected ||
        suggestion.status == SuggestionStatus.confirmed) {
      throw const ValidationError('Resolved suggestions cannot be confirmed');
    }
    if (account.status != FinancialAccountStatus.active) {
      throw const ValidationError('Archived accounts cannot receive imports');
    }
    if (account.currency != suggestion.draft.amount.currency) {
      throw const ValidationError(
        'Suggestion and account currencies must match',
      );
    }
    final entry = AccountEntry(
      id: StableId.generate(timestamp: suggestion.draft.occurredAt),
      accountId: account.id,
      type: suggestion.draft.direction == TransactionDirection.incoming
          ? AccountEntryType.income
          : AccountEntryType.expense,
      amount: suggestion.draft.amount,
      occurredAt: suggestion.draft.occurredAt.toUtc(),
      referenceId: suggestion.draft.reference,
      note: suggestion.draft.merchant,
    );
    await finance.saveEntry(entry);
    await repository.saveSuggestion(
      suggestion.withStatus(SuggestionStatus.confirmed),
    );
    final staged = (await repository.listImports()).firstWhere(
      (item) => item.id == suggestion.stagedImportId,
    );
    await repository.saveImport(staged.withStatus(StagedItemStatus.confirmed));
    return entry;
  }

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
