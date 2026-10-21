import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/money/money_input_formatter.dart';
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
import 'package:planact/features/finance/presentation/account_identity_icon.dart';

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
              ? PersianCopy.accountFormSheetSaveMessage
              : PersianCopy.accountFormSheetSaveMessage2;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: PlanActFormSheet(
      title: widget.account == null
          ? planActL10n(context).accountFormSheetBuildTitle
          : planActL10n(context).accountFormSheetBuildTitle2,
      formKey: _form,
      primaryLabel: widget.account == null
          ? planActL10n(context).quickCaptureSheetBuildActions
          : planActL10n(context).commonSave,
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
            decoration: InputDecoration(
              labelText: planActL10n(context).accountFormSheetBuildLabelText,
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? planActL10n(context).accountFormSheetBuildValidator
                : null,
          ),
          const SizedBox(height: PlanActSpacing.md),
          DropdownButtonFormField<FinancialAccountType>(
            initialValue: _type,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: planActL10n(context).accountFormSheetBuildLabelText2,
            ),
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
              inputFormatters: const [MoneyInputFormatter(decimal: true)],
              decoration: InputDecoration(
                labelText: planActL10n(context).accountFormSheetBuildLabelText3,
                suffixText: _money!.unit.label,
              ),
              validator: (v) =>
                  (v ?? '').trim().isNotEmpty && _money!.parse(v!) == null
                  ? planActL10n(context).accountFormSheetBuildValidator2
                  : null,
            ),
          ],
          ExpansionTile(
            title: Text(planActL10n(context).accountFormSheetBuildTitle3),
            initiallyExpanded: widget.account != null,
            children: [
              Text(planActL10n(context).accountFormSheetBuildChildren),
              const SizedBox(height: PlanActSpacing.md),
              DropdownButtonFormField<IranianBank>(
                initialValue: _bank,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: planActL10n(context)
                      .accountFormSheetBuildLabelText4,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(planActL10n(context).commonNoSelection),
                  ),
                  ...IranianBank.values.map(
                    (bank) => DropdownMenuItem(
                      value: bank,
                      child: Text(iranianBankLabel(context, bank)),
                    ),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _bank = value),
              ),
              const SizedBox(height: PlanActSpacing.md),
              _identifier(
                _card,
                planActL10n(context).accountFormSheetBuildChildren2,
                'account-card',
                AccountIdentifiers.cardError,
              ),
              const SizedBox(height: PlanActSpacing.md),
              _identifier(
                _iban,
                planActL10n(context).accountFormSheetBuildChildren3,
                'account-iban',
                AccountIdentifiers.ibanError,
                iban: true,
              ),
              const SizedBox(height: PlanActSpacing.md),
              _identifier(
                _number,
                planActL10n(context).accountFormSheetBuildChildren4,
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
        tooltip: PersianCopy.accountFormSheetIdentifierTooltip3(
          (_revealed.contains(key)
                  ? PersianCopy.accountFormSheetIdentifierTooltip2
                  : PersianCopy.accountFormSheetIdentifierTooltip)
              .toString(),
          (label).toString(),
        ),
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
  FinancialAccountType.bank =>
    PersianCopy.accountFormSheetFinancialAccountTypeBank,
  FinancialAccountType.cash =>
    PersianCopy.accountFormSheetFinancialAccountTypeCash,
  FinancialAccountType.digitalWallet =>
    PersianCopy.accountFormSheetFinancialAccountTypeDigitalWallet,
  FinancialAccountType.credit =>
    PersianCopy.accountFormSheetFinancialAccountTypeCredit,
};
