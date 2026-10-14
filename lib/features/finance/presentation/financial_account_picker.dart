import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/account_identity_icon.dart';

/// Reads durable accounts without choosing one on the user's behalf.
class FinancialAccountPicker extends StatefulWidget {
  const FinancialAccountPicker({
    super.key,
    required this.repository,
    required this.onChanged,
    required this.onCreateAccount,
    this.currency,
    this.enabled = true,
  });

  final FinanceRepository repository;
  final String? currency;
  final bool enabled;
  final ValueChanged<FinancialAccount?> onChanged;
  final Future<void> Function() onCreateAccount;

  @override
  State<FinancialAccountPicker> createState() => _FinancialAccountPickerState();
}

class _FinancialAccountPickerState extends State<FinancialAccountPicker> {
  List<FinancialAccount> _accounts = [];
  FinancialAccount? _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final accounts = await widget.repository.listAccounts();
      if (!mounted) return;
      final usable = accounts
          .where(
            (account) =>
                account.status == FinancialAccountStatus.active &&
                (widget.currency == null ||
                    account.currency == widget.currency),
          )
          .toList();
      final selected = usable.where((a) => a.id == _selected?.id).firstOrNull;
      setState(() {
        _accounts = usable;
        _selected = selected;
        _loading = false;
      });
      widget.onChanged(selected);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'خواندن حساب‌ها انجام نشد؛ دوباره تلاش کنید.';
      });
      widget.onChanged(null);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_loading) ...[
        const LinearProgressIndicator(),
        const Text('در حال بارگذاری حساب‌ها…'),
      ] else if (_error != null) ...[
        Text(_error!),
        TextButton(
          onPressed: widget.enabled ? _load : null,
          child: const Text('تلاش دوباره'),
        ),
      ] else if (_accounts.isEmpty)
        const Text('حساب فعال سازگار پیدا نشد. برای ثبت، حساب بسازید.')
      else
        DropdownButtonFormField<FinancialAccount>(
          key: ValueKey(_selected?.id),
          initialValue: _selected,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'حساب مالی',
            hintText: 'حساب را انتخاب کنید',
          ),
          items: _accounts
              .map(
                (account) => DropdownMenuItem(
                  value: account,
                  child: AccountIdentityLabel(account: account),
                ),
              )
              .toList(),
          onChanged: widget.enabled
              ? (value) {
                  setState(() => _selected = value);
                  widget.onChanged(value);
                }
              : null,
        ),
      const SizedBox(height: PlanActSpacing.sm),
      if (!_loading && _error == null)
        TextButton.icon(
          onPressed: widget.enabled ? _load : null,
          icon: const Icon(Icons.refresh),
          label: const Text('تازه‌سازی حساب‌ها'),
        ),
      TextButton.icon(
        onPressed: widget.enabled && !_loading
            ? () async {
                await widget.onCreateAccount();
                if (mounted) await _load();
              }
            : null,
        icon: const Icon(Icons.account_balance_wallet_outlined),
        label: const Text('ساخت حساب'),
      ),
    ],
  );
}
