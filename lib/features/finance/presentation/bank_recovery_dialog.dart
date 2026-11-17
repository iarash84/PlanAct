import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';

/// Never retries the caller's command. The retained form remains authoritative.
Future<bool> showBankRecovery(
  BuildContext context,
  BankRecoveryRepository repository,
  Set<String> accountIds,
) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            _BankRecoveryDialog(repository: repository, accountIds: accountIds),
      ) ??
      false;
}

class _BankRecoveryDialog extends StatefulWidget {
  const _BankRecoveryDialog({
    required this.repository,
    required this.accountIds,
  });
  final BankRecoveryRepository repository;
  final Set<String> accountIds;
  @override
  State<_BankRecoveryDialog> createState() => _BankRecoveryDialogState();
}

class _BankRecoveryDialogState extends State<_BankRecoveryDialog> {
  BankRecoveryPreview? _preview;
  bool _busy = true;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _failed = false;
      _preview = null;
    });
    try {
      final preview = await widget.repository.previewBankRecovery(
        widget.accountIds,
      );
      if (mounted) setState(() => _preview = preview);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final preview = _preview!;
    setState(() => _busy = true);
    try {
      await widget.repository.recoverBankReconciliations(preview);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      // Discard stale consent: retry must load and display a new preview.
      if (mounted) {
        setState(() {
          _failed = true;
          _preview = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final preview = _preview;
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(l10n.bankRecoveryTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.bankRecoveryDisclosure),
              if (_busy) const LinearProgressIndicator(),
              if (_failed) Text(l10n.bankBalanceFailure),
              if (preview != null) ...[
                for (final account in preview.accounts) Text(account.name),
                if (preview.decisions.isEmpty) Text(l10n.bankRecoveryEmpty),
                for (final decision in preview.decisions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      preview.accounts
                          .singleWhere((a) => a.id == decision.entry.accountId)
                          .name,
                    ),
                    subtitle: Text(
                      [
                        PersianDateFormatter.date(
                          JalaliDate.fromDateTime(decision.through.toLocal()),
                        ),
                        PersianNumbers.format(
                          JalaliDate.fromDateTime(decision.through.toLocal())
                              .year,
                        ),
                        '${PersianNumbers.format(decision.through.toLocal().hour.toString().padLeft(2, '0'))}:${PersianNumbers.format(decision.through.toLocal().minute.toString().padLeft(2, '0'))}',
                        decision.reason == BankReconciliationReason.knownFee
                            ? l10n.bankBalanceKnownFee
                            : l10n.bankBalanceUnknownAdjustment,
                        PersianMoneyText.money(
                          Money(
                            minorUnits: -decision.entry.signedAmount.minorUnits,
                            currency: 'IRR',
                          ),
                          unit: MoneyUnitScope.of(context),
                          isolateNumber: true,
                        ),
                        '${l10n.bankRecoverySource}: ${decision.observationId}',
                        '${l10n.bankRecoveryEntry}: ${decision.entry.id.value}',
                      ].join('\n'),
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          if (_failed)
            TextButton(
              onPressed: _busy ? null : _load,
              child: Text(l10n.bankRecoveryTitle),
            ),
          FilledButton(
            onPressed: _busy || preview == null || preview.decisions.isEmpty
                ? null
                : _confirm,
            child: Text(l10n.bankRecoveryTitle),
          ),
        ],
      ),
    );
  }
}
