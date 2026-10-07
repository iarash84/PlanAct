import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/features/finance/domain/finance.dart';

/// Direction follows the ledger sign, including signed corrections.
String transactionLabel(AccountEntry entry) => switch (entry.type) {
  AccountEntryType.income => 'واریز',
  AccountEntryType.expense => 'برداشت',
  AccountEntryType.transferIn => 'انتقال ورودی',
  AccountEntryType.transferOut => 'انتقال خروجی',
  AccountEntryType.openingBalance => 'موجودی اولیه',
  AccountEntryType.adjustment => 'اصلاح موجودی',
  AccountEntryType.refund => 'بازپرداخت',
  AccountEntryType.reversal => 'ثبت جبرانی',
};

class TransactionDirectionIcon extends StatelessWidget {
  const TransactionDirectionIcon({super.key, required this.entry});

  final AccountEntry entry;

  @override
  Widget build(BuildContext context) {
    final incoming = entry.signedAmount.minorUnits > 0;
    final colors = PlanActStatusColors.of(context);
    return CircleAvatar(
      backgroundColor: incoming
          ? colors.successContainer
          : colors.attentionContainer,
      child: Icon(
        incoming ? Icons.south_west : Icons.north_east,
        color: incoming ? colors.success : colors.attention,
        semanticLabel:
            '${transactionLabel(entry)}؛ ${incoming ? 'ورودی به حساب' : 'خروجی از حساب'}',
      ),
    );
  }
}
