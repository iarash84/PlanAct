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
    this.merchant,
    this.reference,
  });

  final Money amount;
  final DateTime occurredAt;
  final String? merchant;
  final String? reference;
}

class LocalSmsParser {
  const LocalSmsParser();

  ParsedSms parse({required String text, required String currency}) {
    final amountMatch = RegExp(
      r'(?:مبلغ|amount)\s*[:：]?\s*([0-9۰-۹,]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (amountMatch == null) {
      throw const ValidationError('SMS amount could not be parsed');
    }
    final amount = _digits(amountMatch.group(1)!);
    final dateMatch = RegExp(r'(20\d{2})[-/]([01]?\d)[-/]([0-3]?\d)')
        .firstMatch(text);
    final occurredAt = dateMatch == null
        ? DateTime.now().toUtc()
        : DateTime.utc(
            int.parse(dateMatch.group(1)!),
            int.parse(dateMatch.group(2)!),
            int.parse(dateMatch.group(3)!),
          );
    final reference = RegExp(
      r'(?:پیگیری|ref|reference)\s*[:#]?\s*([\w-]+)',
      caseSensitive: false,
    ).firstMatch(text)?.group(1);
    return ParsedSms(
      amount: Money(minorUnits: amount, currency: currency),
      occurredAt: occurredAt,
      merchant: _merchant(text),
      reference: reference,
    );
  }

  int _digits(String value) => int.parse(
    value
        .replaceAll(',', '')
        .replaceAll('۰', '0')
        .replaceAll('۱', '1')
        .replaceAll('۲', '2')
        .replaceAll('۳', '3')
        .replaceAll('۴', '4')
        .replaceAll('۵', '5')
        .replaceAll('۶', '6')
        .replaceAll('۷', '7')
        .replaceAll('۸', '8')
        .replaceAll('۹', '9'),
  );

  String? _merchant(String text) {
    final match = RegExp(
      r'(?:فروشگاه|merchant)\s*[:：]\s*([^\n]+)',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1)?.trim();
  }
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
    final fingerprint = sha256.convert(utf8.encode(rawText.trim())).toString();
    final existing = await repository.listImports();
    final duplicate = existing.where((item) => item.fingerprint == fingerprint);
    if (duplicate.isNotEmpty) {
      throw const ValidationError('This source item was already imported');
    }
    final parsed = parser.parse(text: rawText, currency: currency);
    final staged = StagedImport(
      id: StableId.generate(timestamp: importedAt),
      rawText: rawText,
      fingerprint: fingerprint,
      provenance: ImportProvenance(
        source: ImportSource.sms,
        sourceKey: sourceKey,
        importedAt: (importedAt ?? DateTime.now()).toUtc(),
      ),
    );
    final draft = TransactionDraft(
      id: StableId.generate(timestamp: parsed.occurredAt),
      stagedImportId: staged.id,
      amount: parsed.amount,
      occurredAt: parsed.occurredAt,
      type: 'expense',
      merchant: parsed.merchant,
      reference: parsed.reference,
    );
    final suggestion = InboxSuggestion(
      id: StableId.generate(timestamp: importedAt),
      stagedImportId: staged.id,
      draft: draft,
    );
    await repository.saveImport(staged);
    await repository.saveSuggestion(suggestion);
    return suggestion;
  }

  Future<void> reject(InboxSuggestion suggestion) async {
    await repository.saveSuggestion(
      suggestion.withStatus(SuggestionStatus.rejected),
    );
    final imports = await repository.listImports();
    final staged = imports.firstWhere(
      (item) => item.id == suggestion.stagedImportId,
    );
    await repository.saveImport(staged.withStatus(StagedItemStatus.rejected));
  }

  Future<AccountEntry> confirm({
    required InboxSuggestion suggestion,
    required FinancialAccount account,
    required FinanceRepository finance,
  }) async {
    if (suggestion.status == SuggestionStatus.rejected) {
      throw const ValidationError('Rejected suggestions cannot be confirmed');
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
      type: AccountEntryType.expense,
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
}
