import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

String smsDirectionLabel(TransactionDirection direction) => switch (direction) {
  TransactionDirection.incoming =>
    PersianCopy.transactionDirectionAccountEntryTypeIncome,
  TransactionDirection.outgoing =>
    PersianCopy.transactionDirectionAccountEntryTypeExpense,
  TransactionDirection.unknown => PersianCopy.commonUnknown,
};

String maskedSmsEvidence(String? value) {
  if (value == null || value.isEmpty) return PersianCopy.commonUnknown;
  // Never reveal a complete short identifier either.
  return value.length <= 4
      ? '••••'
      : '•••• ${PersianNumbers.format(value.substring(value.length - 4))}';
}

String smsReviewTimestamp(DateTime value) =>
    '${PersianDateFormatter.date(JalaliDate.fromDateTime(value.toLocal()))} ${PersianNumbers.format(JalaliDate.fromDateTime(value.toLocal()).year)} · ${PersianNumbers.format('${value.toLocal().hour.toString().padLeft(2, '0')}:${value.toLocal().minute.toString().padLeft(2, '0')}:${value.toLocal().second.toString().padLeft(2, '0')}')}';

class SmsOriginalEvidence extends StatelessWidget {
  const SmsOriginalEvidence({super.key, required this.suggestion});
  final InboxSuggestion suggestion;
  @override
  Widget build(BuildContext context) {
    final evidence = suggestion.extractedEvidence;
    final original = evidence?.draft;
    String dateLabel() {
      final source = evidence?.sourceDate;
      if (source == null) return planActL10n(context).commonUnknown;
      if (!RegExp(r'^\d{4}[-/]\d{1,2}[-/]\d{1,2}$').hasMatch(source)) {
        return planActL10n(context).smsReviewEditorDateLabelMessage(
          (PersianNumbers.format(source)).toString(),
        );
      }
      final parts = source.split(RegExp('[-/]')).map(int.parse).toList();
      final date = parts.first < 1500
          ? JalaliDate(parts[0], parts[1], parts[2])
          : JalaliDate.fromDateTime(DateTime(parts[0], parts[1], parts[2]));
      return '${PersianDateFormatter.date(date)} ${PersianNumbers.format(date.year)}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          planActL10n(context).smsReviewEditorBuildChildren,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (original == null)
          Text(planActL10n(context).smsReviewEditorBuildChildren2)
        else ...[
          Text(
            planActL10n(context).smsReviewEditorBuildChildren4(
              (original.currencyEvidence == null
                      ? PersianMoneyText.money(
                          original.amount,
                          unit: MoneyUnitScope.of(context),
                        )
                      : planActL10n(context).accountFormSheetIdentifierTooltip3(
                          (PersianNumbers.format(
                            MoneyInputFormatter.groupText(
                              original.currencyEvidence!.sourceAmount
                                  .toString(),
                            ),
                          )).toString(),
                          (original.currencyEvidence!.effectiveUnit?.label ??
                                  planActL10n(context)
                                      .smsReviewEditorBuildChildren3)
                              .toString(),
                        ))
                  .toString(),
            ),
          ),
          Text(
            planActL10n(context).smsReviewEditorBuildChildren6(
              (evidence!.isTransfer
                      ? planActL10n(context).smsReviewEditorBuildChildren5
                      : smsDirectionLabel(original.direction))
                  .toString(),
            ),
          ),
          Text(
            planActL10n(context).smsReviewEditorBuildChildren7(
              (original.merchant ?? planActL10n(context).commonUnknown)
                  .toString(),
            ),
          ),
          Text(
            planActL10n(context).smsReviewEditorBuildChildren8(
              (original.bank ?? planActL10n(context).commonUnknown).toString(),
            ),
          ),
          Text(
            planActL10n(context).smsReviewEditorBuildChildren9(
              (maskedSmsEvidence(original.accountHint)).toString(),
            ),
          ),
          Text(
            planActL10n(context).smsReviewEditorBuildChildren10(
              (maskedSmsEvidence(original.reference)).toString(),
            ),
          ),
          Text(
            planActL10n(context)
                .smsReviewEditorBuildChildren11((dateLabel()).toString()),
          ),
          Text(
            planActL10n(context).smsReviewEditorBuildChildren12(
              (evidence.sourceTime == null
                      ? planActL10n(context).commonUnknown
                      : PersianNumbers.format(evidence.sourceTime!))
                  .toString(),
            ),
          ),
          Text(
            planActL10n(context).smsReviewEditorBuildChildren13(
              (original.receivedAt == null
                      ? planActL10n(context).commonUnknown
                      : smsReviewTimestamp(original.receivedAt!))
                  .toString(),
            ),
          ),
        ],
      ],
    );
  }
}

class SmsReviewEditor extends StatefulWidget {
  const SmsReviewEditor({
    super.key,
    required this.suggestion,
    required this.inbox,
  });
  final InboxSuggestion suggestion;
  final InboxUseCases inbox;
  @override
  State<SmsReviewEditor> createState() => _SmsReviewEditorState();
}

