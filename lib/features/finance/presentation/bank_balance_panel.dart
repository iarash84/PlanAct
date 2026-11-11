import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';

class BankBalancePanel extends StatefulWidget {
  const BankBalancePanel({
    super.key,
    required this.snapshot,
    required this.repository,
    required this.onChanged,
    required this.enabled,
  });
  final BankBalanceSnapshot snapshot;
  final BankBalanceRepository repository;
  final Future<void> Function() onChanged;
  final bool enabled;
  @override
  State<BankBalancePanel> createState() => _BankBalancePanelState();
}

class _BankBalancePanelState extends State<BankBalancePanel> {
  bool _busy = false;
  String _money(int amount) => PersianMoneyText.money(
    Money(minorUnits: amount, currency: 'IRR'),
    unit: MoneyUnitScope.of(context),
    isolateNumber: true,
  );
  String _time(DateTime value) {
    final local = value.toLocal();
    final date = JalaliDate.fromDateTime(local);
    return '${PersianDateFormatter.date(date)} ${PersianNumbers.format(date.year)} · ${PersianNumbers.format(local.hour.toString().padLeft(2, '0'))}:${PersianNumbers.format(local.minute.toString().padLeft(2, '0'))}';
  }

  Future<void> _review() async {
    final l10n = planActL10n(context);
    BankReconciliationReason? reason;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(l10n.bankBalanceReconcile),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.bankBalanceDisclosure),
                Text(_time(widget.snapshot.latest!.transactionTime!)),
                Text(
                  '${l10n.bankBalanceReported}: ${_money(widget.snapshot.latest!.irr)}',
                ),
                Text(
                  '${l10n.bankBalanceLedgerAtReport}: ${_money(widget.snapshot.ledgerAtReport)}',
                ),
                Text(
                  '${l10n.bankBalanceDifference}: ${_money(widget.snapshot.difference!)}',
                ),
                DropdownButton<BankReconciliationReason>(
                  isExpanded: true,
                  value: reason,
                  hint: Text(l10n.bankBalanceReconcile),
                  items: [
                    if (widget.snapshot.difference! < 0)
                      DropdownMenuItem(
                        value: BankReconciliationReason.knownFee,
                        child: Text(l10n.bankBalanceKnownFee),
                      ),
                    DropdownMenuItem(
                      value: BankReconciliationReason.unknownAdjustment,
                      child: Text(l10n.bankBalanceUnknownAdjustment),
                    ),
                  ],
                  onChanged: (value) => update(() => reason = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: reason == null
                  ? null
                  : () => Navigator.pop(context, true),
              child: Text(l10n.bankBalanceConfirm),
            ),
          ],
        ),
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => _busy = true);
    var saved = false;
    try {
      await widget.repository.reconcileBankBalance(widget.snapshot, reason!);
      saved = true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.bankBalanceFailure)));
      }
    }
    if (saved && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.bankBalanceSaved)));
      await widget.onChanged();
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final snapshot = widget.snapshot;
    if (snapshot.latest == null && !snapshot.ambiguous) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.bankBalanceReported,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (snapshot.latest case final observation?) ...[
          Text(_money(observation.irr)),
          Text(_time(observation.transactionTime!)),
        ],
        if (snapshot.ambiguous) Text(l10n.bankBalanceAmbiguous),
        if (snapshot.canReconcile)
          TextButton.icon(
            onPressed: _busy || !widget.enabled ? null : _review,
            icon: const Icon(Icons.balance_outlined),
            label: Text(l10n.bankBalanceReconcile),
          ),
        if (_busy) const LinearProgressIndicator(),
      ],
    );
  }
}
