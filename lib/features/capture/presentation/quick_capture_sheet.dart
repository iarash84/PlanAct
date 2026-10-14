import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/features/commitments/presentation/commitment_color_picker.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:flutter/material.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

class QuickCaptureSheet extends StatefulWidget {
  const QuickCaptureSheet({super.key, this.onSave, this.tagRepository});
  final TagRepository? tagRepository;

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
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pinned ??= PinnedMoneyInput(MoneyUnitScope.of(context));
  }

  PinnedMoneyInput? _pinned;
  PinnedMoneyInput get _moneyInput =>
      _pinned ??= PinnedMoneyInput(MoneyUnitScope.of(context));
  final _financialAmount = TextEditingController();
  CommitmentDraft _draft = const CommitmentDraft();
  bool _dateSelected = false;
  bool _timeSelected = false;
  final _creditController = ExpansibleController();
  final _financeController = ExpansibleController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _creditController.dispose();
    _financeController.dispose();
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
      occurrenceCount: int.tryParse(
        MoneyInputFormatter.normalize(_count.text.trim()),
      ),
      clearOccurrenceCount: _count.text.trim().isEmpty,
      entitlementUnits: int.tryParse(
        MoneyInputFormatter.normalize(_entitlementUnits.text.trim()),
      ),
      clearEntitlementUnits: _entitlementUnits.text.trim().isEmpty,
      financialAmount: _moneyInput.parse(_financialAmount.text),
      clearFinancialAmount: _moneyInput.parse(_financialAmount.text) == null,
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    _syncDraft();
    final error =
        _draft.validateForStep(1) ??
        (!_dateSelected || !_timeSelected
            ? 'تاریخ و زمان شروع را انتخاب کنید.'
            : _draft.validateForStep(2)) ??
        _draft.validateForStep(3);
    if (error != null) {
      setState(() => _error = error);
      if (_draft.entitlement == EntitlementDraft.fixedUnits &&
          (_draft.entitlementUnits == null || _draft.entitlementUnits! <= 0)) {
        _creditController.expand();
      }
      if (_draft.financialMeaning != CommitmentFinancialMeaning.none &&
          (_draft.financialAmount == null || _draft.financialAmount! <= 0)) {
        _financeController.expand();
      }
      return;
    }
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
    if (picked == null || !mounted) return;
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
    if (picked == null || !mounted) return;
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
        title: 'افزودن تعهد',
        primaryLabel: 'ثبت تعهد',
        onPrimary: _save,
        isLoading: _saving,
        error: _error,
        primaryKey: const ValueKey('commitment-save-button'),
        child: ExcludeFocus(
          excluding: _saving,
          child: AbsorbPointer(
            absorbing: _saving,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  enabled: !_saving,
                  key: const ValueKey('commitment-title-field'),
                  controller: _title,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'عنوان تعهد',
                    hintText: 'مثلاً کلاس زبان',
                  ),
                  onChanged: (_) => setState(_syncDraft),
                ),
                const SizedBox(height: PlanActSpacing.lg),
                Text(
                  'زمان‌بندی',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: PlanActSpacing.sm),
                _scheduleFields(),
                const SizedBox(height: PlanActSpacing.md),
                _section(
                  key: 'commitment-reminders-section',
                  title: 'یادآور',
                  subtitle: _draft.reminderOffsets.isEmpty
                      ? 'بدون یادآور'
                      : _draft.reminderOffsets
                            .map((offset) => _reminderLabel(offset.inMinutes))
                            .join('، '),
                  child: _reminderPicker(),
                ),
                _section(
                  key: 'commitment-credit-section',
                  title: 'اعتبار جلسات',
                  subtitle: _draft.entitlement == EntitlementDraft.none
                      ? 'بدون بستهٔ جلسه'
                      : '${PersianNumbers.format(_draft.entitlementUnits ?? 0)} جلسه اعتبار',
                  controller: _creditController,
                  child: _entitlementFields(),
                ),
                _section(
                  key: 'commitment-finance-section',
                  title: 'اطلاعات مالی',
                  subtitle: switch (_draft.financialMeaning) {
                    CommitmentFinancialMeaning.none => 'بدون انتظار مالی',
                    CommitmentFinancialMeaning.paymentRequired =>
                      'پرداخت مورد انتظار',
                    CommitmentFinancialMeaning.receivable =>
                      'دریافت مورد انتظار',
                  },
                  controller: _financeController,
                  child: _financialFields(),
                ),
                _section(
                  key: 'commitment-details-section',
                  title: 'جزئیات بیشتر',
                  subtitle: 'توضیحات، اولویت، رنگ و برچسب‌ها',
                  child: _detailFields(),
                ),
                const SizedBox(height: PlanActSpacing.md),
                _summary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _section({
    required String key,
    required String title,
    required String subtitle,
    required Widget child,
    ExpansibleController? controller,
  }) => ExpansionTile(
    key: ValueKey(key),
    controller: controller,
    maintainState: true,
    expansionAnimationStyle: AnimationStyle(
      duration: PlanActMotion.duration(context),
      curve: PlanActMotion.curve,
    ),
    tilePadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: Text(subtitle),
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: PlanActSpacing.md),
        child: child,
      ),
    ],
  );

  Widget _detailFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        enabled: !_saving,
        controller: _description,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'توضیحات (اختیاری)'),
        onChanged: (_) => setState(_syncDraft),
      ),
      const SizedBox(height: PlanActSpacing.md),
      DropdownButtonFormField<CommitmentPriority>(
        isExpanded: true,
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
      CommitmentColorPicker(
        selected: _draft.color,
        enabled: !_saving,
        onChanged: (color) => setState(
          () =>
              _draft = _draft.copyWith(color: color, clearColor: color == null),
        ),
      ),
      const SizedBox(height: PlanActSpacing.md),
      DraftTagPicker(
        repository: widget.tagRepository,
        selected: _draft.tags,
        enabled: !_saving,
        onChanged: (tags) =>
            setState(() => _draft = _draft.copyWith(tags: tags)),
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

  Widget _scheduleFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<CommitmentKind>(
        isExpanded: true,
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
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
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
          const SizedBox(height: PlanActSpacing.sm),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.schedule_outlined),
            label: Text(
              !_timeSelected
                  ? 'انتخاب زمان'
                  : TimeOfDay.fromDateTime(_draft.startAt!).format(context),
            ),
          ),
        ],
      ),
      if (_draft.isRecurring) ...[
        const SizedBox(height: PlanActSpacing.md),
        DropdownButtonFormField<RecurrenceFrequency>(
          isExpanded: true,
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
        if (_draft.frequency == RecurrenceFrequency.monthly ||
            _draft.frequency == RecurrenceFrequency.yearly) ...[
          const SizedBox(height: PlanActSpacing.md),
          DropdownButtonFormField<RecurrenceCalendar>(
            key: const ValueKey('recurrence-calendar'),
            isExpanded: true,
            initialValue: _draft.recurrenceCalendar,
            decoration: const InputDecoration(labelText: 'تقویم تکرار'),
            items: const [
              DropdownMenuItem(
                value: RecurrenceCalendar.jalali,
                child: Text('شمسی'),
              ),
              DropdownMenuItem(
                value: RecurrenceCalendar.gregorian,
                child: Text('میلادی'),
              ),
            ],
            onChanged: (value) => setState(
              () => _draft = _draft.copyWith(recurrenceCalendar: value),
            ),
          ),
          const Text(
            'روز و ماه از تاریخ شروع در تقویم تکرار گرفته می‌شود. اگر روز در ماه مقصد وجود نداشته باشد، آخرین روز همان ماه انتخاب می‌شود؛ روز اصلی برای نوبت‌های بعد حفظ می‌شود. نمایش تاریخ‌ها همیشه شمسی است.',
          ),
        ],
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
        DropdownButtonFormField<RecurrenceTermination>(
          key: const ValueKey('recurrence-termination'),
          isExpanded: true,
          initialValue: _draft.termination,
          decoration: const InputDecoration(labelText: 'پایان تکرار'),
          items: const [
            DropdownMenuItem(
              value: RecurrenceTermination.open,
              child: Text('بدون پایان'),
            ),
            DropdownMenuItem(
              value: RecurrenceTermination.endDate,
              child: Text('تا تاریخ مشخص'),
            ),
            DropdownMenuItem(
              value: RecurrenceTermination.count,
              child: Text('تعداد مشخص'),
            ),
          ],
          onChanged: (value) =>
              setState(() => _draft = _draft.copyWith(termination: value)),
        ),
        if (_draft.termination == RecurrenceTermination.open)
          const Text(
            'نوبت‌های آینده در بازهٔ محدود ساخته می‌شوند و با بازکردن یا بازگشت به برنامه ادامه می‌یابند؛ تعداد ساخته‌شده به معنی پایان تکرار نیست.',
          ),
        if (_draft.termination == RecurrenceTermination.count)
          TextField(
            enabled: !_saving,
            key: const ValueKey('recurrence-count'),
            controller: _count,
            keyboardType: TextInputType.number,
            inputFormatters: const [MoneyInputFormatter()],
            decoration: const InputDecoration(labelText: 'تعداد نوبت‌ها'),
            onChanged: (_) => setState(_syncDraft),
          ),
        if (_draft.termination == RecurrenceTermination.endDate)
          OutlinedButton.icon(
            key: const ValueKey('recurrence-end-date'),
            onPressed: () async {
              final picked = await showDialog<DateTime>(
                context: context,
                builder: (_) => PlanActJalaliDatePicker(
                  initialDate:
                      _draft.endDate ?? _draft.startAt ?? DateTime.now(),
                ),
              );
              if (picked != null && mounted) {
                setState(() => _draft = _draft.copyWith(endDate: picked));
              }
            },
            icon: const Icon(Icons.event_outlined),
            label: Text(
              _draft.endDate == null
                  ? 'انتخاب تاریخ پایان'
                  : PersianDateFormatter.date(
                      JalaliDate.fromDateTime(_draft.endDate!),
                    ),
            ),
          ),
      ],
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
      return '${PersianNumbers.format(days)} روز قبل';
    }
    if (minutes >= 60 && minutes % 60 == 0) {
      return '${PersianNumbers.format(minutes ~/ 60)} ساعت قبل';
    }
    return '${PersianNumbers.format(minutes)} دقیقه قبل';
  }

  Widget _entitlementFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButtonFormField<EntitlementDraft>(
        isExpanded: true,
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
          enabled: !_saving,
          controller: _entitlementUnits,
          keyboardType: TextInputType.number,
          inputFormatters: const [MoneyInputFormatter()],
          decoration: const InputDecoration(labelText: 'تعداد جلسه'),
          onChanged: (_) => setState(_syncDraft),
        ),
      ],
      const SizedBox(height: PlanActSpacing.sm),
      const Text('اعتبار جلسات مستقل از تعداد نوبت‌های زمان‌بندی‌شده است.'),
    ],
  );

  Widget _financialFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (_draft.financialMeaning != CommitmentFinancialMeaning.none) ...[
        const SizedBox(height: PlanActSpacing.md),
        TextField(
          enabled: !_saving,
          controller: _financialAmount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [MoneyInputFormatter(decimal: true)],
          decoration: InputDecoration(
            labelText: 'مبلغ مورد انتظار به ${_moneyInput.unit.label}',
          ),
          onChanged: (_) => setState(_syncDraft),
        ),
      ],
      const SizedBox(height: PlanActSpacing.lg),
      const Text('معنای مالی (فقط انتظار مالی، بدون ثبت خودکار تراکنش)'),
      SegmentedButton<CommitmentFinancialMeaning>(
        direction: Axis.vertical,
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

  Widget _summary() => Column(
    key: const ValueKey('commitment-summary'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('خلاصهٔ تعهد', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: PlanActSpacing.sm),
      Text(
        _draft.reviewSummary(
          formattedFinancialAmount: PersianMoneyText.amount(
            _draft.financialAmount ?? 0,
            'IRR',
            unit: MoneyUnitScope.of(context),
          ),
        ),
      ),
      if (_dateSelected)
        Text(
          'شروع: ${PersianDateFormatter.date(JalaliDate.fromDateTime(_draft.startAt!))}',
        ),
      if (_timeSelected)
        Text(
          'ساعت: ${TimeOfDay.fromDateTime(_draft.startAt!).format(context)}',
        ),
      if (_draft.isRecurring && _draft.frequency == RecurrenceFrequency.weekly)
        Text(
          'روزها: ${[
            for (final day in const [(6, 'شنبه'), (7, 'یکشنبه'), (1, 'دوشنبه'), (2, 'سه‌شنبه'), (3, 'چهارشنبه'), (4, 'پنجشنبه'), (5, 'جمعه')])
              if (_draft.weekdays.contains(day.$1)) day.$2,
          ].join('، ')}',
        ),
      if (_draft.isRecurring &&
          _draft.termination == RecurrenceTermination.endDate &&
          _draft.endDate != null)
        Text(
          'پایان: ${PersianDateFormatter.date(JalaliDate.fromDateTime(_draft.endDate!))}',
        ),
      if (_draft.reminderOffsets.isNotEmpty)
        Text(
          'یادآور: ${_draft.reminderOffsets.map((offset) => _reminderLabel(offset.inMinutes)).join('، ')}',
        ),
      if (_draft.tags.isNotEmpty) TagLabels(labels: _draft.tags),
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
