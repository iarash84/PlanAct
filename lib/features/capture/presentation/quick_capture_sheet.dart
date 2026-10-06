import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

class QuickCaptureSheet extends StatefulWidget {
  const QuickCaptureSheet({super.key, this.onSave});

  /// Persists before closing; a failed save leaves the form intact for retry.
  final Future<void> Function(CommitmentDraft draft)? onSave;

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
  bool _dateSelected = false;
  bool _timeSelected = false;
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
    if (_saving) return;
    _syncDraft();
    final error = _step == 0
        ? _draft.validateForStep(1)
        : _step == 1
        ? (!_dateSelected || !_timeSelected
              ? 'تاریخ و زمان شروع را انتخاب کنید.'
              : _draft.validateForStep(2) ?? _draft.validateForStep(3))
        : _draft.validateForStep(1) ??
              (!_dateSelected || !_timeSelected
                  ? 'تاریخ و زمان شروع را انتخاب کنید.'
                  : _draft.validateForStep(2)) ??
              _draft.validateForStep(3);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_step == 2) {
      _save();
      return;
    }
    setState(() {
      _error = null;
      _step++;
    });
  }

  void _back() {
    if (_saving) return;
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
        (!_dateSelected || !_timeSelected
            ? 'تاریخ و زمان شروع را انتخاب کنید.'
            : _draft.validateForStep(2)) ??
        _draft.validateForStep(3);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.onSave != null) await widget.onSave!(_draft);
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop(widget.onSave == null ? _draft : null);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error =
              'ثبت تعهد انجام نشد؛ اطلاعات شما حفظ شده است. دوباره تلاش کنید.';
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (_) => PlanActJalaliDatePicker(
        initialDate: _draft.startAt ?? DateTime.now(),
      ),
    );
    if (picked == null) return;
    final current = _draft.startAt;
    setState(() {
      _dateSelected = true;
      _draft = _draft.copyWith(
        startAt: DateTime(
          picked.year,
          picked.month,
          picked.day,
          _timeSelected ? current!.hour : 0,
          _timeSelected ? current!.minute : 0,
        ),
      );
    });
  }

  Future<void> _pickTime() async {
    final current = _draft.startAt ?? DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null) return;
    setState(() {
      _timeSelected = true;
      _draft = _draft.copyWith(
        startAt: DateTime(
          current.year,
          current.month,
          current.day,
          picked.hour,
          picked.minute,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: PlanActFormSheet(
        title: const ['اصل تعهد', 'زمان‌بندی', 'مرور و ثبت'][_step],
        primaryLabel: _step == 2 ? 'ثبت تعهد' : 'ادامه',
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
      ),
    );
  }

  Widget _buildStep() => switch (_step) {
    0 => _basicStep(),
    1 => _scheduleStep(),
    _ => _reviewStep(),
  };

  Widget _basicStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
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
      const SizedBox(height: PlanActSpacing.md),
      RadioGroup<CommitmentCategory>(
        groupValue: _draft.category,
        onChanged: (value) =>
            setState(() => _draft = _draft.copyWith(category: value)),
        child: Column(
          children: [
            for (final item in CommitmentCategory.values)
              RadioListTile<CommitmentCategory>(
                value: item,
                title: Text(_categoryLabel(item)),
              ),
          ],
        ),
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
                !_dateSelected
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
                !_timeSelected
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
      const SizedBox(height: PlanActSpacing.lg),
      _reminderPicker(),
      const SizedBox(height: PlanActSpacing.md),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('تنظیمات پیشرفته'),
        children: [_entitlementStep()],
      ),
    ],
  );

  Widget _reminderPicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('یادآوری‌های این تعهد'),
      const SizedBox(height: PlanActSpacing.xs),
      const Text('می‌توانید چند یادآوری، پیش از زمان هر نوبت ثبت کنید.'),
      const SizedBox(height: PlanActSpacing.sm),
      Wrap(
        spacing: PlanActSpacing.sm,
        runSpacing: PlanActSpacing.sm,
        children: [
          for (final minutes in const [5, 15, 30, 60, 1440])
            FilterChip(
              label: Text(_reminderLabel(minutes)),
              selected: _draft.reminderOffsets.contains(
                Duration(minutes: minutes),
              ),
              onSelected: (selected) => _toggleReminder(minutes, selected),
            ),
          ActionChip(
            avatar: const Icon(Icons.add, size: 18),
            label: const Text('زمان دلخواه'),
            onPressed: _addCustomReminder,
          ),
        ],
      ),
      if (_draft.reminderOffsets
          .where(
            (offset) => !const [5, 15, 30, 60, 1440].contains(offset.inMinutes),
          )
          .isNotEmpty) ...[
        const SizedBox(height: PlanActSpacing.sm),
        for (final offset in _draft.reminderOffsets.where(
          (offset) => !const [5, 15, 30, 60, 1440].contains(offset.inMinutes),
        ))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(_reminderLabel(offset.inMinutes)),
            trailing: IconButton(
              tooltip: 'حذف یادآوری',
              onPressed: () => setState(() {
                final offsets = [..._draft.reminderOffsets]..remove(offset);
                _draft = _draft.copyWith(reminderOffsets: offsets);
              }),
              icon: const Icon(Icons.close),
            ),
          ),
      ],
    ],
  );

  void _toggleReminder(int minutes, bool selected) {
    final offset = Duration(minutes: minutes);
    final offsets = [..._draft.reminderOffsets];
    if (selected) {
      if (!offsets.contains(offset)) offsets.add(offset);
    } else {
      offsets.remove(offset);
    }
    offsets.sort((a, b) => b.compareTo(a));
    setState(() => _draft = _draft.copyWith(reminderOffsets: offsets));
  }

  Future<void> _addCustomReminder() async {
    final minutes = await showDialog<int?>(
      context: context,
      builder: (_) => const _CustomReminderDialog(),
    );
    if (!mounted || minutes == null) return;
    final offset = Duration(minutes: minutes);
    if (_draft.reminderOffsets.contains(offset)) return;
    final offsets = [..._draft.reminderOffsets, offset]
      ..sort((a, b) => b.compareTo(a));
    setState(() => _draft = _draft.copyWith(reminderOffsets: offsets));
  }

  static String _reminderLabel(int minutes) {
    if (minutes >= 1440 && minutes % 1440 == 0) {
      final days = minutes ~/ 1440;
      return '$days روز قبل';
    }
    if (minutes >= 60 && minutes % 60 == 0) {
      return '${minutes ~/ 60} ساعت قبل';
    }
    return '$minutes دقیقه قبل';
  }

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
        onPressed: () => setState(() => _step = 0),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('ویرایش اطلاعات پایه'),
      ),
      OutlinedButton.icon(
        onPressed: () => setState(() => _step = 1),
        icon: const Icon(Icons.edit_calendar_outlined),
        label: const Text('ویرایش زمان‌بندی'),
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

class _CustomReminderDialog extends StatefulWidget {
  const _CustomReminderDialog();

  @override
  State<_CustomReminderDialog> createState() => _CustomReminderDialogState();
}

class _CustomReminderDialogState extends State<_CustomReminderDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('یادآوری دلخواه'),
    content: TextField(
      key: const ValueKey('custom-reminder-minutes-field'),
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'چند دقیقه قبل؟',
        hintText: 'مثلاً ۹۰',
      ),
    ),
    actions: [
      TextButton(
        key: const ValueKey('custom-reminder-cancel'),
        onPressed: () => Navigator.pop<int?>(context, null),
        child: const Text('انصراف'),
      ),
      FilledButton(
        onPressed: () {
          final value = int.tryParse(_controller.text.trim());
          if (value == null || value <= 0) return;
          Navigator.pop<int?>(context, value);
        },
        child: const Text('افزودن'),
      ),
    ],
  );
}
