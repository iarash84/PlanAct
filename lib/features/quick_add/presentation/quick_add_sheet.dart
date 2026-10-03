import 'package:flutter/material.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/features/finance/domain/finance.dart';

/// The supported entry points exposed by the global add action.
enum QuickAddAction { expense, income, transfer, commitment }

class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  static Future<QuickAddAction?> show(BuildContext context) =>
      showModalBottomSheet<QuickAddAction>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => const QuickAddSheet(),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('افزودن سریع', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _ActionTile(
            key: const ValueKey('quick-add-expense'),
            icon: Icons.remove_circle_outline,
            title: 'هزینه',
            subtitle: 'ثبت سریع برداشت از یک حساب',
            onTap: () => Navigator.pop(context, QuickAddAction.expense),
          ),
          _ActionTile(
            key: const ValueKey('quick-add-income'),
            icon: Icons.add_circle_outline,
            title: 'درآمد',
            subtitle: 'ثبت سریع واریز به یک حساب',
            onTap: () => Navigator.pop(context, QuickAddAction.income),
          ),
          _ActionTile(
            key: const ValueKey('quick-add-transfer'),
            icon: Icons.swap_horiz,
            title: 'انتقال',
            subtitle: 'جابجایی بین حساب‌های خودتان',
            onTap: () => Navigator.pop(context, QuickAddAction.transfer),
          ),
          _ActionTile(
            key: const ValueKey('quick-add-commitment'),
            icon: Icons.add_task,
            title: 'تعهد',
            subtitle: 'باز کردن wizard ثبت تعهد',
            onTap: () => Navigator.pop(context, QuickAddAction.commitment),
          ),
        ],
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    onTap: onTap,
  );
}

class QuickFinancialEntrySheet extends StatefulWidget {
  const QuickFinancialEntrySheet({
    super.key,
    required this.accounts,
    required this.income,
  });
  final List<FinancialAccount> accounts;
  final bool income;

  @override
  State<QuickFinancialEntrySheet> createState() =>
      _QuickFinancialEntrySheetState();
}

class _QuickFinancialEntrySheetState extends State<QuickFinancialEntrySheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late FinancialAccount _account = widget.accounts.first;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(MoneyInputFormatter.normalize(_amount.text));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'مبلغ معتبر وارد کنید.');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    Navigator.pop(
      context,
      QuickFinancialEntry(
        account: _account,
        amount: amount,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        income: widget.income,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PlanActFormSheet(
    title: widget.income ? 'ثبت سریع درآمد' : 'ثبت سریع هزینه',
    primaryLabel: 'ثبت',
    onPrimary: _submit,
    isLoading: _saving,
    error: _error,
    primaryKey: const ValueKey('quick-financial-save'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const ValueKey('quick-financial-amount'),
          controller: _amount,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: const [MoneyInputFormatter()],
          decoration: const InputDecoration(labelText: 'مبلغ به تومان'),
        ),
        DropdownButtonFormField<FinancialAccount>(
          key: const ValueKey('quick-financial-account'),
          initialValue: _account,
          decoration: const InputDecoration(labelText: 'حساب'),
          items: widget.accounts
              .map(
                (account) =>
                    DropdownMenuItem(value: account, child: Text(account.name)),
              )
              .toList(),
          onChanged: (value) => setState(() => _account = value ?? _account),
        ),
        TextField(
          key: const ValueKey('quick-financial-note'),
          controller: _note,
          decoration: InputDecoration(
            labelText: widget.income
                ? 'شرح درآمد (اختیاری)'
                : 'یادداشت (اختیاری)',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: () =>
                Navigator.pop(context, const QuickFinancialEntry.moreOptions()),
            child: const Text('گزینه‌های بیشتر'),
          ),
        ),
      ],
    ),
  );
}

class QuickFinancialEntry {
  const QuickFinancialEntry({
    required this.account,
    required this.amount,
    required this.note,
    required this.income,
  }) : moreOptions = false;
  const QuickFinancialEntry.moreOptions()
    : account = null,
      amount = 0,
      note = null,
      income = false,
      moreOptions = true;
  final FinancialAccount? account;
  final int amount;
  final String? note;
  final bool income;
  final bool moreOptions;
}

class QuickTransferSheet extends StatefulWidget {
  const QuickTransferSheet({super.key, required this.accounts});
  final List<FinancialAccount> accounts;

  @override
  State<QuickTransferSheet> createState() => _QuickTransferSheetState();
}

class _QuickTransferSheetState extends State<QuickTransferSheet> {
  final _amount = TextEditingController();
  late FinancialAccount _from = widget.accounts.first;
  late FinancialAccount _to = widget.accounts.length > 1
      ? widget.accounts[1]
      : widget.accounts.first;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = int.tryParse(MoneyInputFormatter.normalize(_amount.text));
    if (amount == null || amount <= 0) {
      setState(() => _error = 'مبلغ معتبر وارد کنید.');
      return;
    }
    if (_from.id == _to.id) {
      setState(() => _error = 'حساب مبدأ و مقصد باید متفاوت باشند.');
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    Navigator.pop(context, QuickTransfer(from: _from, to: _to, amount: amount));
  }

  @override
  Widget build(BuildContext context) => PlanActFormSheet(
    title: 'ثبت سریع انتقال',
    primaryLabel: 'ثبت انتقال',
    onPrimary: _submit,
    isLoading: _saving,
    error: _error,
    primaryKey: const ValueKey('quick-transfer-save'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _amount,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: const [MoneyInputFormatter()],
          decoration: const InputDecoration(labelText: 'مبلغ به تومان'),
        ),
        DropdownButtonFormField<FinancialAccount>(
          initialValue: _from,
          decoration: const InputDecoration(labelText: 'از حساب'),
          items: widget.accounts
              .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
              .toList(),
          onChanged: (v) => setState(() => _from = v ?? _from),
        ),
        DropdownButtonFormField<FinancialAccount>(
          initialValue: _to,
          decoration: const InputDecoration(labelText: 'به حساب'),
          items: widget.accounts
              .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
              .toList(),
          onChanged: (v) => setState(() => _to = v ?? _to),
        ),
      ],
    ),
  );
}

class QuickTransfer {
  const QuickTransfer({
    required this.from,
    required this.to,
    required this.amount,
  });
  final FinancialAccount from;
  final FinancialAccount to;
  final int amount;
}
