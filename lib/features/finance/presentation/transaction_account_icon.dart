import 'package:flutter/material.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/account_identity_icon.dart';

/// Transaction cards use the same compact asset-aware identity treatment.
class TransactionAccountIcon extends StatelessWidget {
  const TransactionAccountIcon({super.key, required this.account});

  final FinancialAccount account;

  @override
  Widget build(BuildContext context) => AccountIdentityIcon(account: account);
}
