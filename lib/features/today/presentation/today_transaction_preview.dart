import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/today/application/attention_engine.dart';

/// Read-only review context; deliberately not a confirmed-ledger card.
class TodayTransactionPreview extends StatelessWidget {
  const TodayTransactionPreview({
    super.key,
    required this.item,
    required this.onReview,
  });

  final TodayActionItem item;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = planActL10n(context);
    final details = item.attentionItem;
    final draft = details?.inboxDraft;
    final inbox = item.type == TodayActionItemType.inboxReview;
    final incoming = draft != null
        ? draft.direction == TransactionDirection.incoming
        : details?.transactionType == AccountEntryType.income;
    final unknown = draft != null
        ? draft.direction == TransactionDirection.unknown
        : details?.transactionType == null;
    final title = inbox
        ? item.title
        : switch (details?.transactionType) {
            AccountEntryType.income =>
              l10n.transactionDirectionAccountEntryTypeIncome,
            AccountEntryType.expense =>
              l10n.transactionDirectionAccountEntryTypeExpense,
            _ => item.title,
          };
    String money(int value) => PersianMoneyText.amount(
      value,
      details?.currency ?? '',
      unit: MoneyUnitScope.of(context),
    );
    final evidence = draft?.currencyEvidence;
    final amount = draft != null
        ? evidence != null && evidence.requiresSelection
              ? l10n.inboxPageAmountMessage(
                  PersianMoneyText.amount(evidence.sourceAmount, '').trim(),
                )
              : PersianMoneyText.money(
                  draft.amount,
                  unit: MoneyUnitScope.of(context),
                )
        : details?.amountMinorUnits == null
        ? l10n.commonUnknown
        : money(details!.amountMinorUnits!);
    final description = (draft?.merchant ?? details?.description)?.trim();
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final metadata = <String>[];
    if (draft != null) {
      final bank = draft.bank?.trim();
      final sender = draft.sourceAddress?.trim();
      metadata.add(
        [
          if (bank != null && bank.isNotEmpty)
            bank
          else if (sender != null && sender.isNotEmpty)
            l10n.inboxPageSmsSenderLabel(sender),
        ].join(' · '),
      );
      final date = PersianDateFormatter.date(
        JalaliDate.fromDateTime(
          draft.occurredAt.isUtc
              ? draft.occurredAt.toLocal()
              : draft.occurredAt,
        ),
      );
      metadata.add(switch (draft.dateSource) {
        TransactionDateSource.extracted => date,
        TransactionDateSource.reviewer => l10n.todayTransactionReviewedDate(
          date,
        ),
        _ => l10n.todayTransactionDateNeedsReview,
      });
    } else {
      metadata.add(
        [
          details?.accountName ??
              l10n.transactionRelationshipPageBuildChildren3(
                l10n.commonUnknown,
              ),
          details?.bankName ??
              l10n.inboxPageBuildChildren12(l10n.commonUnknown),
        ].join(' · '),
      );
      final occurredAt = details?.occurredAt;
      final local = occurredAt?.isUtc == true
          ? occurredAt!.toLocal()
          : occurredAt;
      metadata.add(
        local == null
            ? l10n.todayRelationshipDate(l10n.commonUnknown)
            : '${PersianDateFormatter.date(JalaliDate.fromDateTime(local))} · ${PersianNumbers.format('${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}')}',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PlanActSpacing.md,
          vertical: PlanActSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PlanActSpacing.xs,
          children: [
            _PreviewHeader(
              title: title,
              amount: amount,
              remainder: inbox ? null : l10n.todayTransactionRemainder,
              total:
                  !inbox &&
                      details?.transactionTotalMinorUnits != null &&
                      details!.transactionTotalMinorUnits !=
                          details.amountMinorUnits
                  ? l10n.todayTransactionTotal(
                      money(details.transactionTotalMinorUnits!),
                    )
                  : null,
              icon: unknown
                  ? Icons.help_outline
                  : incoming
                  ? Icons.south_west
                  : Icons.north_east,
            ),
            for (final line in metadata.where((line) => line.isNotEmpty))
              Text(line, style: secondary),
            if (description != null && description.isNotEmpty)
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: PlanActSpacing.sm,
              children: [
                if (details != null && details.tags.isNotEmpty)
                  Wrap(
                    spacing: PlanActSpacing.sm,
                    runSpacing: PlanActSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TagLabels(labels: details.tags.take(2)),
                      if (details.tags.length > 2)
                        Text(
                          l10n.tagSelectionRemaining(
                            PersianNumbers.format(details.tags.length - 2),
                          ),
                          style: secondary,
                        ),
                    ],
                  ),
                if (inbox)
                  Text(l10n.todayTransactionUnconfirmed, style: secondary),
                TextButton(onPressed: onReview, child: Text(item.actionLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Measures the actual localized/scaled text, not a phone-width breakpoint.
class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({
    required this.title,
    required this.amount,
    required this.icon,
    this.remainder,
    this.total,
  });

  final String title;
  final String amount;
  final IconData icon;
  final String? remainder;
  final String? total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final iconSize = IconTheme.of(context).size ?? 24;
    double width(String text, TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: DefaultTextStyle.of(context).style.merge(style),
        ),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
      )..layout();
      final result = painter.width.ceilToDouble();
      painter.dispose();
      return result;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final titleWidth =
            iconSize +
            PlanActSpacing.sm +
            width(title, theme.textTheme.titleMedium);
        final moneyWidth = [
          width(amount, theme.textTheme.titleLarge),
          if (remainder != null) width(remainder!, secondary),
          if (total != null) width(total!, secondary),
        ].reduce((a, b) => a > b ? a : b);
        final fits =
            titleWidth + PlanActSpacing.md + moneyWidth <= constraints.maxWidth;
        final type = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: PlanActSpacing.sm),
            Flexible(child: Text(title, style: theme.textTheme.titleMedium)),
          ],
        );
        final money = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: fits
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (remainder != null) Text(remainder!, style: secondary),
            Text(amount, style: theme.textTheme.titleLarge),
            if (total != null) Text(total!, style: secondary),
          ],
        );
        if (!fits) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: PlanActSpacing.xs,
            children: [type, money],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: titleWidth, child: type),
            const Spacer(),
            SizedBox(width: moneyWidth, child: money),
          ],
        );
      },
    );
  }
}
