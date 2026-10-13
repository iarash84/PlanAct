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
  TransactionDirection.incoming => 'واریز',
  TransactionDirection.outgoing => 'برداشت',
  TransactionDirection.unknown => 'نامشخص',
};

String maskedSmsEvidence(String? value) {
  if (value == null || value.isEmpty) return 'نامشخص';
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
      if (source == null) return 'نامشخص';
      if (!RegExp(r'^\d{4}[-/]\d{1,2}[-/]\d{1,2}$').hasMatch(source)) {
        return '${PersianNumbers.format(source)} (سال نامشخص)';
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
          'شواهد اصلی پیامک (بدون تغییر)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (original == null)
          const Text('شواهد اصلی پیامک قدیمی در دسترس نیست.')
        else ...[
          Text(
            'مبلغ اصلی: ${original.currencyEvidence == null ? PersianMoneyText.money(original.amount, unit: MoneyUnitScope.of(context)) : '${PersianNumbers.format(original.currencyEvidence!.sourceAmount)} ${original.currencyEvidence!.effectiveUnit?.label ?? 'واحد نامشخص'}'}',
          ),
          Text(
            'جهت پیامک: ${evidence!.isTransfer ? 'انتقال' : smsDirectionLabel(original.direction)}',
          ),
          Text('شرح اصلی: ${original.merchant ?? 'نامشخص'}'),
          Text('بانک اصلی: ${original.bank ?? 'نامشخص'}'),
          Text('راهنمای حساب اصلی: ${maskedSmsEvidence(original.accountHint)}'),
          Text('پیگیری اصلی: ${maskedSmsEvidence(original.reference)}'),
          Text('تاریخ پیامک: ${dateLabel()}'),
          Text(
            'ساعت پیامک: ${evidence.sourceTime == null ? 'نامشخص' : PersianNumbers.format(evidence.sourceTime!)}',
          ),
          Text(
            'زمان دریافت پیامک: ${original.receivedAt == null ? 'نامشخص' : smsReviewTimestamp(original.receivedAt!)}',
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
      _amount = TextEditingController(
        text: _draft.currencyEvidence == null
            ? _legacyUnit.inputText(_draft.amount.minorUnits)
            : _unit == null
            ? _draft.currencyEvidence!.sourceAmount.toString()
            : (_unit == SmsMoneyUnit.toman
                      ? IranianMoneyUnit.toman
                      : IranianMoneyUnit.rial)
                  .inputText(_draft.amount.minorUnits),
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
      setState(
        () => _error = 'واحد مبلغ نامشخص است؛ ریال یا تومان را انتخاب کنید.',
      );
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = 'مبلغ باید معتبر و بزرگ‌تر از صفر باشد.');
      return;
    }
    // The current draft requires a complete timestamp. Partial source evidence
    // stays immutable; editing a timestamp never synthesizes its missing part.
    if (_dateEdited && (_date == null || _time == null)) {
      setState(
        () => _error =
            'برای تغییر زمان تراکنش، تاریخ و ساعت را صریحاً انتخاب کنید.',
      );
      return;
    }
    int? reviewedAmount;
    if (currency != null) {
      final divisor = _unit == SmsMoneyUnit.toman ? 10 : 1;
      if (amount % divisor != 0) {
        setState(
          () => _error = 'مبلغ پیامک باید در واحد انتخابی عدد صحیح باشد؛ برای باقی‌ماندهٔ ریالی، ریال را انتخاب کنید.',
        );
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
          _error = 'ذخیره انجام نشد؛ مقادیر فرم حفظ شده‌اند. دوباره تلاش کنید.';
        });
      }
    }
  }

  Widget _field(TextEditingController controller, String label) => Padding(
    padding: const EdgeInsets.only(bottom: PlanActSpacing.sm),
    child: TextField(
      controller: controller,
      enabled: !_saving,
      decoration: InputDecoration(labelText: label),
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: PlanActFormSheet(
      title: 'ویرایش پیشنهاد تراکنش',
      primaryLabel: 'ذخیره و بررسی',
      onPrimary: _save,
      isLoading: _saving,
      error: _error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SmsOriginalEvidence(suggestion: widget.suggestion),
          const SizedBox(height: PlanActSpacing.md),
          const Text(
            'مقادیر بررسی‌شدهٔ شما؛ ذخیرهٔ ویرایش هنوز تراکنش مالی ثبت نمی‌کند.',
          ),
          _field(
            _amount,
            _draft.currencyEvidence == null
                ? 'مبلغ به ${_legacyUnit.label}'
                : 'مبلغ (واحد انتخابی)',
          ),
          if (_draft.currencyEvidence != null)
            DropdownButtonFormField<SmsMoneyUnit>(
              initialValue: _unit,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'واحد مبلغ'),
              items: [
                for (final u in SmsMoneyUnit.values)
                  DropdownMenuItem(value: u, child: Text(u.label)),
              ],
              onChanged: _saving ? null : (v) => setState(() => _unit = v),
            )
          else
            const Text(
              'واحد پیامک قدیمی نامشخص است؛ مقدار ذخیره‌شده بازتفسیر نمی‌شود.',
            ),
          _field(_merchant, 'پذیرنده یا شرح'),
          _field(_reference, 'شناسه پیگیری'),
          _field(_bank, 'نام بانک'),
          _field(_hint, 'راهنمای حساب یا کارت'),
          DropdownButtonFormField<TransactionDirection>(
            initialValue: _direction,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'جهت پیامک'),
            items: [
              for (final d in TransactionDirection.values)
                DropdownMenuItem(value: d, child: Text(smsDirectionLabel(d))),
            ],
            onChanged: _saving ? null : (v) => setState(() => _direction = v!),
          ),
          const Text(
            'واریز یا برداشت به‌تنهایی به معنی درآمد یا هزینه نیست؛ طبقه‌بندی مالی را پیش از تأیید نهایی بررسی کنید.',
          ),
          if (widget.suggestion.extractedEvidence?.isTransfer == true)
            const Text(
              'شواهد پیامک نشان‌دهندهٔ انتقال است؛ ثبت درآمد یا هزینه مجاز نیست. انتقال را در بخش مالی بین دو حساب ثبت کنید.',
            ),
          if (_draft.dateSource == TransactionDateSource.receipt)
            Text(
              'پیشنهاد زمان دریافت (نه زمان تراکنش): ${smsReviewTimestamp(_draft.occurredAt)}',
            ),
          TextButton.icon(
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              _date == null
                  ? 'انتخاب تاریخ تراکنش (نامشخص)'
                  : 'تاریخ تراکنش: ${PersianDateFormatter.date(JalaliDate.fromDateTime(_date!))}',
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
                  ? 'انتخاب ساعت تراکنش (نامشخص)'
                  : 'ساعت تراکنش: ${PersianNumbers.format('${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}')}',
            ),
            onPressed: _saving
                ? null
                : () async {
                    final result = await showTimePicker(
                      context: context,
                      initialTime:
                          _time ??
                          TimeOfDay.fromDateTime(_draft.occurredAt.toLocal()),
                      cancelText: 'انصراف',
                      confirmText: 'تأیید ساعت',
                      helpText: 'انتخاب ساعت تراکنش',
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
