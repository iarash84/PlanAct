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
    ImportSource.sms => 'پیامک بانکی',
    ImportSource.file => 'فایل واردشده',
    ImportSource.manual => 'ورود دستی',
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
  }) {
    final importsById = {for (final item in imports) item.id: item};
    final accountsById = {for (final item in accounts) item.id: item};
    final pending = suggestions.where(
      (item) =>
          item.status == SuggestionStatus.pending ||
          item.status == SuggestionStatus.edited,
    );

    return [
      for (final suggestion in pending)
        if (importsById[suggestion.stagedImportId] case final import?)
          _item(
            suggestion: suggestion,
            import: import,
            accountsById: accountsById,
            entries: entries,
          ),
    ];
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
      reasons.add('مبلغ و جهت تراکنش از متن پیامک بانکی تشخیص داده شد');
    } else if (draft.quality == ParseQuality.medium) {
      reasons.add('مبلغ از متن پیامک تشخیص داده شد؛ جهت تراکنش قطعی نیست');
    } else {
      reasons.add('اطلاعات واردشده نیاز به بررسی دستی دارد');
    }
    if (draft.merchant case final merchant? when merchant.trim().isNotEmpty) {
      reasons.add('نام پذیرنده از متن پیامک استخراج شد');
    }
    if (account != null) {
      reasons.add('تنها حساب فعال سازگار با واحد پول پیدا شد');
    } else if (matchingAccounts.isEmpty) {
      warnings.add('حساب فعال سازگار برای ثبت پیدا نشد');
    } else {
      warnings.add('چند حساب سازگار وجود دارد؛ حساب باید انتخاب شود');
    }

    final sameAmount = entries.where(
      (entry) =>
          entry.amount.currency == draft.amount.currency &&
          entry.amount.minorUnits == draft.amount.minorUnits &&
          entry.type == _entryType(draft.direction),
    );
    if (sameAmount.isNotEmpty) {
      warnings.add('تراکنش دیگری با همین مبلغ و نوع قبلاً ثبت شده است');
      reasons.add('هشدار تکراری بودن بر اساس مبلغ و نوع تراکنش');
    }
    if (draft.reference case final reference?
        when reference.trim().isNotEmpty) {
      final sameReference = entries.where(
        (entry) => entry.referenceId == reference,
      );
      if (sameReference.isNotEmpty) {
        warnings.add('شناسه پیگیری قبلاً در دفترکل دیده شده است');
        reasons.add('هشدار تکراری بودن بر اساس شناسه پیگیری');
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
