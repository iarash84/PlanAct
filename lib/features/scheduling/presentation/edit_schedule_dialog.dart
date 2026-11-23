import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/scheduling/application/recurrence_schedule_edit.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

class ScheduleEditSelection {
  const ScheduleEditSelection(
    this.scheduledAt,
    this.scope, {
    this.recurrenceEdit,
    this.previewToken,
  });
  final Object scheduledAt;
  final SeriesEditScope scope;
  final RecurrenceScheduleEdit? recurrenceEdit;
  final String? previewToken;
}

typedef SchedulePreview = Future<RecurrenceEditPreview> Function(
  ScheduleEditSelection selection,
);

class EditScheduleDialog extends StatefulWidget {
  const EditScheduleDialog({
    super.key,
    required this.occurrence,
    required this.recurring,
    this.schedule,
    this.onPreview,
    this.onConfirm,
  });
  final Occurrence occurrence;
  final bool recurring;
  final ScheduleDefinition? schedule;
  final SchedulePreview? onPreview;
  final Future<void> Function(ScheduleEditSelection selection)? onConfirm;
  @override
  State<EditScheduleDialog> createState() => _EditScheduleDialogState();
}

enum _Termination { open, date, count }

class _EditScheduleDialogState extends State<EditScheduleDialog> {
  late final Object _original = widget.occurrence.currentScheduledAt;
  late DateTime _date = _original is LocalDate
      ? DateTime(_original.year, _original.month, _original.day)
      : (_original as DateTime);
  late TimeOfDay? _time = _original is DateTime
      ? TimeOfDay.fromDateTime(_original)
      : null;
  SeriesEditScope _scope = SeriesEditScope.onlyThis;
  bool _editPattern = false;
  bool _busy = false;
  String? _error;
  RecurrenceEditPreview? _preview;
  late RecurrenceFrequency _frequency =
      widget.schedule?.recurrenceRule?.frequency ?? RecurrenceFrequency.daily;
  late final Set<int> _weekdays = {
    ...?widget.schedule?.recurrenceRule?.weekdays,
  };
  late final _interval = TextEditingController(
    text: PersianNumbers.format(widget.schedule?.recurrenceRule?.interval ?? 1),
  );
  late final _count = TextEditingController(
    text: widget.schedule?.occurrenceCount == null
        ? ''
        : PersianNumbers.format(widget.schedule!.occurrenceCount!),
  );
  late LocalDate? _endDate = widget.schedule?.endDate;
  late _Termination _termination = widget.schedule?.occurrenceCount != null
      ? _Termination.count
      : _endDate != null
      ? _Termination.date
      : _Termination.open;
  bool get _pattern => _editPattern && _scope != SeriesEditScope.onlyThis;
  bool get _canEditPattern =>
      widget.onPreview != null &&
      widget.schedule?.recurrenceRule != null &&
      widget.schedule?.timeSemantics != TimeSemantics.fixedInstant;

  @override
  void dispose() {
    _interval.dispose();
    _count.dispose();
    super.dispose();
  }

  void _changed(VoidCallback change) => setState(() {
    change();
    _preview = null;
    _error = null;
  });
  int? _positive(String value) {
    final n = int.tryParse(PersianNumbers.normalizeDigits(value));
    return n != null && n > 0 ? n : null;
  }

  String _dateLabel(LocalDate date) => PersianDateFormatter.date(
    JalaliDate.fromDateTime(DateTime(date.year, date.month, date.day)),
  );

