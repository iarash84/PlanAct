import 'package:planact/core/localization/planact_localizations.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_radius.dart';
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
///
/// Bundled bank artwork is an opaque square, so it is kept intact in a compact
/// soft-corner frame rather than placed inside a larger circular container.
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
    final theme = Theme.of(context);
    final icon = bank == null
        ? fallback
        : Image.asset(
            'assets/banks/${bank.code}.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
            semanticLabel: planActL10n(context)
                .accountIdentityIconBuildSemanticLabel(
                  iranianBankLabel(context, bank),
                ),
            errorBuilder: (context, error, stackTrace) => fallback,
          );
    return SizedBox(
      key: const ValueKey('account-identity-icon-frame'),
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bank == null
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.white,
          borderRadius: PlanActRadius.input,
        ),
        child: Center(child: icon),
      ),
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
