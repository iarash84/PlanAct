import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

String reminderRuleLabel(ReminderRule rule) {
  if (rule.anchor == ReminderAnchor.absolute) {
    final date = rule.absoluteAt!.toLocal();
    return '${PersianDateFormatter.date(JalaliDate.fromDateTime(date))}، ${reminderTimeLabel(date)}';
  }
  if (rule.offset == Duration.zero) return 'هنگام شروع';
  final seconds = rule.offset.inSeconds.abs();
  final value = seconds % 86400 == 0
      ? '${PersianNumbers.format(seconds ~/ 86400)} روز'
      : seconds % 3600 == 0
      ? '${PersianNumbers.format(seconds ~/ 3600)} ساعت'
      : seconds % 60 == 0
      ? '${PersianNumbers.format(seconds ~/ 60)} دقیقه'
      : '${PersianNumbers.format(seconds)} ثانیه';
  return '$value ${rule.offset.isNegative ? 'قبل' : 'بعد'} از شروع';
}

String reminderTimeLabel(DateTime value) {
  final date = value.isUtc ? value.toLocal() : value;
  return PersianNumbers.format(
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
  );
}

class OccurrenceReminders extends StatefulWidget {
  const OccurrenceReminders({
    super.key,
    required this.occurrence,
    required this.service,
    required this.onSaved,
  });
  final Occurrence occurrence;
  final ReminderService service;
  final Future<void> Function() onSaved;
  @override
  State<OccurrenceReminders> createState() => _OccurrenceRemindersState();
}

class _OccurrenceRemindersState extends State<OccurrenceReminders> {
  late Future<List<ReminderRule>> _rules = _load();
  bool _busy = false;
  Future<List<ReminderRule>> _load() async =>
      (await widget.service.repository.listRules())
          .where(
            (rule) => rule.occurrenceId == widget.occurrence.id && rule.enabled,
          )
          .toList();

  String _occurrenceLabel() {
    final value = widget.occurrence.currentScheduledAt;
    final date = value is DateTime
        ? (value.isUtc ? value.toLocal() : value)
        : DateTime((value as LocalDate).year, value.month, value.day);
    final label = PersianDateFormatter.date(JalaliDate.fromDateTime(date));
    return value is DateTime
        ? '$label، ساعت ${reminderTimeLabel(value)}'
        : '$label (بدون ساعت)';
  }

  Future<void> _edit(List<ReminderRule> current) async {
    final selected = await showDialog<List<ReminderRule>>(
      context: context,
      builder: (_) => EditOccurrenceRemindersDialog(
        occurrence: widget.occurrence,
        rules: current,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _busy = true);
    bool pending;
    try {
      pending = await widget.service.editOccurrenceRules(
        occurrenceId: widget.occurrence.id,
        expected: current,
        selected: selected,
        now: DateTime.now(),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _rules = _load();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'یادآوری‌ها ذخیره نشدند؛ وضعیت نوبت را بررسی و دوباره تلاش کنید.',
            ),
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _rules = _load();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          pending
              ? 'یادآوری‌ها ذخیره شدند؛ هماهنگ‌سازی اعلان‌ها در انتظار است.'
              : 'یادآوری‌ها ذخیره شدند.',
        ),
      ),
    );
    // Refresh failure must not reclassify a committed reminder edit as failed.
    try {
      await widget.onSaved();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'یادآوری‌ها ذخیره شدند؛ برای تازه‌سازی نمایش دوباره وارد صفحه شوید.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ReminderRule>>(
    future: _rules,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton.icon(
          onPressed: () => setState(() => _rules = _load()),
          icon: const Icon(Icons.refresh),
          label: const Text('بارگذاری یادآوری‌ها انجام نشد؛ تلاش دوباره'),
        );
      }
      if (!snapshot.hasData) return const LinearProgressIndicator();
      final rules = snapshot.data!;
      final resolved = {
        OccurrenceStatus.completed,
        OccurrenceStatus.cancelled,
        OccurrenceStatus.skipped,
      }.contains(widget.occurrence.status);
      return ListTile(
        leading: const Icon(Icons.notifications_outlined),
        title: Text('یادآوری‌های ${_occurrenceLabel()}'),
        subtitle: Text(
          rules.isEmpty
              ? 'بدون یادآوری'
              : rules.map(reminderRuleLabel).join('، '),
        ),
        trailing: _busy
            ? const CircularProgressIndicator()
            : IconButton(
                tooltip: resolved
                    ? 'برای ویرایش، ابتدا نتیجهٔ نوبت را بازگردانید'
                    : 'ویرایش یادآوری‌ها',
                onPressed: resolved ? null : () => _edit(rules),
                icon: const Icon(Icons.edit_outlined),
              ),
      );
    },
  );
}

