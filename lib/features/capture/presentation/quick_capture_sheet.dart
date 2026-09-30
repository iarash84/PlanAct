import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

class QuickCaptureSheet extends StatefulWidget {
  const QuickCaptureSheet({super.key});

  @override
  State<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<QuickCaptureSheet> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _count = TextEditingController();
  final _entitlementUnits = TextEditingController();
  final _financialAmount = TextEditingController();
  CommitmentDraft _draft = const CommitmentDraft();
  int _step = 0;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _count.dispose();
    _entitlementUnits.dispose();
    _financialAmount.dispose();
    super.dispose();
  }

  void _syncDraft() {
    _draft = _draft.copyWith(
      title: _title.text,
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      occurrenceCount: int.tryParse(_count.text.trim()),
      entitlementUnits: int.tryParse(
        MoneyInputFormatter.normalize(_entitlementUnits.text.trim()),
      ),
      financialAmount: int.tryParse(
        MoneyInputFormatter.normalize(_financialAmount.text.trim()),
      ),
    );
  }

  void _next() {
    _syncDraft();
    final validationStep = _step == 0 ? 1 : _step;
    final error = _draft.validateForStep(validationStep);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_step == 2) {
      _save();
      return;
    }
    if (_step == 4) {
      _save();
      return;
    }
    setState(() {
      _error = null;
      _step = _step == 0 ? 2 : _step + 1;
    });
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    _syncDraft();
    setState(() {
      _error = null;
      _step--;
    });
  }

  Future<void> _save() async {
    _syncDraft();
    final error =
        _draft.validateForStep(1) ??
        _draft.validateForStep(2) ??
        _draft.validateForStep(3);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    Navigator.of(context).pop(_draft);
  }

  Future<void> _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) =>
          _JalaliDatePicker(initialDate: _draft.startAt ?? DateTime.now()),
    );
    if (picked == null) return;
    final current = _draft.startAt ?? DateTime.now();
    setState(
      () => _draft = _draft.copyWith(
        startAt: DateTime(
          picked.year,
          picked.month,
          picked.day,
          current.hour,
          current.minute,
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final current = _draft.startAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null) return;
    setState(
      () => _draft = _draft.copyWith(
        startAt: DateTime(
          current.year,
          current.month,
          current.day,
          picked.hour,
          picked.minute,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlanActFormSheet(
      title: const [
        'تعهد جدید',
        'اطلاعات پایه',
        'زمان‌بندی',
        'بسته و اعتبار',
        'مرور نهایی',
      ][_step],
      primaryLabel: _step == 4 || _step == 2
          ? 'ثبت تعهد'
          : (_step == 0 ? 'افزودن جزئیات' : 'ادامه'),
      secondaryLabel: _step == 0 ? 'انصراف' : 'بازگشت',
      onPrimary: _next,
      onSecondary: _back,
      isLoading: _saving,
      error: _error,
      primaryKey: const ValueKey('commitment-save-button'),
      child: AnimatedSwitcher(
        duration: PlanActMotion.standard,
        child: KeyedSubtree(key: ValueKey(_step), child: _buildStep()),
      ),
    );
  }

  Widget _buildStep() => switch (_step) {
    0 => _categoryStep(),
    1 => _basicStep(),
    2 => _scheduleStep(),
    3 => _entitlementStep(),
    _ => _reviewStep(),
  };

  Widget _categoryStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'نوع تعهد را انتخاب کنید؛ جزئیات دامنه در مراحل بعدی تنظیم می‌شود.',
      ),
      const SizedBox(height: PlanActSpacing.md),
      TextFormField(
        key: const ValueKey('commitment-title-field'),
        controller: _title,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'عنوان تعهد',
          hintText: 'مثلاً کلاس زبان',
        ),
      ),
      const SizedBox(height: PlanActSpacing.md),
      for (final item in CommitmentCategory.values)
        RadioListTile<CommitmentCategory>(
          value: item,
          groupValue: _draft.category,
          title: Text(_categoryLabel(item)),
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(category: value)),
        ),
    ],
  );

  Widget _basicStep() => Column(
    children: [
      TextFormField(
        key: const ValueKey('commitment-title-field'),
        controller: _title,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'عنوان تعهد',
          hintText: 'مثلاً کلاس زبان',
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'عنوان تعهد را وارد کنید.'
            : null,
      ),
      const SizedBox(height: PlanActSpacing.md),
      TextField(
        controller: _description,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'توضیحات (اختیاری)'),
      ),
      const SizedBox(height: PlanActSpacing.md),
      DropdownButtonFormField<CommitmentPriority>(
        initialValue: _draft.priority,
        decoration: const InputDecoration(labelText: 'اولویت'),
        items: const [
          DropdownMenuItem(value: CommitmentPriority.low, child: Text('کم')),
          DropdownMenuItem(
            value: CommitmentPriority.normal,
            child: Text('عادی'),
          ),
          DropdownMenuItem(value: CommitmentPriority.high, child: Text('زیاد')),
          DropdownMenuItem(
            value: CommitmentPriority.urgent,
            child: Text('فوری'),
          ),
        ],
        onChanged: (value) =>
            setState(() => _draft = _draft.copyWith(priority: value)),
      ),
    ],
  );

  Widget _scheduleStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<CommitmentKind>(
        key: const ValueKey('commitment-kind-dropdown'),
        initialValue: _draft.kind,
        decoration: const InputDecoration(labelText: 'نوع برنامه'),
        items: const [
          DropdownMenuItem(
            value: CommitmentKind.oneOff,
            child: Text('یک‌باره'),
          ),
          DropdownMenuItem(
            value: CommitmentKind.recurring,
            child: Text('تکرارشونده'),
          ),
        ],
        onChanged: (value) =>
            setState(() => _draft = _draft.copyWith(kind: value)),
      ),
      const SizedBox(height: PlanActSpacing.md),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(
                _draft.startAt == null
                    ? 'انتخاب تاریخ'
                    : PersianDateFormatter.date(
                        JalaliDate.fromDateTime(_draft.startAt!),
                      ),
              ),
            ),
          ),
          const SizedBox(width: PlanActSpacing.sm),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule_outlined),
              label: Text(
                _draft.startAt == null
                    ? 'انتخاب زمان'
                    : TimeOfDay.fromDateTime(_draft.startAt!).format(context),
              ),
            ),
          ),
        ],
      ),
      if (_draft.isRecurring) ...[
        const SizedBox(height: PlanActSpacing.md),
        DropdownButtonFormField<RecurrenceFrequency>(
          initialValue: _draft.frequency,
          decoration: const InputDecoration(labelText: 'تکرار'),
          items: const [
            DropdownMenuItem(
              value: RecurrenceFrequency.daily,
              child: Text('روزانه'),
            ),
            DropdownMenuItem(
              value: RecurrenceFrequency.weekly,
              child: Text('هفتگی'),
            ),
            DropdownMenuItem(
              value: RecurrenceFrequency.monthly,
              child: Text('ماهانه'),
            ),
            DropdownMenuItem(
              value: RecurrenceFrequency.yearly,
              child: Text('سالانه'),
            ),
          ],
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(frequency: value)),
        ),
        if (_draft.frequency == RecurrenceFrequency.weekly) ...[
          const SizedBox(height: PlanActSpacing.sm),
          Wrap(
            spacing: PlanActSpacing.sm,
            children: [
              for (final day in const [
                ('ش', 6),
                ('ی', 7),
                ('د', 1),
                ('س', 2),
                ('چ', 3),
                ('پ', 4),
                ('ج', 5),
              ])
                FilterChip(
                  label: Text(day.$1),
                  selected: _draft.weekdays.contains(day.$2),
                  onSelected: (selected) => setState(() {
                    final days = {..._draft.weekdays};
                    selected ? days.add(day.$2) : days.remove(day.$2);
                    _draft = _draft.copyWith(weekdays: days);
                  }),
                ),
            ],
          ),
        ],
        const SizedBox(height: PlanActSpacing.md),
        TextField(
          controller: _count,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'تعداد جلسات (اختیاری)'),
        ),
      ],
      const SizedBox(height: PlanActSpacing.md),
      TextButton(
        onPressed: () => setState(() => _step = 3),
        child: const Text('تنظیم بسته و اعتبار'),
      ),
    ],
  );

  Widget _entitlementStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<EntitlementDraft>(
        initialValue: _draft.entitlement,
        decoration: const InputDecoration(labelText: 'اعتبار جلسه'),
        items: const [
          DropdownMenuItem(
            value: EntitlementDraft.none,
            child: Text('بدون بسته'),
          ),
          DropdownMenuItem(
            value: EntitlementDraft.fixedUnits,
            child: Text('تعداد ثابت جلسه'),
          ),
        ],
        onChanged: (value) =>
            setState(() => _draft = _draft.copyWith(entitlement: value)),
      ),
      if (_draft.entitlement == EntitlementDraft.fixedUnits) ...[
        const SizedBox(height: PlanActSpacing.md),
        TextField(
          controller: _entitlementUnits,
          keyboardType: TextInputType.number,
          inputFormatters: const [MoneyInputFormatter()],
          decoration: const InputDecoration(labelText: 'تعداد جلسه'),
          onChanged: (_) => _syncDraft(),
        ),
      ],
      if (_draft.financialMeaning != CommitmentFinancialMeaning.none) ...[
        const SizedBox(height: PlanActSpacing.md),
        TextField(
          controller: _financialAmount,
          keyboardType: TextInputType.number,
          inputFormatters: const [MoneyInputFormatter()],
          decoration: const InputDecoration(
            labelText: 'مبلغ مورد انتظار به تومان',
          ),
          onChanged: (_) => _syncDraft(),
        ),
      ],
      const SizedBox(height: PlanActSpacing.lg),
      const Text('معنای مالی (فقط انتظار مالی، بدون ثبت خودکار تراکنش)'),
      SegmentedButton<CommitmentFinancialMeaning>(
        segments: const [
          ButtonSegment(
            value: CommitmentFinancialMeaning.none,
            label: Text('ندارد'),
          ),
          ButtonSegment(
            value: CommitmentFinancialMeaning.paymentRequired,
            label: Text('پرداختی'),
          ),
          ButtonSegment(
            value: CommitmentFinancialMeaning.receivable,
            label: Text('دریافتی'),
          ),
        ],
        selected: {_draft.financialMeaning},
        onSelectionChanged: (value) => setState(
          () => _draft = _draft.copyWith(financialMeaning: value.first),
        ),
      ),
    ],
  );

  Widget _reviewStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        _draft.reviewSummary(),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: PlanActSpacing.md),
      const Text(
        'برای اصلاح هر بخش، با بازگشت به مرحلهٔ مربوطه اطلاعات را تغییر دهید.',
      ),
      const SizedBox(height: PlanActSpacing.md),
      OutlinedButton.icon(
        onPressed: () => setState(() => _step = 1),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('ویرایش اطلاعات پایه'),
      ),
      OutlinedButton.icon(
        onPressed: () => setState(() => _step = 2),
        icon: const Icon(Icons.edit_calendar_outlined),
        label: const Text('ویرایش زمان‌بندی'),
      ),
      OutlinedButton.icon(
        onPressed: () => setState(() => _step = 3),
        icon: const Icon(Icons.inventory_2_outlined),
        label: const Text('ویرایش بسته و اعتبار'),
      ),
    ],
  );

  String _categoryLabel(CommitmentCategory value) => switch (value) {
    CommitmentCategory.classCourse => 'کلاس / دوره',
    CommitmentCategory.appointment => 'قرار / جلسه',
    CommitmentCategory.personalRecurring => 'فعالیت شخصی تکرارشونده',
    CommitmentCategory.subscription => 'اشتراک / خدمت پولی',
    CommitmentCategory.other => 'سایر',
  };
}

