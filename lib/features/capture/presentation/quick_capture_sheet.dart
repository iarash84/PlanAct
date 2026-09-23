import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

class CommitmentDraft {
  const CommitmentDraft({
    required this.title,
    this.scheduledDates = const [],
    this.kind = CommitmentKind.oneOff,
    this.priority = CommitmentPriority.normal,
    this.description,
    this.tags = const {},
    this.frequency = RecurrenceFrequency.weekly,
    this.weekdays = const {},
    this.dayOfMonth,
    this.occurrenceCount,
    this.endDate,
    this.reminderOffsets = const [],
    this.attachmentIds = const [],
  });
  final String title;
  final List<DateTime> scheduledDates;
  final CommitmentKind kind;
  final CommitmentPriority priority;
  final String? description;
  final Set<String> tags;
  final RecurrenceFrequency frequency;
  final Set<int> weekdays;
  final int? dayOfMonth;
  final int? occurrenceCount;
  final DateTime? endDate;
  final List<Duration> reminderOffsets;
  final List<String> attachmentIds;
}

class QuickCaptureSheet extends StatefulWidget {
  const QuickCaptureSheet({super.key});

  @override
  State<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<QuickCaptureSheet> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _occurrenceCountController = TextEditingController();
  bool _showOptions = false;
  DateTime _date = DateTime.now();
  TimeOfDay? _time;
  CommitmentKind _kind = CommitmentKind.oneOff;
  CommitmentPriority _priority = CommitmentPriority.normal;
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  RecurrenceFrequency _frequency = RecurrenceFrequency.weekly;
  final Set<int> _weekdays = {};
  int? _occurrenceCount;
  final Set<Duration> _reminderOffsets = {};
  final List<String> _attachmentIds = [];

