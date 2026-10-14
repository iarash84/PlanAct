import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:planact/features/finance/presentation/account_form_sheet.dart';
import 'package:planact/features/finance/presentation/account_information_card.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/features/finance/presentation/financial_account_picker.dart';
import 'package:planact/features/finance/presentation/transaction_direction.dart';
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
  });

  final Future<void> Function(StableId transactionId)? onDetermineRelationship;
  final TagRepository? tagRepository;
  final Future<void> Function()? onTagsChanged;
  final Future<void> Function()? onDataChanged;
  final FinanceRepository repository;
  final bool embedded;
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
        for (final entry in entries) {
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
  }) async {
    var draftTags = {...initialTags};
    final moneyInput = PinnedMoneyInput(MoneyUnitScope.of(context));
    final amount = TextEditingController();
    final note = TextEditingController();
    FinancialAccount? account;
    var occurredAt = DateTime.now();
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
                title: income
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
                      note: note.text.trim().isEmpty ? null : note.text.trim(),
                      category: income
                          ? PersianCopy.financePageResultCategory
                          : PersianCopy.commonGeneral,
                      tags: draftTags,
                    );
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
                    FinancialAccountPicker(
                      repository: widget.repository,
                      enabled: !saving,
                      onChanged: (value) =>
                          setDialogState(() => account = value),
                      onCreateAccount: () => openFinancialAccountCreation(
                        context,
                        widget.repository,
                      ),
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
                    TextField(
                      controller: note,
                      decoration: InputDecoration(
                        labelText: income
                            ? PersianCopy.financePageResultLabelText2
                            : PersianCopy.financePageResultLabelText3,
                      ),
                    ),
                    DraftTagPicker(
                      repository: widget.tagRepository,
                      selected: draftTags,
                      enabled: !saving,
                      onChanged: (tags) =>
                          setDialogState(() => draftTags = tags),
                    ),
                    const SizedBox(height: 8),
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
        await _refresh();
        await widget.onDataChanged?.call();
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
    final account = _accounts
        .where((item) => item.id == entry.accountId)
        .firstOrNull;
    if (account == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(PersianCopy.financePageConfirmedTitle),
        content: const Text(PersianCopy.financePageConfirmedContent),
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
      await _refresh();
      await widget.onDataChanged?.call();
      if (mounted) _showMessage(PersianCopy.financePageVoidEntryMessage);
    } catch (_) {
      if (mounted) _showMessage(PersianCopy.financePageVoidEntryMessage2);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _money(Money money) =>
      PersianMoneyText.money(money, unit: MoneyUnitScope.of(context));

  List<AccountEntry> get _filteredEntries {
    final entries =
        _entries
            .where(
              (entry) =>
                  _tagMatches == null || _tagMatches!.contains(entry.id.value),
            )
            .where((entry) => _typeFilter == null || entry.type == _typeFilter)
            .where(
              (entry) =>
                  _categoryFilter == null || entry.category == _categoryFilter,
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
    return Scaffold(
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
                    _loadError ?? planActL10n(context).financePageBuildChildren,
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
                padding: const EdgeInsets.all(16),
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
                        ],
                      ),
                    ],
                  ),
                  if (_accounts.isEmpty)
                    Card(
                      child: ListTile(
                        title: Text(
                          planActL10n(context).financePageBuildTitle3,
                        ),
                      ),
                    ),
                  for (final account in _accounts)
                    AccountInformationCard(
                      key: ValueKey(account.id),
                      account: account,
                      balance: rebuildBalance(account, _entries),
                      operations: IconButton(
                        tooltip: planActL10n(context)
                            .accountFormSheetBuildTitle2,
                        onPressed: () => _editAccount(account),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    planActL10n(context).financePageBuildChildren3,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_filteredEntries.isEmpty)
                    Card(
                      child: ListTile(
                        title: Text(
                          planActL10n(context).financePageBuildTitle4,
                        ),
                      ),
                    ),
                  for (final entry in _filteredEntries)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(PlanActSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    );
  }

  Widget _entryOperations(AccountEntry entry) => PopupMenuButton<String>(
    tooltip: PersianCopy.financePageEntryOperationsTooltip,
    onSelected: (value) {
      if (value == 'void') _voidEntry(entry);
      if (value == 'tags') _editEntryTags(entry);
      if (value == 'relationship') {
        widget.onDetermineRelationship?.call(entry.id);
      }
    },
    itemBuilder: (context) => [
      if (widget.onDetermineRelationship != null &&
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
      PopupMenuItem(
        value: 'void',
        child: Text(PersianCopy.financePageConfirmedTitle),
      ),
    ],
  );
}
