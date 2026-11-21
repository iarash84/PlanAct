import 'package:flutter/material.dart';
import 'package:planact/features/finance/presentation/bank_recovery_dialog.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/finance/domain/bank_balance.dart';
import 'package:planact/features/finance/domain/finance.dart';

class BankObservationReview extends StatefulWidget {
  const BankObservationReview({
    super.key,
    required this.observation,
    required this.repository,
    required this.accounts,
  });
  final BankBalanceObservation observation;
  final BankObservationReviewRepository repository;
  final List<FinancialAccount> accounts;
  @override
  State<BankObservationReview> createState() => _BankObservationReviewState();
}

class _BankObservationReviewState extends State<BankObservationReview> {
  late final _amount = TextEditingController(
    text: MoneyInputFormatter.format(widget.observation.sourceAmount),
  );
  late String _account = widget.observation.accountId;
  late String? _unit = widget.observation.sourceUnit;
  late DateTime? _time = widget.observation.transactionTime?.toLocal();
  late bool _active = widget.observation.active;
  bool _busy = false;
  String? _error;
  Set<String>? _recoveryAccounts;

  Future<void> _recover() async {
    final repository = widget.repository;
    if (repository is! BankRecoveryRepository) return;
    final recovered = await showBankRecovery(
      context,
      repository as BankRecoveryRepository,
      _recoveryAccounts!,
    );
    if (mounted && recovered) {
      setState(() {
        _recoveryAccounts = null;
        _error = planActL10n(context).bankRecoveryDone;
      });
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final date = await showDialog<DateTime>(
      context: context,
      builder: (_) =>
          PlanActJalaliDatePicker(initialDate: _time ?? DateTime.now()),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_time ?? DateTime.now()),
    );
    if (time == null || !mounted) return;
    setState(
      () => _time = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> _save() async {
    final l10n = planActL10n(context);
    final raw = PersianNumbers.normalizeDigits(_amount.text)
        .replaceAll(',', '')
        .replaceAll('٬', '');
    final amount = RegExp(r'^[0-9]+$').hasMatch(raw) ? int.tryParse(raw) : null;
    if (amount == null) {
      setState(() => _error = l10n.bankBalanceFailure);
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.bankEvidenceConfirm),
        content: Text(l10n.bankEvidenceDisclosure),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.bankEvidenceConfirm),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.reviewBankObservation(
        expected: widget.observation,
        accountId: _account,
        sourceAmount: amount,
        sourceUnit: _unit,
        transactionTime: _time,
        active: _active,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error is AppError ? error.message : l10n.bankBalanceFailure;
          _recoveryAccounts = error is BankRecoveryRequired
              ? error.accountIds
              : null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final accounts = widget.accounts
        .where(
          (a) =>
              a.currency == 'IRR' &&
              (a.status == FinancialAccountStatus.active ||
                  a.id.value == _account),
        )
        .toList();
    return AlertDialog(
      title: Text(l10n.bankEvidenceReview),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.bankEvidenceDisclosure),
            DropdownButton<String>(
              isExpanded: true,
              value: _account,
              items: [
                for (final a in accounts)
                  DropdownMenuItem(value: a.id.value, child: Text(a.name)),
              ],
              onChanged: _busy ? null : (v) => setState(() => _account = v!),
            ),
            TextField(
              controller: _amount,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: const [MoneyInputFormatter(decimal: true)],
              decoration: InputDecoration(labelText: l10n.bankEvidenceAmount),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: _unit ?? 'unknown',
              items: [
                DropdownMenuItem(
                  value: 'unknown',
                  child: Text(l10n.bankEvidenceUnknownUnit),
                ),
                DropdownMenuItem(value: 'rial', child: Text(l10n.currencyRial)),
                DropdownMenuItem(
                  value: 'toman',
                  child: Text(l10n.currencyToman),
                ),
              ],
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _unit = v == 'unknown' ? null : v),
            ),
            if (_time != null)
              Text(
                '${PersianDateFormatter.date(JalaliDate.fromDateTime(_time!))} ${PersianNumbers.format(JalaliDate.fromDateTime(_time!).year)} · ${PersianNumbers.format(_time!.hour.toString().padLeft(2, '0'))}:${PersianNumbers.format(_time!.minute.toString().padLeft(2, '0'))}',
              ),
            TextButton(
              onPressed: _busy ? null : _pickTime,
              child: Text(l10n.bankEvidenceDate),
            ),
            TextButton(
              onPressed: _busy ? null : () => setState(() => _time = null),
              child: Text(l10n.bankEvidenceClearTime),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.bankEvidenceActive),
              subtitle: !_active ? Text(l10n.bankEvidenceInactive) : null,
              value: _active,
              onChanged: _busy ? null : (v) => setState(() => _active = v),
            ),
            if (_error != null) Text(_error!, semanticsLabel: _error),
            if (_recoveryAccounts != null &&
                widget.repository is BankRecoveryRepository)
              TextButton(
                onPressed: _busy ? null : _recover,
                child: Text(l10n.bankRecoveryReview),
              ),
            if (_busy) const LinearProgressIndicator(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(l10n.bankEvidenceConfirm),
        ),
      ],
    );
  }
}
