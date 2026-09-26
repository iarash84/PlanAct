import 'package:flutter/material.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key, required this.repository});

  final FinanceRepository repository;

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late final FinanceUseCases _finance = FinanceUseCases(widget.repository);
  List<FinancialAccount> _accounts = const [];
  List<AccountEntry> _entries = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final accounts = await widget.repository.listAccounts();
    final entries = await widget.repository.listEntries();
    if (mounted) {
      setState(() {
        _accounts = accounts;
        _entries = entries;
        _loading = false;
      });
    }
  }

  Future<void> _addAccount() async {
    final name = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('افزودن حساب'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'نام حساب'),
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
    name.dispose();
    if (result == null || result.isEmpty) return;
    await _finance.createAccount(
      FinancialAccount(
        id: StableId.generate(),
        name: result,
        currency: 'تومان',
        type: FinancialAccountType.cash,
      ),
    );
    await _refresh();
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
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.name),
                        ))
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
    );
    amount.dispose();
    note.dispose();
    await _refresh();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _money(Money money) => '${_digits(money.minorUnits.abs())} ${money.currency}';

  String _digits(int value) => value.toString().replaceAllMapped(
        RegExp(r'(?<=\d)(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );

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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('حساب‌ها', style: Theme.of(context).textTheme.titleLarge),
                      IconButton(
                        onPressed: _addAccount,
                        tooltip: 'افزودن حساب',
                        icon: const Icon(Icons.add_card),
                      ),
                    ],
                  ),
                  if (_accounts.isEmpty)
                    const Card(child: ListTile(title: Text('هنوز حسابی ثبت نشده است.'))),
                  for (final account in _accounts)
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.account_balance_wallet)),
                        title: Text(account.name),
                        subtitle: Text(account.status == FinancialAccountStatus.active ? 'فعال' : 'بایگانی‌شده'),
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
                  Text('آخرین هزینه‌ها', style: Theme.of(context).textTheme.titleLarge),
                  if (_entries.where((entry) => entry.type == AccountEntryType.expense).isEmpty)
                    const Card(child: ListTile(title: Text('هزینه‌ای ثبت نشده است.'))),
                  for (final entry in _entries
                      .where((entry) => entry.type == AccountEntryType.expense)
                      .toList()
                    ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)))
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.remove_circle_outline),
                        title: Text(_money(entry.amount)),
                        subtitle: Text(entry.note ?? 'بدون شرح'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