class _JalaliDatePicker extends StatefulWidget {
  const _JalaliDatePicker({required this.initialDate});
  final DateTime initialDate;
  @override
  State<_JalaliDatePicker> createState() => _JalaliDatePickerState();
}

class _JalaliDatePickerState extends State<_JalaliDatePicker> {
  late JalaliDate _selected = JalaliDate.fromDateTime(widget.initialDate);
  late JalaliDate _month = JalaliDate(_selected.year, _selected.month, 1);
  @override
  Widget build(BuildContext context) {
    final offset = _month.weekDay - 1;
    final count = offset + _month.monthLength;
    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _month = _month.addMonths(-1)),
            icon: const Icon(Icons.chevron_right),
          ),
          Expanded(
            child: Center(child: Text(PersianDateFormatter.month(_month))),
          ),
          IconButton(
            onPressed: () => setState(() => _month = _month.addMonths(1)),
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: count,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemBuilder: (_, index) {
            if (index < offset) return const SizedBox();
            final day = index - offset + 1;
            final date = JalaliDate(_month.year, _month.month, day);
            final selected = date == _selected;
            return InkWell(
              onTap: () => Navigator.pop(context, date.toDateTime()),
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: selected
                      ? BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    PersianNumbers.format(day),
                    style: TextStyle(
                      color: selected
                          ? Theme.of(context).colorScheme.onPrimary
                          : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
      ],
    );
  }
}
