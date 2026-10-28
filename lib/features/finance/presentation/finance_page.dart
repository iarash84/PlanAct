import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/undo_feedback.dart';
import 'package:planact/core/application/undo_token.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:planact/features/finance/presentation/account_form_sheet.dart';
import 'package:planact/features/finance/presentation/account_information_card.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/features/finance/presentation/financial_account_picker.dart';
import 'package:planact/features/finance/presentation/transaction_direction.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/domain/tag.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/logging/app_logger.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/money/currency.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/finance_reports.dart';

/// Keep the calling draft mounted while using the existing Finance account form.
Future<void> openFinancialAccountCreation(
  BuildContext context,
  FinanceRepository repository,
) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => _AccountCreationRoute(repository: repository),
    ),
  );
}

class _AccountCreationRoute extends StatefulWidget {
  const _AccountCreationRoute({required this.repository});
  final FinanceRepository repository;
  @override
  State<_AccountCreationRoute> createState() => _AccountCreationRouteState();
}

class _AccountCreationRouteState extends State<_AccountCreationRoute> {
  final _key = GlobalKey<FinancePageState>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _key.currentState?.openAccountForm();
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(planActL10n(context).financePageBuildTitle)),
    body: FinancePage(key: _key, repository: widget.repository, embedded: true),
  );
}

enum FinanceRecordKind { account, entry }

class FinancePage extends StatefulWidget {
  const FinancePage({
    super.key,
    required this.repository,
    this.expectationRepository,
    this.tagRepository,
    this.onTagsChanged,
    this.onDataChanged,
    this.onDetermineRelationship,
    this.embedded = false,
    this.bottomContentPadding = 0,
    this.showArchivedAccounts = false,
    this.focusedRecordId,
    this.focusedKind = FinanceRecordKind.entry,
  });

  final Future<void> Function(StableId transactionId)? onDetermineRelationship;
  final TagRepository? tagRepository;
  final Future<void> Function()? onTagsChanged;
  final Future<void> Function()? onDataChanged;
  final FinanceRepository repository;
  final bool embedded;
  final double bottomContentPadding;
  final bool showArchivedAccounts;

  /// Search opens the existing controls for exactly one durable record.
  final String? focusedRecordId;
  final FinanceRecordKind focusedKind;
  final FinancialExpectationRepository? expectationRepository;

  @override
  State<FinancePage> createState() => FinancePageState();
}

class FinancePageState extends State<FinancePage> {
  Future<void> openTransactionForm({
    required bool income,
    Set<String> initialTags = const {},
  }) => _recordTransaction(income: income, initialTags: initialTags);

  Future<void> openAccountForm() => _addAccount();
  Future<void> refreshData() => _refresh();