  ScheduleEditSelection _selection() {
    final Object selected = _original is LocalDate
        ? LocalDate(_date.year, _date.month, _date.day)
        : (_original as DateTime).isUtc
        ? DateTime.utc(
            _date.year,
            _date.month,
            _date.day,
            _time!.hour,
            _time!.minute,
          )
        : DateTime(
            _date.year,
            _date.month,
            _date.day,
            _time!.hour,
            _time!.minute,
          );
    RecurrenceScheduleEdit? edit;
    if (_pattern) {
      final interval = _positive(_interval.text);
      final count = _positive(_count.text);
      if (interval == null ||
          (_frequency == RecurrenceFrequency.weekly && _weekdays.isEmpty) ||
          (_termination == _Termination.count && count == null) ||
          (_termination == _Termination.date && _endDate == null)) {
        throw const FormatException();
      }
      final old = widget.schedule!.recurrenceRule!;
      edit = RecurrenceScheduleEdit(
        rule: RecurrenceRule(
          frequency: _frequency,
          interval: interval,
          weekdays: _weekdays,
          calendar: old.calendar,
          dayOfMonth: old.dayOfMonth,
          monthOfYear: old.monthOfYear,
          monthEndPolicy: old.monthEndPolicy,
          legacyCalendarSemantics: old.legacyCalendarSemantics,
        ),
        endDate: _termination == _Termination.date ? _endDate : null,
        totalCount: _termination == _Termination.count ? count : null,
      );
    }
    return ScheduleEditSelection(
      selected,
      _scope,
      recurrenceEdit: edit,
      previewToken: _pattern ? _preview?.token : null,
    );
  }

