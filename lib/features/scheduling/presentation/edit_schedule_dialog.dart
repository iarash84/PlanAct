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
    title: const Text('ویرایش زمان نوبت'),
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
            decoration: const InputDecoration(labelText: 'دامنهٔ تغییر'),
            items: [
              const DropdownMenuItem(
                value: SeriesEditScope.onlyThis,
                child: Text('فقط این نوبت'),
              ),
              if (widget.recurring) ...[
                const DropdownMenuItem(
                  value: SeriesEditScope.thisAndFollowing,
                  child: Text('این نوبت و نوبت‌های بعد'),
                ),
                const DropdownMenuItem(
                  value: SeriesEditScope.entireActiveCycle,
                  child: Text('نوبت‌های آیندهٔ دورهٔ فعال'),
                ),
              ],
            ],
            onChanged: (value) {
              if (value != null) setState(() => _scope = value);
            },
          ),
          const SizedBox(height: PlanActSpacing.md),
          const Text(
            'سوابق انجام‌شده و نوبت‌های دستی تغییر نمی‌کنند. پرداخت و اعتبار جلسه نیز تغییر نمی‌کند.',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('انصراف'),
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
        child: const Text('ذخیرهٔ زمان'),
      ),
    ],
  );
}
