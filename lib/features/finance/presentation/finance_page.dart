import 'package:flutter/material.dart';
import 'package:planact/core/ids/stable_id.dart';
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
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
        _showMessage('بارگذاری اطلاعات مالی انجام نشد. دوباره تلاش کنید.');
      }
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
    } catch (_) {
      if (mounted) _showMessage('افزودن حساب انجام نشد. دوباره تلاش کنید.');
    } finally {
      name.dispose();
      opening.dispose();
    }
  }

  Future<void> _addExpense() async {
    if (_accounts.isEmpty) {
      _showMessage('ابتدا یک حساب اضافه کنید.');
      return;
    }
    final amount = TextEditingController();
    final note = TextEditingController();
    var account = _accounts.first;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('ثبت هزینه'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<FinancialAccount>(
                initialValue: account,
                decoration: const InputDecoration(labelText: 'حساب'),
                items: _accounts
                    .map(
                      (item) =>
                          DropdownMenuItem(value: item, child: Text(item.name)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => account = value);
                },
              ),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'مبلغ به تومان'),
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'شرح هزینه'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ثبت'),
            ),
          ],
        ),
      ),
    );
    final value = int.tryParse(amount.text.replaceAll(',', '').trim());
    if (result != true || value == null || value <= 0) {
      amount.dispose();
      note.dispose();
      if (result == true) _showMessage('مبلغ معتبر وارد کنید.');
      return;
    }
    await _finance.record(
      account: account,
      type: AccountEntryType.expense,
      amount: Money(minorUnits: value, currency: account.currency),
      occurredAt: DateTime.now(),
      note: note.text.trim().isEmpty ? null : note.text.trim(),
      category: 'عمومی',
    );
    amount.dispose();
    note.dispose();
    await _refresh();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _money(Money money) =>
      '${_digits(money.minorUnits.abs())} ${money.currency}';

  String _digits(int value) => value.toString().replaceAllMapped(
    RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );

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
        icon: const Icon(Icons.add),
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
                      IconButton(
                        onPressed: _addAccount,
                        tooltip: 'افزودن حساب',
                        icon: const Icon(Icons.add_card),
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
                        trailing: FutureBuilder<Money>(
                          future: _finance.balance(account),
                          builder: (context, snapshot) => Text(
                            snapshot.hasData ? _money(snapshot.data!) : '—',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
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
                        ),
                        title: Text(_money(entry.amount)),
                        subtitle: Text(
                          [
                            if (entry.category != null) entry.category!,
                            entry.note ?? 'بدون شرح',
                          ].join(' · '),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
