import 'package:planact/core/localization/planact_localizations.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/scheduling/application/series_editing.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

class ScheduleEditSelection {
  const ScheduleEditSelection(this.scheduledAt, this.scope);
  final Object scheduledAt;
  final SeriesEditScope scope;
}

class EditScheduleDialog extends StatefulWidget {
  const EditScheduleDialog({
    super.key,
    required this.occurrence,
    required this.recurring,
  });
  final Occurrence occurrence;
  final bool recurring;
  @override
  State<EditScheduleDialog> createState() => _EditScheduleDialogState();
}

class _EditScheduleDialogState extends State<EditScheduleDialog> {
  late final Object _original = widget.occurrence.currentScheduledAt;
  late DateTime _date = _original is LocalDate
      ? DateTime(_original.year, _original.month, _original.day)
      : (_original as DateTime);
  late TimeOfDay? _time = _original is DateTime
      ? TimeOfDay.fromDateTime(_original)
      : null;
  SeriesEditScope _scope = SeriesEditScope.onlyThis;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(planActL10n(context).editScheduleDialogBuildTitle),
    content: SingleChildScrollView(
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
                builder: (_) => PlanActJalaliDatePicker(initialDate: _date),
              );
              if (date != null && mounted) setState(() => _date = date);
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
                if (time != null && mounted) setState(() => _time = time);
              },
            ),
          const SizedBox(height: PlanActSpacing.md),
          DropdownButtonFormField<SeriesEditScope>(
            initialValue: _scope,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: planActL10n(context).editScheduleDialogBuildLabelText,
            ),
            items: [
              DropdownMenuItem(
                value: SeriesEditScope.onlyThis,
                child: Text(planActL10n(context).editScheduleDialogBuildItems),
              ),
              if (widget.recurring) ...[
                DropdownMenuItem(
                  value: SeriesEditScope.thisAndFollowing,
                  child: Text(
                    planActL10n(context).editScheduleDialogBuildItems2,
                  ),
                ),
                DropdownMenuItem(
                  value: SeriesEditScope.entireActiveCycle,
                  child: Text(
                    planActL10n(context).editScheduleDialogBuildItems3,
                  ),
                ),
              ],
            ],
            onChanged: (value) {
              if (value != null) setState(() => _scope = value);
            },
          ),
          const SizedBox(height: PlanActSpacing.md),
          Text(planActL10n(context).editScheduleDialogBuildChildren),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(planActL10n(context).commonCancel),
      ),
      FilledButton(
        onPressed: () {
          final Object selected;
          if (_original is LocalDate) {
            selected = LocalDate(_date.year, _date.month, _date.day);
          } else if ((_original as DateTime).isUtc) {
            selected = DateTime.utc(
              _date.year,
              _date.month,
              _date.day,
              _time!.hour,
              _time!.minute,
            );
          } else {
            selected = DateTime(
              _date.year,
              _date.month,
              _date.day,
              _time!.hour,
              _time!.minute,
            );
          }
          Navigator.pop(context, ScheduleEditSelection(selected, _scope));
        },
        child: Text(planActL10n(context).editScheduleDialogBuildActions),
      ),
    ],
  );
}