  @override
  void dispose() {
    _controller.dispose();
    _occurrenceCountController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDialog<DateTime>(
      context: context,
      builder: (context) => _JalaliDatePicker(initialDate: _date),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickAttachments() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;
    setState(() {
      _attachmentIds
        ..clear()
        ..addAll(result.files.map((file) => file.path).whereType<String>());
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final title = _controller.text.trim();
    Navigator.of(context).pop(
      CommitmentDraft(
        title: title,
        kind: _kind,
        priority: _priority,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toSet(),
        frequency: _frequency,
        weekdays: Set.unmodifiable(_weekdays),
        occurrenceCount: _occurrenceCount,
        reminderOffsets: List.unmodifiable(_reminderOffsets),
        attachmentIds: List.unmodifiable(_attachmentIds),
        scheduledDates: [
          DateTime(
            _date.year,
            _date.month,
            _date.day,
            _time?.hour ?? 9,
            _time?.minute ?? 0,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        PlanActSpacing.lg,
        0,
        PlanActSpacing.lg,
        bottom + PlanActSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'تعهد جدید',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: PlanActSpacing.lg),
              TextFormField(
                key: const ValueKey('commitment-title-field'),
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _save(),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'عنوان تعهد را وارد کنید.'
                    : null,
                decoration: const InputDecoration(
                  labelText: 'چه کاری باید انجام شود؟',
                  hintText: 'مثلاً کلاس زبان',
                ),
              ),
              const SizedBox(height: PlanActSpacing.md),
              TextButton.icon(
                onPressed: () => setState(() => _showOptions = !_showOptions),
                icon: Icon(_showOptions ? Icons.expand_less : Icons.tune),
                label: Text(_showOptions ? 'بستن گزینه‌ها' : 'افزودن جزئیات'),
              ),
              if (_showOptions) ...[
                Wrap(
                  spacing: PlanActSpacing.sm,
                  runSpacing: PlanActSpacing.sm,
                  children: [
                    ActionChip(
                      avatar: const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                      ),
                      label: Text(
                        PersianDateFormatter.date(
                          JalaliDate.fromDateTime(_date),
                        ),
                      ),
                      onPressed: _pickDate,
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.schedule_outlined, size: 18),
                      label: Text(
                        _time == null ? 'زمان' : _time!.format(context),
                      ),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _time ?? TimeOfDay.now(),
                        );
                        if (picked != null) setState(() => _time = picked);
                      },
                    ),
                    if (_kind == CommitmentKind.recurring)
                      DropdownButton<RecurrenceFrequency>(
                        value: _frequency,
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
                            setState(() => _frequency = value!),
                      ),
                    _ReminderSelector(
                      selected: _reminderOffsets,
                      onChanged: (value) => setState(() {
                        _reminderOffsets
                          ..clear()
                          ..addAll(value);
                      }),
                    ),
                  ],
                ),
                if (_kind == CommitmentKind.recurring) ...[
                  const SizedBox(height: PlanActSpacing.md),
                  TextField(
                    controller: _occurrenceCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'تعداد جلسات',
                      hintText: 'مثلاً ۱۰',
                    ),
                    onChanged: (value) =>
                        _occurrenceCount = int.tryParse(value),
                  ),
                ],
                const SizedBox(height: PlanActSpacing.md),
                DropdownButtonFormField<CommitmentKind>(
                  key: const ValueKey('commitment-kind-dropdown'),
                  initialValue: _kind,
                  decoration: const InputDecoration(labelText: 'نوع تعهد'),
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
                  onChanged: (value) => setState(() => _kind = value!),
                ),
                const SizedBox(height: PlanActSpacing.md),
                DropdownButtonFormField<CommitmentPriority>(
                  initialValue: _priority,
                  decoration: const InputDecoration(labelText: 'اولویت'),
                  items: const [
                    DropdownMenuItem(
                      value: CommitmentPriority.low,
                      child: Text('کم'),
                    ),
                    DropdownMenuItem(
                      value: CommitmentPriority.normal,
                      child: Text('عادی'),
                    ),
                    DropdownMenuItem(
                      value: CommitmentPriority.high,
                      child: Text('زیاد'),
                    ),
                    DropdownMenuItem(
                      value: CommitmentPriority.urgent,
                      child: Text('فوری'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _priority = value!),
                ),
                const SizedBox(height: PlanActSpacing.md),
                TextField(
                  controller: _descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'توضیحات'),
                ),
                const SizedBox(height: PlanActSpacing.md),
                TextField(
                  controller: _tagsController,
                  decoration: const InputDecoration(
                    labelText: 'برچسب‌ها',
                    hintText: 'مثلاً مالی، شخصی',
                  ),
                ),
                const SizedBox(height: PlanActSpacing.md),
                OutlinedButton.icon(
                  onPressed: _pickAttachments,
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _attachmentIds.isEmpty
                        ? 'افزودن فایل'
                        : '${_attachmentIds.length} فایل انتخاب شده',
                  ),
                ),
              ],
              if (_showOptions &&
                  _kind == CommitmentKind.recurring &&
                  _frequency == RecurrenceFrequency.weekly) ...[
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
                        selected: _weekdays.contains(day.$2),
                        onSelected: (selected) => setState(() {
                          if (selected) {
                            _weekdays.add(day.$2);
                          } else {
                            _weekdays.remove(day.$2);
                          }
                        }),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: PlanActSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('commitment-save-button'),
                  onPressed: _save,
                  child: const Text('ثبت'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JalaliDatePicker extends StatefulWidget {
  const _JalaliDatePicker({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_JalaliDatePicker> createState() => _JalaliDatePickerState();
}

class _JalaliDatePickerState extends State<_JalaliDatePicker> {
  late JalaliDate _selected;
  late JalaliDate _month;

  @override
  void initState() {
    super.initState();
    _selected = JalaliDate.fromDateTime(widget.initialDate);
    _month = JalaliDate(_selected.year, _selected.month, 1);
  }

  void _changeMonth(int offset) {
    setState(() => _month = _month.addMonths(offset));
  }

  @override
  Widget build(BuildContext context) {
    final firstWeekdayOffset = _month.weekDay - 1;
    final dayCount = _month.monthLength;
    final cellCount = firstWeekdayOffset + dayCount;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          IconButton(
            tooltip: 'ماه قبل',
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_right),
          ),
          Expanded(
            child: Center(
              child: Text(
                PersianDateFormatter.month(_month),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'ماه بعد',
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_left),
          ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  for (final name in PersianDateFormatter.weekdayNames)
                    Expanded(
                      child: Center(
                        child: Text(
                          name.substring(0, 1),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cellCount,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemBuilder: (context, index) {
                  if (index < firstWeekdayOffset) return const SizedBox();
                  final day = index - firstWeekdayOffset + 1;
                  final date = JalaliDate(_month.year, _month.month, day);
                  final isSelected = date == _selected;
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).pop(date.toDateTime()),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: isSelected
                            ? BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              )
                            : null,
                        child: Text(
                          PersianNumbers.format(day),
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('انصراف'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderSelector extends StatelessWidget {
  const _ReminderSelector({required this.selected, required this.onChanged});

  final Set<Duration> selected;
  final ValueChanged<Set<Duration>> onChanged;

  static const options = <MapEntry<Duration, String>>[
    MapEntry(Duration(minutes: 5), '۵ دقیقه قبل'),
    MapEntry(Duration(minutes: 10), '۱۰ دقیقه قبل'),
    MapEntry(Duration(minutes: 15), '۱۵ دقیقه قبل'),
    MapEntry(Duration(minutes: 30), '۳۰ دقیقه قبل'),
    MapEntry(Duration(hours: 1), '۱ ساعت قبل'),
    MapEntry(Duration(days: 1), '۱ روز قبل'),
    MapEntry(Duration(days: 2), '۲ روز قبل'),
    MapEntry(Duration(days: 7), '۱ هفته قبل'),
  ];

  @override
  Widget build(BuildContext context) => PopupMenuButton<Duration>(
    tooltip: 'یادآوری‌ها',
    onSelected: (value) {
      final next = {...selected};
      if (!next.add(value)) next.remove(value);
      onChanged(next);
    },
    itemBuilder: (context) => options
        .map(
          (option) => CheckedPopupMenuItem<Duration>(
            value: option.key,
            checked: selected.contains(option.key),
            child: Text(option.value),
          ),
        )
        .toList(),
    child: InputDecorator(
      decoration: const InputDecoration(
        labelText: 'یادآوری‌ها',
        suffixIcon: Icon(Icons.notifications_none),
      ),
      child: Text(
        selected.isEmpty
            ? 'انتخاب چند یادآوری'
            : '${PersianNumbers.format(selected.length)} یادآوری انتخاب شده',
      ),
    ),
  );
}
