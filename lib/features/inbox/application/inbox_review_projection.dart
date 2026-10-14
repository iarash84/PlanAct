import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

/// The action and explanation shown for one pending imported item.
enum InboxReviewAction { confirm, edit, reject }

class InboxReviewItem {
  const InboxReviewItem({
    required this.suggestion,
    required this.import,
    required this.proposedAction,
    required this.reasons,
    required this.warnings,
    required this.supportedActions,
    this.account,
  });

  final InboxSuggestion suggestion;
  final StagedImport import;
  final InboxReviewAction proposedAction;
  final List<String> reasons;
  final List<String> warnings;
  final List<InboxReviewAction> supportedActions;
  final FinancialAccount? account;

  String? get sourceLabel => switch (import.provenance.source) {
    ImportSource.sms => PersianCopy.inboxReviewProjectionImportSourceSms,
    ImportSource.file => PersianCopy.inboxReviewProjectionImportSourceFile,
    ImportSource.manual => PersianCopy.inboxReviewProjectionImportSourceManual,
  };
}

/// Builds a review projection without putting classification or reconciliation
/// rules in widgets. It only uses evidence already persisted in the domain.
class InboxReviewProjection {
  const InboxReviewProjection();

  List<InboxReviewItem> build({
    required Iterable<InboxSuggestion> suggestions,
    required Iterable<StagedImport> imports,
    required Iterable<FinancialAccount> accounts,
    required Iterable<AccountEntry> entries,
    SuggestionStatus? status,
    String? bank,
    bool oldestFirst = false,
  }) {
    final importsById = {for (final item in imports) item.id: item};
    final accountsById = {for (final item in accounts) item.id: item};
    final pending = suggestions.where(
      (item) =>
          (status == null
              ? item.status == SuggestionStatus.pending ||
                    item.status == SuggestionStatus.edited
              : item.status == status) &&
          (bank == null || (item.draft.bank ?? '') == bank),
    );

    final result = [
      for (final suggestion in pending)
        if (importsById[suggestion.stagedImportId] case final import?)
          _item(
            suggestion: suggestion,
            import: import,
            accountsById: accountsById,
            entries: entries,
          ),
    ];
    result.sort((a, b) {
      final date = a.import.provenance.importedAt.compareTo(
        b.import.provenance.importedAt,
      );
      final comparison = date == 0
          ? a.suggestion.id.value.compareTo(b.suggestion.id.value)
          : date;
      return oldestFirst ? comparison : -comparison;
    });
    return result;
  }

  InboxReviewItem _item({
    required InboxSuggestion suggestion,
    required StagedImport import,
    required Map<StableId, FinancialAccount> accountsById,
    required Iterable<AccountEntry> entries,
  }) {
    final draft = suggestion.draft;
    final matchingAccounts = accountsById.values.where(
      (account) =>
          account.status == FinancialAccountStatus.active &&
          account.currency == draft.amount.currency,
    );
    final account = matchingAccounts.length == 1
        ? matchingAccounts.single
        : null;
    final reasons = <String>[];
    final warnings = <String>[];

    if (draft.quality == ParseQuality.high) {
      reasons.add(PersianCopy.inboxReviewProjectionItemMessage);
    } else if (draft.quality == ParseQuality.medium) {
      reasons.add(PersianCopy.inboxReviewProjectionItemMessage2);
    } else {
      reasons.add(PersianCopy.inboxReviewProjectionItemMessage3);
    }
    if (draft.merchant case final merchant? when merchant.trim().isNotEmpty) {
      reasons.add(PersianCopy.inboxReviewProjectionItemMessage4);
    }
    if (account != null) {
      reasons.add(PersianCopy.inboxReviewProjectionItemMessage5);
    } else if (matchingAccounts.isEmpty) {
      warnings.add(PersianCopy.inboxReviewProjectionItemMessage6);
    } else {
      warnings.add(PersianCopy.inboxReviewProjectionItemMessage7);
    }

    final sameAmount = entries.where(
      (entry) =>
          entry.amount.currency == draft.amount.currency &&
          entry.amount.minorUnits == draft.amount.minorUnits &&
          entry.type == _entryType(draft.direction),
    );
    if (sameAmount.isNotEmpty) {
      warnings.add(PersianCopy.inboxReviewProjectionItemMessage8);
      reasons.add(PersianCopy.inboxReviewProjectionItemMessage9);
    }
    if (draft.reference case final reference?
        when reference.trim().isNotEmpty) {
      final sameReference = entries.where(
        (entry) => entry.referenceId == reference,
      );
      if (sameReference.isNotEmpty) {
        warnings.add(PersianCopy.inboxReviewProjectionItemMessage10);
        reasons.add(PersianCopy.inboxReviewProjectionItemMessage11);
      }
    }

    return InboxReviewItem(
      suggestion: suggestion,
      import: import,
      proposedAction: InboxReviewAction.confirm,
      reasons: List.unmodifiable(reasons),
      warnings: List.unmodifiable(warnings),
      supportedActions: const [
        InboxReviewAction.confirm,
        InboxReviewAction.edit,
        InboxReviewAction.reject,
      ],
      account: account,
    );
  }

  AccountEntryType _entryType(TransactionDirection direction) =>
      direction == TransactionDirection.incoming
      ? AccountEntryType.income
      : AccountEntryType.expense;
}
