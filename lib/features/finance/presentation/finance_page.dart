import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/domain/tag.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/logging/app_logger.dart';
import 'package:planact/core/money/money_input_formatter.dart';
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

class FinancePage extends StatefulWidget {
  const FinancePage({
    super.key,
    required this.repository,
    this.expectationRepository,
    this.tagRepository,
    this.onTagsChanged,
    this.onDetermineRelationship,
  });

  final Future<void> Function(StableId transactionId)? onDetermineRelationship;
  final TagRepository? tagRepository;
  final Future<void> Function()? onTagsChanged;
  final FinanceRepository repository;
  final FinancialExpectationRepository? expectationRepository;

  @override
  State<FinancePage> createState() => FinancePageState();
}

class FinancePageState extends State<FinancePage> {
  Future<void> openTransactionForm({required bool income}) =>
      income ? _addIncome() : _addExpense();

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
          _loadError = 'بارگذاری اطلاعات مالی انجام نشد. دوباره تلاش کنید.';
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
      if (mounted) _showMessage('فیلتر برچسب انجام نشد؛ دوباره تلاش کنید.');
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

  Future<void> _editAccount(FinancialAccount account) async {
    try {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _AccountEditDialog(initialName: account.name),
      );
      if (!mounted ||
          result == null ||
          result.isEmpty ||
          result == account.name) {
        return;
      }
      await _finance.updateAccount(account: account, name: result);
      await _refresh();
    } catch (_) {
      if (mounted) _showMessage('ویرایش حساب انجام نشد؛ دوباره تلاش کنید.');
    }
  }

  Future<void> _addAccount() async {
    final name = TextEditingController();
    final opening = TextEditingController();
    var type = FinancialAccountType.cash;
    IranianBank? bank;
    try {
      final result =
          await showModalBottomSheet<
            ({String name, FinancialAccountType type, IranianBank? bank})
          >(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => StatefulBuilder(
              builder: (context, setDialogState) => PlanActFormSheet(
                title: 'افزودن حساب',
                primaryLabel: 'افزودن',
                onPrimary: () {
                  if (name.text.trim().isNotEmpty) {
                    Navigator.pop(context, (
                      name: name.text.trim(),
                      type: type,
                      bank: bank,
                    ));
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: name,
                      autofocus: true,
                      onChanged: (value) {
                        final detected = IranianBank.detect(value);
                        if (detected != null && bank != detected) {
                          setDialogState(() {
                            bank = detected;
                            type = FinancialAccountType.bank;
                          });
                        }
                      },
                      decoration: const InputDecoration(labelText: 'نام حساب'),
                    ),
                    DropdownButtonFormField<FinancialAccountType>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: 'نوع حساب'),
                      items: const [
                        DropdownMenuItem(
                          value: FinancialAccountType.cash,
                          child: Text('نقدی'),
                        ),
                        DropdownMenuItem(
                          value: FinancialAccountType.bank,
                          child: Text('بانکی'),
                        ),
                        DropdownMenuItem(
                          value: FinancialAccountType.digitalWallet,
                          child: Text('کیف پول'),
                        ),
                        DropdownMenuItem(
                          value: FinancialAccountType.credit,
                          child: Text('اعتباری'),
                        ),
                      ],
                      onChanged: (value) => setDialogState(() {
                        type = value ?? FinancialAccountType.cash;
                        bank = type == FinancialAccountType.bank
                            ? IranianBank.detect(name.text)
                            : null;
                      }),
                    ),
                    if (type == FinancialAccountType.bank)
                      DropdownButtonFormField<IranianBank?>(
                        initialValue: bank,
                        decoration: const InputDecoration(
                          labelText: 'بانک (اختیاری)',
                        ),
                        items: [
                          const DropdownMenuItem<IranianBank?>(
                            value: null,
                            child: Text('بدون انتخاب'),
                          ),
                          ...IranianBank.values.map(
                            (item) => DropdownMenuItem<IranianBank?>(
                              value: item,
                              child: Text(item.label),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => bank = value),
                      ),
                    TextField(
                      controller: opening,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [MoneyInputFormatter()],
                      decoration: const InputDecoration(
                        labelText: 'موجودی اولیه (اختیاری)',
                        suffixText: 'ریال',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
      final value = int.tryParse(opening.text.replaceAll(',', '').trim());
      if (result == null || result.name.isEmpty) return;
      if (opening.text.trim().isNotEmpty && value == null) {
        _showMessage('موجودی اولیه معتبر نیست.');
        return;
      }
      final account = FinancialAccount(
        id: StableId.generate(),
        name: result.name,
        currency: CurrencyCodes.irr,
        type: result.type,
        bank: result.bank,
      );
      await _finance.createAccount(
        account,
        openingBalance: value == null || value == 0
            ? null
            : Money(minorUnits: value, currency: account.currency),
      );
      await _refresh();
    } catch (error) {
      _logger.error(
        'Finance account creation failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (mounted) _showMessage('افزودن حساب انجام نشد. دوباره تلاش کنید.');
    } finally {
      name.dispose();
      opening.dispose();
    }
  }

  Future<void> _addIncome() => _recordTransaction(income: true);

  Future<void> _addExpense() => _recordTransaction(income: false);

  Future<void> _recordTransaction({required bool income}) async {
    if (_accounts.isEmpty) {
      _showMessage('ابتدا یک حساب اضافه کنید.');
      return;
    }
    final amount = TextEditingController();
    final note = TextEditingController();
    var account = _accounts.first;
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
                title: income ? 'ثبت درآمد / واریز' : 'ثبت هزینه',
                primaryLabel: 'ثبت',
                isLoading: saving,
                onPrimary: () async {
                  if (saving) return;
                  final value = int.tryParse(
                    MoneyInputFormatter.normalize(amount.text),
                  );
                  if (value == null || value <= 0) {
                    setDialogState(() => formError = 'مبلغ معتبر وارد کنید.');
                    return;
                  }
                  setDialogState(() {
                    saving = true;
                    formError = null;
                  });
                  try {
                    await _finance.record(
                      account: account,
                      type: income
                          ? AccountEntryType.income
                          : AccountEntryType.expense,
                      amount: Money(
                        minorUnits: value,
                        currency: account.currency,
                      ),
                      occurredAt: occurredAt,
                      note: note.text.trim().isEmpty ? null : note.text.trim(),
                      category: income ? 'دریافت' : 'عمومی',
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
                        formError = 'ثبت تراکنش انجام نشد؛ اطلاعات شما حفظ شده است. دوباره تلاش کنید.';
                      });
                    }
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<FinancialAccount>(
                      initialValue: account,
                      decoration: const InputDecoration(labelText: 'حساب'),
                      items: _accounts
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => account = value);
                        }
                      },
                    ),
                    TextField(
                      controller: amount,
                      keyboardType: TextInputType.number,
                      inputFormatters: const [MoneyInputFormatter()],
                      decoration: InputDecoration(
                        labelText:
                            'مبلغ به ${CurrencyCodes.label(account.currency)}',
                      ),
                    ),
                    TextField(
                      controller: note,
                      decoration: InputDecoration(
                        labelText: income ? 'شرح درآمد' : 'شرح هزینه',
                      ),
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
        if (mounted && _loadError == null) _showMessage('تراکنش ثبت شد.');
      }
    } catch (error) {
      _logger.error(
        'Finance transaction creation failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (mounted) _showMessage('ثبت تراکنش انجام نشد؛ دوباره تلاش کنید.');
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
        title: const Text('حذف امن تراکنش'),
        content: const Text(
          'این تراکنش از تاریخچه حذف نمی‌شود و با یک ثبت جبرانی خنثی می‌شود.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأیید'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _finance.voidEntry(original: entry, account: account);
      await _refresh();
      if (mounted) _showMessage('تراکنش با ثبت جبرانی خنثی شد.');
    } catch (_) {
      if (mounted) _showMessage('حذف امن تراکنش انجام نشد.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _money(Money money) => PersianMoneyText.money(money);

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
      _entries.where((entry) => entry.amount.currency == currency),
      currency,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'جریان نقدی این داده‌ها',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'ورودی: ${PersianMoneyText.amount(summary.incoming, currency)}',
            ),
            Text(
              'خروجی: ${PersianMoneyText.amount(summary.outgoing, currency)}',
            ),
            Text(
              'خالص: ${PersianMoneyText.amount(summary.net.abs(), currency)}',
            ),
            const SizedBox(height: 8),
            const Text(
              'این گزارش فقط بر اساس تراکنش‌های ثبت‌شده روی دستگاه است.',
            ),
            if (_accounts.any((account) => account.currency != currency))
              const Text(
                'حساب‌هایی با واحد پول دیگر در این جمع لحاظ نشده‌اند.',
              ),
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
    return Wrap(
      spacing: 8,
      children: [
        DropdownButton<AccountEntryType?>(
          value: _typeFilter,
          hint: const Text('نوع'),
          items: const [
            DropdownMenuItem(value: null, child: Text('همه تراکنش‌ها')),
            DropdownMenuItem(
              value: AccountEntryType.income,
              child: Text('ورودی'),
            ),
            DropdownMenuItem(
              value: AccountEntryType.expense,
              child: Text('خروجی'),
            ),
          ],
          onChanged: (value) => setState(() => _typeFilter = value),
        ),
        DropdownButton<String?>(
          value: _categoryFilter,
          hint: const Text('دسته‌بندی'),
          items: [
            const DropdownMenuItem(value: null, child: Text('همه دسته‌ها')),
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
      appBar: AppBar(title: const Text('مالی')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_hasLoaded
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_loadError ?? 'اطلاعات مالی در دسترس نیست.'),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('تلاش دوباره'),
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
                        title: const Text(
                          'اطلاعات نمایش‌داده‌شده ممکن است قدیمی باشد.',
                        ),
                        subtitle: Text(_loadError!),
                        trailing: TextButton(
                          onPressed: _refresh,
                          child: const Text('تلاش دوباره'),
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
                      child: const Text('مدیریت برچسب‌ها'),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'حساب‌ها',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            onPressed: _addIncome,
                            tooltip: 'ثبت درآمد یا واریز',
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                          IconButton(
                            onPressed: _addAccount,
                            tooltip: 'افزودن حساب',
                            icon: const Icon(Icons.add_card),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_accounts.isEmpty)
                    const Card(
                      child: ListTile(title: Text('هنوز حسابی ثبت نشده است.')),
                    ),
                  for (final account in _accounts)
                    Card(
                      child: ListTile(
                        leading: _BankAccountAvatar(account: account),
                        title: Text(account.name),
                        subtitle: Text(
                          [
                            if (account.bank != null) account.bank!.label,
                            account.status == FinancialAccountStatus.active
                                ? 'فعال'
                                : 'بایگانی‌شده',
                          ].join(' · '),
                        ),
                        onTap: () => _editAccount(account),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FutureBuilder<Money>(
                              future: _finance.balance(account),
                              builder: (context, snapshot) => Text(
                                snapshot.hasData ? _money(snapshot.data!) : '—',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'ویرایش حساب',
                              onPressed: () => _editAccount(account),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'آخرین تراکنش‌ها',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_filteredEntries.isEmpty)
                    const Card(
                      child: ListTile(
                        title: Text('تراکنشی با این فیلترها پیدا نشد.'),
                      ),
                    ),
                  for (final entry in _filteredEntries)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          entry.type == AccountEntryType.income
                              ? Icons.add_circle_outline
                              : Icons.remove_circle_outline,
                          color: entry.type == AccountEntryType.income
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          '${entry.type == AccountEntryType.income ? 'ورودی' : 'خروجی'} · ${_money(entry.amount)}',
                        ),
                        subtitle: Column(
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
                                if (entry.category != null) entry.category!,
                                entry.note ?? 'بدون شرح',
                              ].join(' · '),
                            ),
                            TagLabels(
                              labels: _tags
                                  .where(
                                    (tag) =>
                                        _entryTags[entry.id.value]?.contains(
                                          tag.id,
                                        ) ??
                                        false,
                                  )
                                  .map((tag) => tag.label),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'عملیات تراکنش',
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
                                child: Text('تعیین ارتباط'),
                              ),
                            if (widget.tagRepository != null)
                              const PopupMenuItem(
                                value: 'tags',
                                child: Text('برچسب‌های تراکنش'),
                              ),
                            PopupMenuItem(
                              value: 'void',
                              child: Text('حذف امن تراکنش'),
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
}

class _BankAccountAvatar extends StatelessWidget {
  const _BankAccountAvatar({required this.account});

  final FinancialAccount account;

  @override
  Widget build(BuildContext context) {
    final bank = account.bank ?? IranianBank.detect(account.name);
    if (bank == null) {
      return CircleAvatar(
        child: Icon(
          account.type == FinancialAccountType.bank
              ? Icons.account_balance
              : Icons.account_balance_wallet,
        ),
      );
    }

    return CircleAvatar(
      backgroundColor: _bankColor(bank),
      child: Text(
        bank.label.characters.first,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Color _bankColor(IranianBank bank) => switch (bank) {
  IranianBank.mellat => const Color(0xffd71920),
  IranianBank.melli => const Color(0xff087f5b),
  IranianBank.saderat => const Color(0xff1565c0),
  IranianBank.tejarat => const Color(0xff00838f),
  IranianBank.pasargad => const Color(0xff6a1b9a),
  _ => const Color(0xff455a64),
};

class _AccountEditDialog extends StatefulWidget {
  const _AccountEditDialog({required this.initialName});

  final String initialName;

  @override
  State<_AccountEditDialog> createState() => _AccountEditDialogState();
}

class _AccountEditDialogState extends State<_AccountEditDialog> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlanActFormSheet(
    title: 'ویرایش حساب',
    onPrimary: () => Navigator.of(context).pop(_name.text.trim()),
    child: TextField(
      controller: _name,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'نام حساب'),
    ),
  );
}
