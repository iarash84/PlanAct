import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/money/currency.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/account_identifiers.dart';
import 'package:planact/features/finance/domain/finance.dart';

Future<bool?> showAccountForm(
  BuildContext context,
  FinanceUseCases finance, {
  FinancialAccount? account,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: false,
  enableDrag: false,
  builder: (context) => AccountFormSheet(finance: finance, account: account),
);

class AccountFormSheet extends StatefulWidget {
  const AccountFormSheet({super.key, required this.finance, this.account});
  final FinanceUseCases finance;
  final FinancialAccount? account;
  @override
  State<AccountFormSheet> createState() => _AccountFormSheetState();
}

class _AccountFormSheetState extends State<AccountFormSheet>
    with WidgetsBindingObserver {
  final _revealed = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _revealed.isNotEmpty) {
      setState(_revealed.clear);
    }
  }

  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.account?.name);
  late final _card = TextEditingController(
    text: widget.account?.identifiers.cardNumber,
  );
  late final _iban = TextEditingController(
    text: widget.account?.identifiers.iban,
  );
  late final _number = TextEditingController(
    text: widget.account?.identifiers.accountNumber,
  );
  final _opening = TextEditingController();
  late final _id = widget.account?.id ?? StableId.generate();
  late FinancialAccountType _type =
      widget.account?.type ?? FinancialAccountType.cash;
  late IranianBank? _bank = widget.account?.bank;
  PinnedMoneyInput? _money;
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _money ??= PinnedMoneyInput(MoneyUnitScope.of(context));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in [_name, _card, _iban, _number, _opening]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final account = FinancialAccount(
        id: _id,
        name: _name.text.trim(),
        currency: widget.account?.currency ?? CurrencyCodes.irr,
        type: _type,
        bank: _bank,
        identifiers: AccountIdentifiers(
          cardNumber: _card.text,
          iban: _iban.text,
          accountNumber: _number.text,
        ),
      );
      if (widget.account case final FinancialAccount original) {
        await widget.finance.editAccount(
          original: original,
          replacement: account,
        );
      } else {
        final value = _money!.parse(_opening.text);
        await widget.finance.createAccount(
          account,
          openingBalance: value == null || value == 0
              ? null
              : Money(minorUnits: value, currency: account.currency),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = widget.account == null
              ? 'افزودن حساب انجام نشد؛ ورودی‌ها حفظ شدند. دوباره تلاش کنید.'
              : 'ویرایش انجام نشد؛ ممکن است حساب تغییر کرده باشد. دوباره تلاش کنید یا فرم را ببندید و از نو باز کنید.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: PlanActFormSheet(
      title: widget.account == null ? 'افزودن حساب' : 'ویرایش حساب',
      formKey: _form,
      primaryLabel: widget.account == null ? 'افزودن' : 'ذخیره',
      isLoading: _saving,
      error: _error,
      onPrimary: _save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _name,
            enabled: !_saving,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'نام حساب'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'نام حساب را وارد کنید.' : null,
          ),
          const SizedBox(height: PlanActSpacing.md),
          DropdownButtonFormField<FinancialAccountType>(
            initialValue: _type,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'نوع حساب'),
            items: FinancialAccountType.values
                .map(
                  (type) => DropdownMenuItem(
                    value: type,
                    child: Text(accountTypeLabel(type)),
                  ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _type = value!),
          ),
          if (widget.account == null) ...[
            const SizedBox(height: PlanActSpacing.md),
            TextFormField(
              controller: _opening,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: 'موجودی اولیه (اختیاری)',
                suffixText: _money!.unit.label,
              ),
              validator: (v) =>
                  (v ?? '').trim().isNotEmpty && _money!.parse(v!) == null
                  ? 'موجودی اولیه معتبر نیست.'
                  : null,
            ),
          ],
          ExpansionTile(
            title: const Text('جزئیات حساب (اختیاری)'),
            initiallyExpanded: widget.account != null,
            children: [
              const Text(
                'این اطلاعات فقط برای شناسایی حساب است؛ رمز، PIN یا CVV وارد نکنید.',
              ),
              const SizedBox(height: PlanActSpacing.md),
              DropdownButtonFormField<IranianBank>(
                initialValue: _bank,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'بانک (اختیاری)'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('بدون انتخاب'),
                  ),
                  ...IranianBank.values.map(
                    (bank) =>
                        DropdownMenuItem(value: bank, child: Text(bank.label)),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _bank = value),
              ),
              const SizedBox(height: PlanActSpacing.md),
              _identifier(
                _card,
                'شماره کارت (اختیاری)',
                'account-card',
                AccountIdentifiers.cardError,
              ),
              const SizedBox(height: PlanActSpacing.md),
              _identifier(
                _iban,
                'شماره شبا (اختیاری)',
                'account-iban',
                AccountIdentifiers.ibanError,
                iban: true,
              ),
              const SizedBox(height: PlanActSpacing.md),
              _identifier(
                _number,
                'شماره حساب (اختیاری)',
                'account-number',
                AccountIdentifiers.accountError,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _identifier(
    TextEditingController controller,
    String label,
    String key,
    String? Function(String?) validator, {
    bool iban = false,
  }) => TextFormField(
    key: ValueKey(key),
    controller: controller,
    enabled: !_saving,
    textDirection: TextDirection.ltr,
    autocorrect: false,
    enableSuggestions: false,
    obscureText: !_revealed.contains(key),
    keyboardType: iban ? TextInputType.text : TextInputType.number,
    decoration: InputDecoration(
      labelText: label,
      suffixIcon: IconButton(
        tooltip: '${_revealed.contains(key) ? 'پنهان کردن' : 'نمایش'} $label',
        onPressed: _saving
            ? null
            : () => setState(() {
                if (!_revealed.remove(key)) _revealed.add(key);
              }),
        icon: Icon(
          _revealed.contains(key)
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
      ),
    ),
    validator: validator,
  );
}

String accountTypeLabel(FinancialAccountType type) => switch (type) {
  FinancialAccountType.bank => 'بانکی',
  FinancialAccountType.cash => 'نقدی',
  FinancialAccountType.digitalWallet => 'کیف پول',
  FinancialAccountType.credit => 'اعتباری',
};
