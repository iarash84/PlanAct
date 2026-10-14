import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/features/finance/domain/finance.dart';

/// Direction follows the ledger sign, including signed corrections.
String transactionLabel(AccountEntry entry) => switch (entry.type) {
  AccountEntryType.income =>
    PersianCopy.transactionDirectionAccountEntryTypeIncome,
  AccountEntryType.expense =>
    PersianCopy.transactionDirectionAccountEntryTypeExpense,
  AccountEntryType.transferIn =>
    PersianCopy.transactionDirectionAccountEntryTypeTransferIn,
  AccountEntryType.transferOut =>
    PersianCopy.transactionDirectionAccountEntryTypeTransferOut,
  AccountEntryType.openingBalance =>
    PersianCopy.transactionDirectionAccountEntryTypeOpeningBalance,
  AccountEntryType.adjustment =>
    PersianCopy.transactionDirectionAccountEntryTypeAdjustment,
  AccountEntryType.refund =>
    PersianCopy.transactionDirectionAccountEntryTypeRefund,
  AccountEntryType.reversal =>
    PersianCopy.transactionDirectionAccountEntryTypeReversal,
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
        semanticLabel: planActL10n(context)
            .transactionDirectionBuildSemanticLabel3(
              (transactionLabel(entry)).toString(),
              (incoming
                      ? planActL10n(context)
                            .transactionDirectionBuildSemanticLabel2
                      : planActL10n(context)
                            .transactionDirectionBuildSemanticLabel)
                  .toString(),
            ),
      ),
    );
  }
}