  Future<void> _submit() async {
    final l10n = planActL10n(context);
    ScheduleEditSelection selection;
    try {
      selection = _selection();
    } catch (_) {
      setState(() => _error = l10n.scheduleEditInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final previewing = _pattern && _preview == null;
    try {
      if (previewing) {
        final result = await widget.onPreview!(selection);
        if (mounted) setState(() => _preview = result);
      } else {
        await widget.onConfirm?.call(selection);
        if (mounted) Navigator.pop(context, selection);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _preview = null;
          _error = previewing
              ? l10n.scheduleEditPreviewFailed
              : l10n.scheduleEditSaveFailed;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final frequencyLabels = [
      l10n.recurrenceDaily,
      l10n.recurrenceWeekly,
      l10n.recurrenceMonthly,
      l10n.recurrenceYearly,
    ];
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(l10n.editScheduleDialogBuildTitle),
        content: SingleChildScrollView(
          child: AbsorbPointer(
            absorbing: _busy,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    PersianDateFormatter.date(JalaliDate.fromDateTime(_date)),
                  ),
                  onPressed: () async {
                    final date = await showDialog<DateTime>(
                      context: context,
                      builder: (_) =>
                          PlanActJalaliDatePicker(initialDate: _date),
                    );
                    if (date != null && mounted) _changed(() => _date = date);
                  },
                ),
                if (_time != null)
                  TextButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: Text(_time!.format(context)),
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _time!,
                      );
                      if (time != null && mounted) _changed(() => _time = time);
                    },
                  ),
                const SizedBox(height: PlanActSpacing.md),
                DropdownButtonFormField<SeriesEditScope>(
                  key: const ValueKey('schedule-scope'),
                  initialValue: _scope,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.editScheduleDialogBuildLabelText,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: SeriesEditScope.onlyThis,
                      child: Text(l10n.editScheduleDialogBuildItems),
                    ),
                    if (widget.recurring) ...[
                      DropdownMenuItem(
                        value: SeriesEditScope.thisAndFollowing,
                        child: Text(l10n.editScheduleDialogBuildItems2),
                      ),
                      DropdownMenuItem(
                        value: SeriesEditScope.entireActiveCycle,
                        child: Text(l10n.editScheduleDialogBuildItems3),
                      ),
                    ],
                  ],
                  onChanged: (value) {
                    if (value != null) _changed(() => _scope = value);
                  },
                ),
                const SizedBox(height: PlanActSpacing.md),
                Text(l10n.editScheduleDialogBuildChildren),
                if (_canEditPattern && _scope != SeriesEditScope.onlyThis) ...[
                  const SizedBox(height: PlanActSpacing.lg),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.scheduleEditPattern),
                    value: _editPattern,
                    onChanged: (value) => _changed(() => _editPattern = value),
                  ),
                  if (_pattern) ...[
                    DropdownButtonFormField<RecurrenceFrequency>(
                      key: const ValueKey('schedule-frequency'),
                      initialValue: _frequency,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.scheduleEditFrequency,
                      ),
                      items: [
                        for (final value in RecurrenceFrequency.values)
                          DropdownMenuItem(
                            value: value,
                            child: Text(frequencyLabels[value.index]),
                          ),
                      ],
                      onChanged: (value) {
                        if (value != null) _changed(() => _frequency = value);
                      },
                    ),
                    const SizedBox(height: PlanActSpacing.md),
                    TextField(
                      key: const ValueKey('schedule-interval'),
                      controller: _interval,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.scheduleEditInterval,
                      ),
                      onChanged: (_) => _changed(() {}),
                    ),
                    if (_frequency == RecurrenceFrequency.weekly)
                      Wrap(
                        spacing: PlanActSpacing.sm,
                        children: [
                          for (var i = 0; i < 7; i++)
                            FilterChip(
                              label: Text(PersianDateFormatter.weekdayNames[i]),
                              selected: _weekdays.contains((i + 5) % 7 + 1),
                              onSelected: (selected) => _changed(() {
                                final day = (i + 5) % 7 + 1;
                                selected
                                    ? _weekdays.add(day)
                                    : _weekdays.remove(day);
                              }),
                            ),
                        ],
                      ),
                    const SizedBox(height: PlanActSpacing.md),
                    DropdownButtonFormField<_Termination>(
                      key: const ValueKey('schedule-termination'),
                      initialValue: _termination,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l10n.scheduleEditTermination,
                      ),
                      items: [
                        DropdownMenuItem(
                          value: _Termination.open,
                          child: Text(
                            l10n.quickCaptureSheetScheduleFieldsItems3,
                          ),
                        ),
                        DropdownMenuItem(
                          value: _Termination.date,
                          child: Text(l10n.scheduleEditEndDate),
                        ),
                        DropdownMenuItem(
                          value: _Termination.count,
                          child: Text(l10n.scheduleEditTotalCount),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) _changed(() => _termination = value);
                      },
                    ),
                    if (_termination == _Termination.count)
                      TextField(
                        key: const ValueKey('schedule-count'),
                        controller: _count,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.scheduleEditTotalCount,
                        ),
                        onChanged: (_) => _changed(() {}),
                      ),
                    if (_termination == _Termination.date)
                      TextButton.icon(
                        key: const ValueKey('schedule-end-date'),
                        icon: const Icon(Icons.event),
                        label: Text(
                          _endDate == null
                              ? l10n.scheduleEditEndDate
                              : _dateLabel(_endDate!),
                        ),
                        onPressed: () async {
                          final date = await showDialog<DateTime>(
                            context: context,
                            builder: (_) => PlanActJalaliDatePicker(
                              initialDate: _endDate == null
                                  ? _date
                                  : DateTime(
                                      _endDate!.year,
                                      _endDate!.month,
                                      _endDate!.day,
                                    ),
                            ),
                          );
                          if (date != null && mounted) {
                            _changed(
                              () => _endDate = LocalDate.fromDateTime(date),
                            );
                          }
                        },
                      ),
                    const SizedBox(height: PlanActSpacing.md),
                    Text(l10n.scheduleEditAnchorsPreserved),
                  ],
                ],
                if (_preview case final preview?) ...[
                  const SizedBox(height: PlanActSpacing.lg),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.scheduleEditPreviewSummary(
                        _dateLabel(preview.boundary),
                        PersianNumbers.format(preview.occurrences.length),
                      ),
                    ),
                  ),
                  for (final row in preview.occurrences)
                    Text(
                      row.currentScheduledAt is LocalDate
                          ? _dateLabel(row.currentScheduledAt as LocalDate)
                          : '${_dateLabel(LocalDate.fromDateTime(row.currentScheduledAt as DateTime))} ${TimeOfDay.fromDateTime(row.currentScheduledAt as DateTime).format(context)}',
                    ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: PlanActSpacing.lg),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                if (_busy) ...[
                  const SizedBox(height: PlanActSpacing.md),
                  const LinearProgressIndicator(),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: Text(
              _pattern
                  ? (_preview == null
                        ? l10n.scheduleEditPreview
                        : l10n.scheduleEditConfirm)
                  : l10n.editScheduleDialogBuildActions,
            ),
          ),
        ],
      ),
    );
  }
}
