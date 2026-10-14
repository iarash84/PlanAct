import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/features/finance/domain/account_identifiers.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/account_form_sheet.dart';
import 'package:planact/features/finance/presentation/account_identity_icon.dart';

/// A ledger account summary, deliberately not a payment-card representation.
class AccountInformationCard extends StatefulWidget {
  const AccountInformationCard({
    super.key,
    required this.account,
    required this.balance,
    required this.operations,
  });
  final FinancialAccount account;
  final Money balance;
  final Widget operations;
  @override
  State<AccountInformationCard> createState() => _AccountInformationCardState();
}

class _AccountInformationCardState extends State<AccountInformationCard>
    with WidgetsBindingObserver {
  final Set<String> _revealed = {};
  bool _copying = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(AccountInformationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.account.sameEditableFields(oldWidget.account)) {
      _revealed.clear();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _revealed.isNotEmpty) {
      setState(_revealed.clear);
    }
  }

  Future<void> _copy(String value) async {
    if (_copying) return;
    setState(() => _copying = true);
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('کپی اطلاعات حساب'),
        content: const Text(
          'این شناسه در کلیپ‌بورد دستگاه قرار می‌گیرد و ممکن است برنامه‌های دیگر یا همگام‌سازی دستگاه به آن دسترسی داشته باشند. ادامه می‌دهید؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('تأیید کپی'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (approved == true) {
      try {
        await Clipboard.setData(ClipboardData(text: value));
        if (mounted) {
          _message(
            'شناسه کپی شد؛ اطلاعات کلیپ‌بورد را پس از استفاده پاک کنید.',
          );
        }
      } catch (_) {
        if (mounted) _message('کپی انجام نشد؛ دوباره تلاش کنید.');
      }
    }
    if (mounted) setState(() => _copying = false);
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PlanActSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccountIdentityIcon(account: account),
                const SizedBox(width: PlanActSpacing.sm),
                Expanded(
                  child: Text(
                    account.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                widget.operations,
              ],
            ),
            Text(
              [
                accountTypeLabel(account.type),
                if (account.bank != null) 'بانک ${account.bank!.label}',
                if (account.status == FinancialAccountStatus.archived)
                  'بایگانی‌شده',
              ].join(' · '),
            ),
            const SizedBox(height: PlanActSpacing.sm),
            Text(
              'موجودی دفتر حساب',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              PersianMoneyText.money(
                widget.balance,
                unit: MoneyUnitScope.of(context),
              ),
            ),
            if (account.identifiers.cardNumber case final String value)
              _identifier('شماره کارت', value),
            if (account.identifiers.iban case final String value)
              _identifier('شماره شبا', value),
            if (account.identifiers.accountNumber case final String value)
              _identifier('شماره حساب', value),
          ],
        ),
      ),
    );
  }

  Widget _identifier(String label, String value) {
    final revealed = _revealed.contains(label);
    return Padding(
      padding: const EdgeInsets.only(top: PlanActSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(
            PersianNumbers.format(
              revealed ? value : AccountIdentifiers.masked(value),
            ),
            textDirection: TextDirection.ltr,
          ),
          Wrap(
            spacing: PlanActSpacing.sm,
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  if (revealed) {
                    _revealed.remove(label);
                  } else {
                    _revealed.add(label);
                  }
                }),
                icon: Icon(
                  revealed
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                label: Text('${revealed ? 'پنهان کردن' : 'نمایش'} $label'),
              ),
              TextButton.icon(
                onPressed: _copying ? null : () => _copy(value),
                icon: const Icon(Icons.copy_outlined),
                label: Text('کپی $label'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
