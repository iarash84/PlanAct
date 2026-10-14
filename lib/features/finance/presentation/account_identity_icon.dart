import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/finance/domain/finance.dart';

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
      semanticLabel: 'نشان بانک ${bank.label}',
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