class _SmsReviewEditorState extends State<SmsReviewEditor> {
  late final _draft = widget.suggestion.draft;
  late final TextEditingController _amount;
  late final TextEditingController _merchant;
  late final TextEditingController _reference;
  late final TextEditingController _bank;
  late final TextEditingController _hint;
  late SmsMoneyUnit? _unit;
  late TransactionDirection _direction;
  late IranianMoneyUnit _legacyUnit;
  DateTime? _date;
  TimeOfDay? _time;
  int _seconds = 0;
  bool _dateEdited = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _unit = _draft.currencyEvidence?.effectiveUnit;
    _direction = _draft.direction;
    _merchant = TextEditingController(text: _draft.merchant ?? '');
    _reference = TextEditingController(text: _draft.reference ?? '');
    _bank = TextEditingController(text: _draft.bank ?? '');
    _hint = TextEditingController(text: _draft.accountHint ?? '');
    final original = widget.suggestion.extractedEvidence;
    if (_draft.dateSource == TransactionDateSource.reviewer ||
        _draft.dateSource == TransactionDateSource.extracted) {
      final value = _draft.occurredAt.toLocal();
      _date = value;
      _time = TimeOfDay.fromDateTime(value);
      _seconds = value.second;
    } else {
      final source = original?.sourceDate;
      if (source != null &&
          RegExp(r'^\d{4}[-/]\d{1,2}[-/]\d{1,2}$').hasMatch(source)) {
        final p = source.split(RegExp('[-/]')).map(int.parse).toList();
        _date = p.first < 1500
            ? JalaliDate(p[0], p[1], p[2]).toDateTime()
            : DateTime(p[0], p[1], p[2]);
      }
      final sourceTime = original?.sourceTime;
      if (sourceTime != null) {
        final p = sourceTime.split(':').map(int.parse).toList();
        _time = TimeOfDay(hour: p[0], minute: p[1]);
        _seconds = p.length > 2 ? p[2] : 0;
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _legacyUnit = _draft.amount.currency == 'IRR'
          ? MoneyUnitScope.of(context)
          : IranianMoneyUnit.rial;
      if (_draft.currencyEvidence?.requiresSelection == true) {
        _unit = _legacyUnit == IranianMoneyUnit.toman
            ? SmsMoneyUnit.toman
            : SmsMoneyUnit.rial;
      }
      _amount = TextEditingController(
        text: MoneyInputFormatter.groupText(
          _draft.currencyEvidence == null
              ? _legacyUnit.inputText(_draft.amount.minorUnits)
              : _draft.currencyEvidence!.requiresSelection
              ? _draft.currencyEvidence!.sourceAmount.toString()
              : (_unit == SmsMoneyUnit.toman
                        ? IranianMoneyUnit.toman
                        : IranianMoneyUnit.rial)
                    .inputText(_draft.amount.minorUnits),
        ),
      );
      _initialized = true;
    }
  }

