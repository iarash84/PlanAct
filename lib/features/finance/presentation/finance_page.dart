import 'package:flutter/material.dart';
import 'package:planact/core/logging/app_logger.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/finance_reports.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({
    super.key,
    required this.repository,
    this.expectationRepository,
  });

  final FinanceRepository repository;
  final FinancialExpectationRepository? expectationRepository;

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  static const _logger = AppLogger();
  late final FinanceUseCases _finance = FinanceUseCases(widget.repository);
  FinancialExpectationUseCases? get _expectations =>
      widget.expectationRepository == null
      ? null
      : FinancialExpectationUseCases(widget.expectationRepository!);
  List<FinancialAccount> _accounts = const [];
  List<AccountEntry> _entries = const [];
  bool _loading = true;
  String? _categoryFilter;
  AccountEntryType? _typeFilter;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final accounts = await widget.repository.listAccounts();
      final entries = await widget.repository.listEntries();
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _entries = entries;
          _loading = false;
        });
      }
    } catch (error) {
      _logger.error(
        'Finance refresh failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (mounted) {
        setState(() => _loading = false);
        _showMessage('بارگذاری اطلاعات مالی انجام نشد. دوباره تلاش کنید.');
      }
    }
  }

  Future<void> _editAccount(FinancialAccount account) async {
    try {
      final result = await showDialog<String>(
        context: context,
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
    try {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('افزودن حساب'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'نام حساب'),
              ),
              TextField(
                controller: opening,
                keyboardType: TextInputType.number,
                inputFormatters: const [MoneyInputFormatter()],
                decoration: const InputDecoration(
                  labelText: 'موجودی اولیه (اختیاری)',
                  suffixText: 'تومان',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, name.text.trim()),
              child: const Text('افزودن'),
            ),
          ],
        ),
      );
      final value = int.tryParse(opening.text.replaceAll(',', '').trim());
      if (result == null || result.isEmpty) return;
      if (opening.text.trim().isNotEmpty && value == null) {
        _showMessage('موجودی اولیه معتبر نیست.');
        return;
      }
      final account = FinancialAccount(
        id: StableId.generate(),
        name: result,
        currency: 'تومان',
        type: FinancialAccountType.cash,
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
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(income ? 'ثبت درآمد / واریز' : 'ثبت هزینه'),
            content: Column(
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
                    if (value != null) setDialogState(() => account = value);
                  },
                ),
                TextField(
                  controller: amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: const [MoneyInputFormatter()],
                  decoration: const InputDecoration(labelText: 'مبلغ به تومان'),
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
                            builder: (_) => _FinanceJalaliDatePicker(
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
                          '${occurredAt.year}/${occurredAt.month}/${occurredAt.day}',
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
                          '${occurredAt.hour.toString().padLeft(2, '0')}:${occurredAt.minute.toString().padLeft(2, '0')}',
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
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('انصراف'),
              ),
              FilledButton(
                onPressed: () {
                  final value = int.tryParse(
                    MoneyInputFormatter.normalize(amount.text),
                  );
                  if (value == null || value <= 0) {
                    setDialogState(() => formError = 'مبلغ معتبر وارد کنید.');
                    return;
                  }
                  Navigator.pop(context, true);
                },
                child: const Text('ثبت'),
              ),
            ],
          ),
        ),
      );
      final value = int.tryParse(MoneyInputFormatter.normalize(amount.text));
      if (result != true || value == null || value <= 0) return;
      await _finance.record(
        account: account,
        type: income ? AccountEntryType.income : AccountEntryType.expense,
        amount: Money(minorUnits: value, currency: account.currency),
        occurredAt: occurredAt,
        note: note.text.trim().isEmpty ? null : note.text.trim(),
        category: income ? 'دریافت' : 'عمومی',
      );
      await _refresh();
    } catch (error) {
      _logger.error(
        'Finance transaction creation failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (mounted) _showMessage('ثبت تراکنش انجام نشد؛ دوباره تلاش کنید.');
    } finally {
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

  String _money(Money money) =>
      '${_digits(money.minorUnits.abs())} ${money.currency}';

  String _digits(int value) => MoneyInputFormatter.format(value);

  List<AccountEntry> get _filteredEntries {
    final entries =
        _entries
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
    final currency = _accounts.isEmpty ? 'تومان' : _accounts.first.currency;
    final summary = cashFlowSummary(_entries, currency);
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
            Text('ورودی: ${_digits(summary.incoming)} $currency'),
            Text('خروجی: ${_digits(summary.outgoing)} $currency'),
            Text('خالص: ${_digits(summary.net.abs())} $currency'),
            const SizedBox(height: 8),
            const Text(
              'این گزارش فقط بر اساس تراکنش‌های ثبت‌شده روی دستگاه است.',
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.remove_circle_outline),
        label: const Text('ثبت هزینه'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummary(),
                  const SizedBox(height: 12),
                  _buildFilters(),
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
                        leading: const CircleAvatar(
                          child: Icon(Icons.account_balance_wallet),
                        ),
                        title: Text(account.name),
                        subtitle: Text(
                          account.status == FinancialAccountStatus.active
                              ? 'فعال'
                              : 'بایگانی‌شده',
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
                  if (_expectations != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'انتظارهای مالی',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text(
                          'انتظار مالی برای هر نوبت از بخش تعهد ثبت می‌شود.',
                        ),
                        subtitle: Text(
                          'مبلغ، ارز و حساب اختیاری هستند و بدون انتخاب شما ساخته نمی‌شوند.',
                        ),
                      ),
                    ),
                  ],
                  Text(
                    'آخرین تراکنش‌ها',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (_filteredEntries.isEmpty)
                    const Card(
                      child: ListTile(title: Text('هزینه‌ای ثبت نشده است.')),
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
                        subtitle: Text(
                          [
                            '${entry.occurredAt.toLocal().year}/${entry.occurredAt.toLocal().month}/${entry.occurredAt.toLocal().day}',
                            '${entry.occurredAt.toLocal().hour.toString().padLeft(2, '0')}:${entry.occurredAt.toLocal().minute.toString().padLeft(2, '0')}',
                            if (entry.category != null) entry.category!,
                            entry.note ?? 'بدون شرح',
                          ].join(' · '),
                        ),
                        trailing: PopupMenuButton<String>(
                          tooltip: 'عملیات تراکنش',
                          onSelected: (value) {
                            if (value == 'void') _voidEntry(entry);
                          },
                          itemBuilder: (context) => const [
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('ویرایش حساب'),
    content: TextField(
      controller: _name,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'نام حساب'),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('انصراف'),
      ),
      FilledButton(
        onPressed: () => Navigator.of(context).pop(_name.text.trim()),
        child: const Text('ذخیره'),
      ),
    ],
  );
}

class _FinanceJalaliDatePicker extends StatefulWidget {
  const _FinanceJalaliDatePicker({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_FinanceJalaliDatePicker> createState() =>
      _FinanceJalaliDatePickerState();
}

class _FinanceJalaliDatePickerState extends State<_FinanceJalaliDatePicker> {
  late JalaliDate _selected;
  late JalaliDate _month;

  @override
  void initState() {
    super.initState();
    _selected = JalaliDate.fromDateTime(widget.initialDate);
    _month = JalaliDate(_selected.year, _selected.month, 1);
  }

  void _changeMonth(int offset) {
    setState(() => _month = _month.addMonths(offset));
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekdayOffset = _month.weekDay - 1;
    final dayCount = _month.monthLength;
    final cellCount = firstWeekdayOffset + dayCount;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          IconButton(
            tooltip: 'ماه قبل',
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_right),
          ),
          Expanded(
            child: Center(
              child: Text(
                PersianDateFormatter.month(_month),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'ماه بعد',
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (final name in PersianDateFormatter.weekdayNames)
                    Expanded(
                      child: Center(
                        child: Text(
                          name.substring(0, 1),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cellCount,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemBuilder: (context, index) {
                  if (index < firstWeekdayOffset) return const SizedBox();
                  final day = index - firstWeekdayOffset + 1;
                  final date = JalaliDate(_month.year, _month.month, day);
                  final isSelected = date == _selected;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pop(date.toDateTime()),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: isSelected
                            ? BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              )
                            : null,
                        child: Text(
                          PersianNumbers.format(day),
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('انصراف'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