  static const _logger = AppLogger();
  late final FinanceUseCases _finance = FinanceUseCases(widget.repository);
  List<FinancialAccount> _accounts = const [];
  List<AccountEntry> _entries = const [];
  bool _loading = true;
  String? _loadError;
  bool _hasLoaded = false;
  List<Tag> _tags = [];
  Map<String, Set<StableId>> _entryTags = {};
  StableId? _tagFilter;
  Set<String>? _tagMatches;
  bool _filterBusy = false;
  String? _categoryFilter;
  AccountEntryType? _typeFilter;
  final Set<StableId> _pendingEntries = {};
  final Set<StableId> _pendingAccounts = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (mounted && !_hasLoaded) setState(() => _loading = true);
    try {
      final accounts = await widget.repository.listAccounts();
      final entries = await widget.repository.listEntries();
      final tags = await widget.tagRepository?.list() ?? <Tag>[];
      final memberships = <String, Set<StableId>>{};
      if (widget.tagRepository case final TagRepository repository) {
        // Keep the full ledger for balance/reversal rules; only memberships
        // depend on which records this route actually presents.
        final entriesWithTags = widget.focusedRecordId == null
            ? entries
            : widget.focusedKind == FinanceRecordKind.entry
            ? entries.where((entry) => entry.id.value == widget.focusedRecordId)
            : const <AccountEntry>[];
        for (final entry in entriesWithTags) {
          memberships[entry.id.value] = await repository.tagsFor(
            entry.id.value,
            TaggableType.accountEntry,
          );
        }
      }
      final selected = tags.any((tag) => tag.id == _tagFilter)
          ? _tagFilter
          : null;
      final matches = selected == null
          ? null
          : await widget.tagRepository!.recordsWithTag(
              selected,
              TaggableType.accountEntry,
            );
      if (mounted) {
        setState(() {
          _tags = tags;
          _entryTags = memberships;
          _tagFilter = selected;
          _tagMatches = matches;
          _accounts = accounts;
          _entries = entries;
          _hasLoaded = true;
          _loadError = null;
          _loading = false;
        });
      }
    } catch (error) {
      _logger.error(
        'Finance refresh failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = PersianCopy.financePageRefreshMessage;
        });
      }
    }
  }

  Future<void> _filterTag(StableId? id) async {
    if (_filterBusy) return;
    setState(() => _filterBusy = true);
    try {
      final matches = id == null
          ? null
          : await widget.tagRepository!.recordsWithTag(
              id,
              TaggableType.accountEntry,
            );
      if (mounted) {
        setState(() {
          _tagFilter = id;
          _tagMatches = matches;
        });
      }
    } catch (_) {
      if (mounted) _showMessage(PersianCopy.financePageFilterTagMessage);
    } finally {
      if (mounted) setState(() => _filterBusy = false);
    }
  }

  Future<void> _tagsChanged() async {
    await widget.onTagsChanged?.call();
    await _refresh();
    if (_loadError != null) throw StateError('Tag refresh failed');
  }

  Future<void> _editEntryTags(AccountEntry entry) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SingleChildScrollView(
      padding: EdgeInsetsDirectional.only(
        start: PlanActSpacing.page,
        end: PlanActSpacing.page,
        top: PlanActSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + PlanActSpacing.lg,
      ),
      child: RecordTagEditor(
        repository: widget.tagRepository!,
        recordId: entry.id.value,
        type: TaggableType.accountEntry,
        onChanged: _tagsChanged,
      ),
    ),
  );

  Future<void> _editAccount(FinancialAccount account) =>
      _accountForm(account: account);

  Future<void> _addAccount() => _accountForm();

  Future<void> _accountForm({FinancialAccount? account}) async {
    final saved = await showAccountForm(context, _finance, account: account);
    if (saved != true || !mounted) return;
    _showMessage(
      account == null
          ? PersianCopy.financePageAccountFormMessage
          : PersianCopy.financePageAccountFormMessage2,
    );
    await _refresh();
    try {
      await widget.onDataChanged?.call();
    } catch (_) {
      if (mounted) {
        _showMessage(PersianCopy.financePageAccountFormMessage3);
      }
    }
  }

  Future<void> _addIncome() => _recordTransaction(income: true);

  Future<void> _recordTransaction({
    required bool income,
    Set<String> initialTags = const {},
    AccountEntry? original,
  }) async {
    var draftTags = {...initialTags};
    final moneyInput = PinnedMoneyInput(MoneyUnitScope.of(context));
    final amount = TextEditingController(
      text: original == null
          ? ''
          : moneyInput.inputText(
              original.amount.minorUnits,
              currency: original.amount.currency,
            ),
    );
    final note = TextEditingController(text: original?.note);
    FinancialAccount? account = original == null
        ? null
        : _accounts.where((a) => a.id == original.accountId).firstOrNull;
    var occurredAt = original?.occurredAt.toLocal() ?? DateTime.now();
    String? formError;
    var saving = false;
    Future<void>? sheetRemoved;
    try {
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: false,
        builder: (context) {
          sheetRemoved ??= ModalRoute.of(context)!.completed.then((_) {});
          return StatefulBuilder(
            builder: (context, setDialogState) => PopScope(
              canPop: !saving,
              child: PlanActFormSheet(
                title: original != null
                    ? planActL10n(context).financeCorrectAction
                    : income
                    ? PersianCopy.financePageResultTitle
                    : PersianCopy.financePageResultTitle2,
                primaryLabel: PersianCopy.financePageResultPrimaryLabel,
                isLoading: saving,
                onPrimary: () async {
                  if (saving) return;
                  final selectedAccount = account;
                  if (selectedAccount == null) {
                    setDialogState(
                      () => formError = PersianCopy.financePageResultOnPrimary,
                    );
                    return;
                  }
                  final value = moneyInput.parse(
                    amount.text,
                    currency: account?.currency ?? CurrencyCodes.irr,
                  );
                  if (value == null || value <= 0) {
                    setDialogState(
                      () => formError = PersianCopy.financePageResultOnPrimary2,
                    );
                    return;
                  }
                  setDialogState(() {
                    saving = true;
                    formError = null;
                  });
                  try {
                    if (original != null) {
                      if (!await confirmRecordedAction(
                            context,
                            planActL10n(context).financeCorrectMessage,
                          ) ||
                          !context.mounted) {
                        if (context.mounted) {
                          setDialogState(() => saving = false);
                        }
                        return;
                      }
                      await _finance.correctEntry(
                        original: original,
                        account: selectedAccount,
                        type: income
                            ? AccountEntryType.income
                            : AccountEntryType.expense,
                        amount: Money(
                          minorUnits: value,
                          currency: selectedAccount.currency,
                        ),
                        occurredAt: occurredAt,
                        note: note.text.trim().isEmpty
                            ? null
                            : note.text.trim(),
                        category: original.category,
                      );
                    } else {
                      await _finance.record(
                        account: selectedAccount,
                        type: income
                            ? AccountEntryType.income
                            : AccountEntryType.expense,
                        amount: Money(
                          minorUnits: value,
                          currency: selectedAccount.currency,
                        ),
                        occurredAt: occurredAt,
                        note: note.text.trim().isEmpty
                            ? null
                            : note.text.trim(),
                        category: income
                            ? PersianCopy.financePageResultCategory
                            : PersianCopy.commonGeneral,
                        tags: draftTags,
                      );
                    }
                    if (context.mounted) {
                      setDialogState(() => saving = false);
                      Navigator.pop(context, true);
                    }
                  } catch (error) {
                    _logger.error(
                      'Finance transaction creation failed',
                      fields: {'errorType': error.runtimeType.toString()},
                    );
                    if (context.mounted) {
                      setDialogState(() {
                        saving = false;
                        formError = PersianCopy.financePageResultOnPrimary3;
                      });
                    }
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (original == null)
                      FinancialAccountPicker(
                        repository: widget.repository,
                        enabled: !saving && original == null,
                        onChanged: (value) =>
                            setDialogState(() => account = value),
                        onCreateAccount: () => openFinancialAccountCreation(
                          context,
                          widget.repository,
                        ),
                      )
                    else
                      Text(
                        account?.name ??
                            planActL10n(context)
                                .transactionRelationshipPageBuildChildren2,
                      ),
                    TextField(
                      controller: amount,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: const [
                        MoneyInputFormatter(decimal: true),
                      ],
                      decoration: InputDecoration(
                        labelText: PersianCopy.financePageResultLabelText(
                          (moneyInput.label(
                            account?.currency ?? CurrencyCodes.irr,
                          )).toString(),
                        ),
                      ),
                    ),
                    const SizedBox(height: PlanActSpacing.sm),
                    TextField(
                      controller: note,
                      decoration: InputDecoration(
                        labelText: income
                            ? PersianCopy.financePageResultLabelText2
                            : PersianCopy.financePageResultLabelText3,
                      ),
                    ),
                    if (original == null) ...[
                      const SizedBox(height: PlanActSpacing.sm),
                      DraftTagPicker(
                        repository: widget.tagRepository,
                        selected: draftTags,
                        enabled: !saving,
                        onChanged: (tags) =>
                            setDialogState(() => draftTags = tags),
                      ),
                    ],
                    const SizedBox(height: PlanActSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final selected = await showDialog<DateTime>(
                                context: context,
                                builder: (_) => PlanActJalaliDatePicker(
                                  initialDate: occurredAt,
                                ),
                              );
                              if (selected == null) return;
                              setDialogState(() {
                                occurredAt = DateTime(
                                  selected.year,
                                  selected.month,
                                  selected.day,
                                  occurredAt.hour,
                                  occurredAt.minute,
                                );
                              });
                            },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text(
                              PersianDateFormatter.date(
                                JalaliDate.fromDateTime(occurredAt),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final selected = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(occurredAt),
                              );
                              if (selected == null) return;
                              setDialogState(() {
                                occurredAt = DateTime(
                                  occurredAt.year,
                                  occurredAt.month,
                                  occurredAt.day,
                                  selected.hour,
                                  selected.minute,
                                );
                              });
                            },
                            icon: const Icon(Icons.schedule_outlined),
                            label: Text(
                              PersianNumbers.format(
                                '${occurredAt.hour.toString().padLeft(2, '0')}:${occurredAt.minute.toString().padLeft(2, '0')}',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (formError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            formError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      if (result == true) {
        try {
          await _refresh();
          await widget.onDataChanged?.call();
        } catch (_) {
          if (mounted) _showMessage(planActL10n(context).undoRefreshPending);
          return;
        }
        if (mounted && _loadError == null) {
          _showMessage(PersianCopy.financePageRecordTransactionMessage);
        }
      }
    } catch (error) {
      _logger.error(
        'Finance transaction creation failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (mounted) {
        _showMessage(PersianCopy.financePageRecordTransactionMessage2);
      }
    } finally {
      if (sheetRemoved != null) await sheetRemoved;
      amount.dispose();
      note.dispose();
    }
  }

  Future<void> _voidEntry(AccountEntry entry) async {
    if (!_pendingEntries.add(entry.id)) return;
    setState(() {});
    try {
      await _confirmVoidEntry(entry);
    } finally {
      if (mounted) setState(() => _pendingEntries.remove(entry.id));
    }
  }

  Future<void> _confirmVoidEntry(AccountEntry entry) async {
    final account = _accounts
        .where((item) => item.id == entry.accountId)
        .firstOrNull;
    if (account == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(PersianCopy.financePageConfirmedTitle),
        content: Text(
          entry.transferGroupId == null
              ? PersianCopy.financePageConfirmedContent
              : planActL10n(context).financeCancelTransferMessage,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(PersianCopy.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(PersianCopy.financePageConfirmedActions),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _finance.voidEntry(original: entry, account: account);
    } catch (_) {
      if (mounted) _showMessage(PersianCopy.financePageVoidEntryMessage2);
      return;
    }
    try {
      await _refresh();
      await widget.onDataChanged?.call();
      if (mounted) _showMessage(PersianCopy.financePageVoidEntryMessage);
    } catch (_) {
      if (mounted) _showMessage(planActL10n(context).undoRefreshPending);
    }
  }

  void _showMessage(String message) {
    showRecordedActionFeedback(context, message);
  }

  String _money(Money money) =>
      PersianMoneyText.money(money, unit: MoneyUnitScope.of(context));

  Future<void> _reorderAccounts() async {
    final ordered = List<FinancialAccount>.from(_accounts);
    final result = await showModalBottomSheet<List<FinancialAccount>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AccountReorderSheet(accounts: ordered),
    );
    if (!mounted || result == null) return;
    try {
      await _finance.reorderAccounts(
        result.map((account) => account.id).toList(),
      );
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(planActL10n(context).financePageReorderAccountsDone),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(planActL10n(context).financePageReorderAccountsError),
          ),
        );
      }
    }
  }

  List<AccountEntry> get _filteredEntries {
    final byId = {for (final e in _entries) e.id.value: e};
    AccountEntry classification(AccountEntry e) =>
        e.type == AccountEntryType.reversal ? byId[e.referenceId] ?? e : e;
    final entries =
        _entries
            .where(
              (entry) =>
                  _tagMatches == null || _tagMatches!.contains(entry.id.value),
            )
            .where(
              (entry) =>
                  _typeFilter == null ||
                  classification(entry).type == _typeFilter,
            )
            .where(
              (entry) =>
                  _categoryFilter == null ||
                  classification(entry).category == _categoryFilter,
            )
            .toList()
          ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return entries;
  }

  Widget _buildSummary() {
    final currency = _accounts.isEmpty
        ? CurrencyCodes.irr
        : _accounts.first.currency;
    final summary = cashFlowSummary(
      _filteredEntries.where((entry) => entry.amount.currency == currency),
      currency,
      sourceEntries: _entries,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              PersianCopy.financePageBuildSummaryChildren,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              PersianCopy.financePageBuildSummaryChildren2(
                (PersianMoneyText.amount(
                  summary.incoming,
                  currency,
                  unit: MoneyUnitScope.of(context),
                )).toString(),
              ),
            ),
            Text(
              PersianCopy.financePageBuildSummaryChildren3(
                (PersianMoneyText.amount(
                  summary.outgoing,
                  currency,
                  unit: MoneyUnitScope.of(context),
                )).toString(),
              ),
            ),
            Text(
              PersianCopy.financePageBuildSummaryChildren4(
                (PersianMoneyText.amount(
                  summary.net,
                  currency,
                  unit: MoneyUnitScope.of(context),
                )).toString(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(PersianCopy.financePageBuildSummaryChildren5),
            if (_accounts.any((account) => account.currency != currency))
              const Text(PersianCopy.financePageBuildSummaryChildren6),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final categories = _entries
        .map((entry) => entry.category)
        .whereType<String>()
        .toSet()
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButton<AccountEntryType?>(
          isExpanded: true,
          itemHeight: null,
          value: _typeFilter,
          hint: const Text(PersianCopy.financePageBuildFiltersHint),
          items: const [
            DropdownMenuItem(
              value: null,
              child: Text(PersianCopy.financePageBuildFiltersItems),
            ),
            DropdownMenuItem(
              value: AccountEntryType.income,
              child: Text(PersianCopy.financePageBuildFiltersItems2),
            ),
            DropdownMenuItem(
              value: AccountEntryType.expense,
              child: Text(PersianCopy.financePageBuildFiltersItems3),
            ),
          ],
          onChanged: (value) => setState(() => _typeFilter = value),
        ),
        DropdownButton<String?>(
          isExpanded: true,
          itemHeight: null,
          value: _categoryFilter,
          hint: const Text(PersianCopy.financePageBuildFiltersHint2),
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text(PersianCopy.financePageBuildFiltersItems4),
            ),
            ...categories.map(
              (item) => DropdownMenuItem(value: item, child: Text(item)),
            ),
          ],
          onChanged: (value) => setState(() => _categoryFilter = value),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:
          widget.focusedRecordId == null ||
          (_pendingEntries.isEmpty && _pendingAccounts.isEmpty),
      child: Scaffold(
        appBar: widget.embedded
            ? null
            : AppBar(title: Text(planActL10n(context).navigationFinance)),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : !_hasLoaded
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _loadError ??
                          planActL10n(context).financePageBuildChildren,
                    ),
                    TextButton(
                      onPressed: _refresh,
                      child: Text(planActL10n(context).commonRetry),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    PlanActSpacing.lg,
                    PlanActSpacing.lg,
                    PlanActSpacing.lg,
                    PlanActSpacing.lg + widget.bottomContentPadding,
                  ),
                  children: [
                    if (_loadError != null)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.warning_amber_outlined),
                          title: Text(
                            planActL10n(context).financePageBuildTitle2,
                          ),
                          subtitle: Text(_loadError!),
                          trailing: TextButton(
                            onPressed: _refresh,
                            child: Text(planActL10n(context).commonRetry),
                          ),
                        ),
                      ),
                    if (widget.focusedRecordId == null) ...[
                      _buildSummary(),
                      const SizedBox(height: 12),
                      _buildFilters(),
                      if (widget.tagRepository != null) ...[
                        if (_filterBusy) const LinearProgressIndicator(),
                        TagFilter(
                          tags: _tags,
                          selected: _tagFilter,
                          enabled: !_filterBusy,
                          onChanged: _filterTag,
                        ),
                        TextButton(
                          onPressed: () => showTagManager(
                            context,
                            repository: widget.tagRepository!,
                            onChanged: _tagsChanged,
                          ),
                          child: Text(
                            planActL10n(context).tagControlsContentChildren,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              planActL10n(context).financePageBuildChildren2,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Wrap(
                            spacing: 4,
                            children: [
                              IconButton(
                                onPressed: _addIncome,
                                tooltip: planActL10n(context)
                                    .financePageBuildTooltip,
                                icon: const Icon(Icons.add_circle_outline),
                              ),
                              IconButton(
                                onPressed: _addAccount,
                                tooltip: planActL10n(context)
                                    .accountFormSheetBuildTitle,
                                icon: const Icon(Icons.add_card),
                              ),
                              IconButton(
                                onPressed: _accounts.length < 2
                                    ? null
                                    : _reorderAccounts,
                                tooltip: planActL10n(context)
                                    .financePageReorderAccounts,
                                icon: const Icon(Icons.swap_vert),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                    if (_accounts.isEmpty)
                      Card(
                        child: ListTile(
                          title: Text(
                            planActL10n(context).financePageBuildTitle3,
                          ),
                        ),
                      ),
                    for (final account in _accounts.where(
                      (a) =>
                          widget.focusedRecordId != null &&
                              widget.focusedKind == FinanceRecordKind.account &&
                              a.id.value == widget.focusedRecordId ||
                          widget.focusedRecordId == null &&
                              (widget.showArchivedAccounts ||
                                  a.status == FinancialAccountStatus.active),
                    ))
                      Padding(
                        padding: const EdgeInsets.only(
                          bottom: PlanActSpacing.md,
                        ),
                        child: AccountInformationCard(
                          key: ValueKey(account.id),
                          account: account,
                          balance: rebuildBalance(account, _entries),
                          operations: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: planActL10n(context)
                                    .accountFormSheetBuildTitle2,
                                onPressed: _pendingAccounts.contains(account.id)
                                    ? null
                                    : () => _editAccount(account),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              PopupMenuButton<String>(
                                key: ValueKey(
                                  'account-menu:${account.id.value}',
                                ),
                                tooltip:
                                    account.status ==
                                        FinancialAccountStatus.active
                                    ? planActL10n(context)
                                          .financeArchivedAccountAction
                                    : planActL10n(context)
                                          .financeRestoreAccountAction,
                                enabled: !_pendingAccounts.contains(account.id),
                                onSelected: (action) {
                                  if (action == 'delete') {
                                    _deleteAccount(account);
                                  } else {
                                    _changeAccountStatus(account);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'status',
                                    child: Text(
                                      account.status ==
                                              FinancialAccountStatus.active
                                          ? planActL10n(context)
                                                .financeArchivedAccountAction
                                          : planActL10n(context)
                                                .financeRestoreAccountAction,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      planActL10n(context)
                                          .financeDeleteAccountAction,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    if (widget.focusedRecordId == null)
                      Text(
                        planActL10n(context).financePageBuildChildren3,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    if ((widget.focusedRecordId == null &&
                            _filteredEntries.isEmpty) ||
                        (widget.focusedRecordId != null &&
                            (widget.focusedKind == FinanceRecordKind.account
                                ? !_accounts.any(
                                    (a) => a.id.value == widget.focusedRecordId,
                                  )
                                : !_entries.any(
                                    (e) => e.id.value == widget.focusedRecordId,
                                  ))))
                      Card(
                        child: ListTile(
                          title: Text(
                            planActL10n(context).financePageBuildTitle4,
                          ),
                        ),
                      ),
                    for (final entry in _filteredEntries.where(
                      (e) =>
                          widget.focusedRecordId == null ||
                          (widget.focusedKind == FinanceRecordKind.entry &&
                              e.id.value == widget.focusedRecordId),
                    ))
                      Card(
                        margin: const EdgeInsets.only(
                          bottom: PlanActSpacing.md,
                        ),
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        shape: const RoundedRectangleBorder(
                          borderRadius: PlanActRadius.card,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(PlanActSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TransactionDirectionIcon(entry: entry),
                                  _entryOperations(entry),
                                ],
                              ),
                              Text(
                                '${transactionLabel(entry)} · ${_money(entry.amount)}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: PlanActSpacing.sm),
                              DefaultTextStyle.merge(
                                style: Theme.of(context).textTheme.bodyMedium,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      [
                                        if (widget.focusedRecordId != null)
                                          _accounts
                                                  .where(
                                                    (a) =>
                                                        a.id == entry.accountId,
                                                  )
                                                  .firstOrNull
                                                  ?.name ??
                                              '',
                                        PersianDateFormatter.date(
                                          JalaliDate.fromDateTime(
                                            entry.occurredAt.toLocal(),
                                          ),
                                        ),
                                        PersianNumbers.format(
                                          '${entry.occurredAt.toLocal().hour.toString().padLeft(2, '0')}:${entry.occurredAt.toLocal().minute.toString().padLeft(2, '0')}',
                                        ),
                                        if (entry.category != null)
                                          entry.category!,
                                        entry.note ??
                                            planActL10n(context)
                                                .financePageBuildChildren4,
                                      ].join(' · '),
                                    ),
                                    TagLabels(
                                      labels: _tags
                                          .where(
                                            (tag) =>
                                                _entryTags[entry.id.value]
                                                    ?.contains(tag.id) ??
                                                false,
                                          )
                                          .map((tag) => tag.label),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _entryOperations(AccountEntry entry) => PopupMenuButton<String>(
    key: ValueKey('entry-menu:${entry.id.value}'),
    enabled:
        !_pendingEntries.contains(entry.id) &&
        (widget.tagRepository != null ||
            (!_isReversed(entry) && entry.type != AccountEntryType.reversal)),
    tooltip: PersianCopy.financePageEntryOperationsTooltip,
    onSelected: (value) {
      if (value == 'void') _voidEntry(entry);
      if (value == 'correct') {
        _recordTransaction(
          income: entry.type == AccountEntryType.income,
          original: entry,
        );
      }
      if (value == 'tags') _editEntryTags(entry);
      if (value == 'relationship') {
        widget.onDetermineRelationship?.call(entry.id);
      }
    },
    itemBuilder: (context) => [
      if (widget.onDetermineRelationship != null &&
          !_isReversed(entry) &&
          (entry.type == AccountEntryType.income ||
              entry.type == AccountEntryType.expense))
        const PopupMenuItem(
          value: 'relationship',
          child: Text(PersianCopy.financePageEntryOperationsItemBuilder),
        ),
      if (widget.tagRepository != null)
        const PopupMenuItem(
          value: 'tags',
          child: Text(PersianCopy.financePageEntryOperationsItemBuilder2),
        ),
      if (!_isReversed(entry) &&
          entry.type != AccountEntryType.reversal &&
          {
            AccountEntryType.income,
            AccountEntryType.expense,
          }.contains(entry.type) &&
          entry.transferGroupId == null)
        PopupMenuItem(
          value: 'correct',
          child: Text(planActL10n(context).financeCorrectAction),
        ),
      if (!_isReversed(entry) && entry.type != AccountEntryType.reversal)
        PopupMenuItem(
          value: 'void',
          child: Text(PersianCopy.financePageConfirmedTitle),
        ),
    ],
  );

  bool _isReversed(AccountEntry entry) => _entries.any(
    (e) =>
        e.type == AccountEntryType.reversal && e.referenceId == entry.id.value,
  );

  Future<void> _changeAccountStatus(FinancialAccount account) async {
    if (!_pendingAccounts.add(account.id)) return;
    setState(() {});
    try {
      if (!await confirmRecordedAction(
            context,
            account.status == FinancialAccountStatus.active
                ? planActL10n(context).financeArchiveAccountMessage
                : planActL10n(context).undoConfirmMessage,
          ) ||
          !mounted) {
        return;
      }
      try {
        if (account.status == FinancialAccountStatus.active) {
          await _finance.archive(account);
        } else {
          await _finance.restore(account);
        }
      } catch (_) {
        if (mounted) _showMessage(planActL10n(context).undoConflict);
        return;
      }
      await _refresh();
      try {
        await widget.onDataChanged?.call();
      } catch (_) {
        if (mounted) _showMessage(planActL10n(context).undoRefreshPending);
        return;
      }
      final repo = widget.repository;
      final token = repo is AccountStatusUndoRepository
          ? await (repo as AccountStatusUndoRepository).accountStatusUndo(
              account.id,
            )
          : null;
      if (mounted) {
        showRecordedActionFeedback(
          context,
          planActL10n(context).undoStateSaved,
          onUndo: token == null
              ? null
              : () => _undoAccountStatus(account.id, token),
        );
      }
    } finally {
      if (mounted) setState(() => _pendingAccounts.remove(account.id));
    }
  }

  Future<void> _deleteAccount(FinancialAccount account) async {
    if (!_pendingAccounts.add(account.id)) return;
    setState(() {});
    try {
      if (!await confirmRecordedAction(
            context,
            planActL10n(context).financeDeleteAccountMessage,
          ) ||
          !mounted) {
        return;
      }
      try {
        await _finance.deleteAccount(account.id);
      } catch (_) {
        if (mounted) {
          _showMessage(planActL10n(context).financeDeleteAccountFailed);
        }
        return;
      }
      await _refresh();
      try {
        await widget.onDataChanged?.call();
      } catch (_) {
        if (mounted) {
          _showMessage(planActL10n(context).undoRefreshPending);
        }
        return;
      }
      if (mounted) {
        _showMessage(planActL10n(context).financeDeleteAccountSuccess);
      }
    } finally {
      if (mounted) setState(() => _pendingAccounts.remove(account.id));
    }
  }

  Future<void> _undoAccountStatus(StableId id, UndoToken token) async {
    final repository = widget.repository;
    if (repository is! AccountStatusUndoRepository ||
        !_pendingAccounts.add(id)) {
      return;
    }
    setState(() {});
    try {
      if (!await confirmRecordedAction(
            context,
            planActL10n(context).undoConfirmMessage,
          ) ||
          !mounted) {
        return;
      }
      try {
        await (repository as AccountStatusUndoRepository).undoAccountStatus(
          id,
          token,
        );
      } catch (_) {
        if (mounted) _showMessage(planActL10n(context).undoConflict);
        return;
      }
      await _refresh();
      try {
        await widget.onDataChanged?.call();
      } catch (_) {
        if (mounted) _showMessage(planActL10n(context).undoRefreshPending);
        return;
      }
      if (mounted) _showMessage(planActL10n(context).undoSuccess);
    } finally {
      if (mounted) setState(() => _pendingAccounts.remove(id));
    }
  }
}

class _AccountReorderSheet extends StatefulWidget {
  const _AccountReorderSheet({required this.accounts});

  final List<FinancialAccount> accounts;

  @override
  State<_AccountReorderSheet> createState() => _AccountReorderSheetState();
}

class _AccountReorderSheetState extends State<_AccountReorderSheet> {
  late final List<FinancialAccount> _accounts = List.of(widget.accounts);

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(PlanActSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            planActL10n(context).financePageReorderAccounts,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: PlanActSpacing.md),
          Flexible(
            child: ReorderableListView.builder(
              shrinkWrap: true,
              itemCount: _accounts.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final account = _accounts.removeAt(oldIndex);
                  _accounts.insert(newIndex, account);
                });
              },
              itemBuilder: (context, index) {
                final account = _accounts[index];
                return ListTile(
                  key: ValueKey(account.id),
                  leading: const Icon(Icons.drag_handle),
                  title: Text(account.name),
                  subtitle: Text(account.bank?.label ?? account.currency),
                );
              },
            ),
          ),
          const SizedBox(height: PlanActSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(planActL10n(context).commonCancel),
              ),
              const SizedBox(width: PlanActSpacing.sm),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_accounts),
                child: Text(planActL10n(context).commonSave),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