  bool _initialized = false;
  @override
  void dispose() {
    for (final c in [_amount, _merchant, _reference, _bank, _hint]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final currency = _draft.currencyEvidence;
    final unit = currency == null
        ? _legacyUnit
        : _unit == SmsMoneyUnit.toman
        ? IranianMoneyUnit.toman
        : IranianMoneyUnit.rial;
    final amount = unit.parse(_amount.text);
    if (currency != null && _unit == null) {
      setState(() => _error = PersianCopy.smsReviewEditorSaveMessage);
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = PersianCopy.smsReviewEditorSaveMessage2);
      return;
    }
    // The current draft requires a complete timestamp. Partial source evidence
    // stays immutable; editing a timestamp never synthesizes its missing part.
    if (_dateEdited && (_date == null || _time == null)) {
      setState(() => _error = PersianCopy.smsReviewEditorSaveMessage3);
      return;
    }
    int? reviewedAmount;
    if (currency != null) {
      final divisor = _unit == SmsMoneyUnit.toman ? 10 : 1;
      if (amount % divisor != 0) {
        setState(() => _error = PersianCopy.smsReviewEditorSaveMessage4);
        return;
      }
      reviewedAmount = amount ~/ divisor;
    }
    String? optional(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final edited = TransactionDraft(
      id: _draft.id,
      stagedImportId: _draft.stagedImportId,
      amount: Money(minorUnits: amount, currency: _draft.amount.currency),
      currencyEvidence: currency == null
          ? null
          : SmsCurrencyEvidence(
              sourceAmount: reviewedAmount!,
              detectedUnit: currency.detectedUnit,
              selectedUnit: _unit,
            ),
      occurredAt: _dateEdited
          ? DateTime(
              _date!.year,
              _date!.month,
              _date!.day,
              _time!.hour,
              _time!.minute,
              _seconds,
            )
          : _draft.occurredAt,
      type: _direction == TransactionDirection.unknown
          ? 'unknown'
          : _direction == TransactionDirection.incoming
          ? 'income'
          : 'expense',
      merchant: optional(_merchant),
      reference: optional(_reference),
      bank: optional(_bank),
      accountHint: optional(_hint),
      direction: _direction,
      balance: _draft.balance,
      quality: _draft.quality,
      confidence: _draft.confidence,
      dateSource: _dateEdited
          ? TransactionDateSource.reviewer
          : _draft.dateSource,
      receivedAt: _draft.receivedAt,
    );
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.inbox.edit(widget.suggestion, edited);
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = PersianCopy.smsReviewEditorSaveMessage5;
        });
      }
    }
  }

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: PlanActSpacing.sm),
    child: TextField(
      controller: controller,
      inputFormatters: controller == _amount
          ? const [MoneyInputFormatter(decimal: true)]
          : null,
      enabled: !_saving,
      decoration: InputDecoration(labelText: label),
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: PlanActFormSheet(
      title: planActL10n(context).smsReviewEditorBuildTitle,
      primaryLabel: planActL10n(context).smsReviewEditorBuildPrimaryLabel,
      onPrimary: _save,
      isLoading: _saving,
      error: _error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SmsOriginalEvidence(suggestion: widget.suggestion),
          const SizedBox(height: PlanActSpacing.md),
          Text(planActL10n(context).smsReviewEditorBuildChildren14),
          _field(
            _amount,
            _draft.currencyEvidence == null
                ? planActL10n(
                    context,
                  ).financePageResultLabelText((_legacyUnit.label).toString())
                : planActL10n(context).smsReviewEditorBuildChildren15,
          ),
          if (_draft.currencyEvidence != null)
            DropdownButtonFormField<SmsMoneyUnit>(
              initialValue: _unit,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: planActL10n(context).smsReviewEditorBuildLabelText,
              ),
              items: [
                for (final u in SmsMoneyUnit.values)
                  DropdownMenuItem(value: u, child: Text(u.label)),
              ],
              onChanged: _saving ? null : (v) => setState(() => _unit = v),
            )
          else
            Text(planActL10n(context).smsReviewEditorBuildChildren16),
          if (_draft.currencyEvidence?.requiresSelection == true)
            Text(planActL10n(context).inboxDefaultUnitEditorNotice),
          _field(
            _merchant,
            planActL10n(context).smsReviewEditorBuildChildren17,
          ),
          _field(
            _reference,
            planActL10n(context).smsReviewEditorBuildChildren18,
          ),
          _field(_bank, planActL10n(context).smsReviewEditorBuildChildren19),
          _field(_hint, planActL10n(context).smsReviewEditorBuildChildren20),
          DropdownButtonFormField<TransactionDirection>(
            initialValue: _direction,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: planActL10n(context).smsReviewEditorBuildLabelText2,
            ),
            items: [
              for (final d in TransactionDirection.values)
                DropdownMenuItem(value: d, child: Text(smsDirectionLabel(d))),
            ],
            onChanged: _saving ? null : (v) => setState(() => _direction = v!),
          ),
          Text(planActL10n(context).smsReviewEditorBuildChildren21),
          if (widget.suggestion.extractedEvidence?.isTransfer == true)
            Text(planActL10n(context).smsReviewEditorBuildChildren22),
          if (_draft.dateSource == TransactionDateSource.receipt)
            Text(
              planActL10n(context).smsReviewEditorBuildChildren23(
                (smsReviewTimestamp(_draft.occurredAt)).toString(),
              ),
            ),
          TextButton.icon(
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              _date == null
                  ? planActL10n(context).smsReviewEditorBuildLabel
                  : planActL10n(context).smsReviewEditorBuildLabel2(
                      (PersianDateFormatter.date(
                        JalaliDate.fromDateTime(_date!),
                      )).toString(),
                    ),
            ),
            onPressed: _saving
                ? null
                : () async {
                    final result = await showDialog<DateTime>(
                      context: context,
                      builder: (_) => PlanActJalaliDatePicker(
                        initialDate: _date ?? _draft.occurredAt.toLocal(),
                      ),
                    );
                    if (result != null && mounted) {
                      setState(() {
                        _date = result;
                        _dateEdited = true;
                      });
                    }
                  },
          ),
          TextButton.icon(
            icon: const Icon(Icons.schedule),
            label: Text(
              _time == null
                  ? planActL10n(context).smsReviewEditorBuildLabel3
                  : planActL10n(context).smsReviewEditorBuildLabel4(
                      (PersianNumbers.format(
                        '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
                      )).toString(),
                    ),
            ),
            onPressed: _saving
                ? null
                : () async {
                    final result = await showTimePicker(
                      context: context,
                      initialTime:
                          _time ??
                          TimeOfDay.fromDateTime(_draft.occurredAt.toLocal()),
                      cancelText: planActL10n(context).commonCancel,
                      confirmText: planActL10n(context)
                          .smsReviewEditorResultConfirmText,
                      helpText: planActL10n(context)
                          .smsReviewEditorResultHelpText,
                    );
                    if (result != null && mounted) {
                      setState(() {
                        _time = result;
                        _seconds = 0;
                        _dateEdited = true;
                      });
                    }
                  },
          ),
        ],
      ),
    ),
  );
}
