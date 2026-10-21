import 'package:planact/core/localization/planact_localizations.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/finance/domain/finance.dart';

String iranianBankLabel(BuildContext context, IranianBank bank) =>
    switch (bank) {
      IranianBank.ansar => planActL10n(context).iranianBankAnsar,
      IranianBank.mehrIran => planActL10n(context).iranianBankMehrIran,
      IranianBank.toseeTaavon => planActL10n(context).iranianBankToseeTaavon,
      IranianBank.sarmayeh => planActL10n(context).iranianBankSarmayeh,
      IranianBank.toseeSaderat => planActL10n(context).iranianBankToseeSaderat,
      IranianBank.postBank => planActL10n(context).iranianBankPostBank,
      IranianBank.khavarmianeh => planActL10n(context).iranianBankKhavarmianeh,
      IranianBank.hekmat => planActL10n(context).iranianBankHekmat,
      IranianBank.iranVenezuela => planActL10n(
        context,
      ).iranianBankIranVenezuela,
      IranianBank.resalat => planActL10n(context).iranianBankResalat,
      IranianBank.melal => planActL10n(context).iranianBankMelal,
      IranianBank.sanatMadan => planActL10n(context).iranianBankSanatMadan,
      _ => bank.label,
    };

/// Bank artwork is static presentation data; identity comes from the saved bank.
class AccountIdentityIcon extends StatelessWidget {
  const AccountIdentityIcon({super.key, required this.account});

  final FinancialAccount account;

  @override
  Widget build(BuildContext context) {
    final bank = account.bank;
    final fallback = Icon(
      account.type == FinancialAccountType.bank
          ? Icons.account_balance
          : Icons.account_balance_wallet,
    );
    if (bank == null) return fallback;
    return Image.asset(
      'assets/banks/${bank.code}.png',
      width: 32,
      height: 32,
      fit: BoxFit.contain,
      semanticLabel: planActL10n(
        context,
      ).accountIdentityIconBuildSemanticLabel(iranianBankLabel(context, bank)),
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}

class AccountIdentityLabel extends StatelessWidget {
  const AccountIdentityLabel({super.key, required this.account});

  final FinancialAccount account;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AccountIdentityIcon(account: account),
      const SizedBox(width: PlanActSpacing.sm),
      Expanded(child: Text(account.name)),
    ],
  );
}