class EditOccurrenceRemindersDialog extends StatefulWidget {
  const EditOccurrenceRemindersDialog({
    super.key,
    required this.occurrence,
    required this.rules,
  });
  final Occurrence occurrence;
  final List<ReminderRule> rules;
  @override
  State<EditOccurrenceRemindersDialog> createState() =>
      _EditOccurrenceRemindersDialogState();
}

class _EditOccurrenceRemindersDialogState
    extends State<EditOccurrenceRemindersDialog> {
  late final List<ReminderRule> _selected = [...widget.rules];
  final _minutes = TextEditingController();
  String? _error;
  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  void _add(int minutes) {
    if (_selected.any(
      (rule) =>
          rule.anchor == ReminderAnchor.occurrenceStart &&
          rule.offset == Duration(minutes: -minutes),
    )) {
      return;
    }
    setState(() {
      _selected.add(
        ReminderRule.beforeOccurrence(
          occurrenceId: widget.occurrence.id,
          offset: Duration(minutes: minutes),
        ),
      );
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('ویرایش یادآوری‌های این نوبت'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'تغییر فقط برای این نوبت ذخیره می‌شود؛ سابقهٔ اعلان‌ها محفوظ می‌ماند.',
          ),
          const SizedBox(height: PlanActSpacing.md),
          for (final rule in _selected)
            ListTile(
              title: Text(reminderRuleLabel(rule)),
              trailing: IconButton(
                tooltip: 'حذف این یادآوری',
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _selected.remove(rule)),
              ),
            ),
          if (_selected.isEmpty) const Text('بدون یادآوری'),
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _selected.clear()),
              child: const Text('حذف همهٔ یادآوری‌های این نوبت'),
            ),
          if (widget.occurrence.currentScheduledAt is DateTime) ...[
            Wrap(
              spacing: PlanActSpacing.sm,
              children: [0, 15, 30, 60, 1440]
                  .map(
                    (minutes) => ActionChip(
                      label: Text(
                        minutes == 0
                            ? 'هنگام شروع'
                            : '${PersianNumbers.format(minutes)} دقیقه قبل',
                      ),
                      onPressed: () => _add(minutes),
                    ),
                  )
                  .toList(),
            ),
            TextField(
              controller: _minutes,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'دقایق قبل از شروع (دلخواه)',
                errorText: _error,
              ),
            ),
            TextButton(
              onPressed: () {
                final minutes = int.tryParse(
                  PersianNumbers.normalizeDigits(_minutes.text.trim()),
                );
                if (minutes == null || minutes < 0) {
                  setState(
                    () => _error = 'تعداد دقیقه را صفر یا بیشتر وارد کنید.',
                  );
                } else {
                  _add(minutes);
                  _minutes.clear();
                }
              },
              child: const Text('افزودن یادآوری'),
            ),
          ] else
            const Text(
              'این نوبت ساعت ندارد؛ افزودن یادآوری نسبی نیازمند انتخاب صریح ساعت است.',
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
        onPressed: () => Navigator.pop(context, _selected),
        child: const Text('ذخیرهٔ یادآوری‌ها'),
      ),
    ],
  );
}
