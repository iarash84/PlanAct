import 'package:flutter/material.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

/// Presents only the actions supported by the current occurrence command seam.
class OccurrenceActionRow extends StatefulWidget {
  const OccurrenceActionRow({
    super.key,
    required this.occurrence,
    required this.executor,
    required this.onChanged,
  });

  final Occurrence occurrence;
  final OccurrenceActionExecutor executor;
  final Future<void> Function() onChanged;

  @override
  State<OccurrenceActionRow> createState() => _OccurrenceActionRowState();
}

class _OccurrenceActionRowState extends State<OccurrenceActionRow> {
  bool _busy = false;
  Occurrence? _updated;

  Future<void> _perform(OccurrenceAction action) async {
    if (_busy) return;
    final occurrence = _updated ?? widget.occurrence;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(action.label),
          content: Text(action.consequence),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('بازگشت'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأیید'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      switch (action.type) {
        case OccurrenceActionType.complete:
          await widget.executor.complete(occurrence);
          _updated = occurrence.withStatus(OccurrenceStatus.completed);
        case OccurrenceActionType.restore:
          await widget.executor.restore(occurrence);
          _updated = occurrence.withStatus(OccurrenceStatus.scheduled);
        default:
          return;
      }
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('وضعیت نوبت ثبت شد.')));
      }
    } on OccurrenceReminderDeliveryPending catch (pending) {
      _updated = pending.occurrence;
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'وضعیت نوبت ثبت شد؛ هماهنگ‌سازی یادآوری هنوز انجام نشده است.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ثبت وضعیت نوبت انجام نشد؛ دوباره تلاش کنید.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final occurrence = _updated ?? widget.occurrence;
    final scheduled = occurrence.currentScheduledAt;
    final label = scheduled is DateTime
        ? PersianDateFormatter.date(JalaliDate.fromDateTime(scheduled))
        : 'نوبت برنامه‌ریزی‌شده';
    final actions = availableOccurrenceActions(occurrence)
        .where(
          (action) =>
              action.type == OccurrenceActionType.complete ||
              action.type == OccurrenceActionType.restore,
        )
        .toList();
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: Text(_statusLabel(occurrence.status)),
        trailing: _busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : actions.isEmpty
            ? null
            : PopupMenuButton<OccurrenceAction>(
                tooltip: 'اقدامات نوبت',
                onSelected: _perform,
                itemBuilder: (_) => [
                  for (final action in actions)
                    PopupMenuItem(value: action, child: Text(action.label)),
                ],
              ),
      ),
    );
  }

  String _statusLabel(OccurrenceStatus status) => switch (status) {
    OccurrenceStatus.scheduled => 'برنامه‌ریزی‌شده',
    OccurrenceStatus.due => 'موعد رسیده',
    OccurrenceStatus.completed => 'انجام‌شده',
    OccurrenceStatus.skipped => 'عدم حضور',
    OccurrenceStatus.cancelled => 'لغوشده',
    OccurrenceStatus.rescheduled => 'جابه‌جا شده',
    OccurrenceStatus.overdue => 'عقب‌افتاده',
    OccurrenceStatus.deferred => 'موکول شده',
    OccurrenceStatus.pendingDecision => 'نیازمند تصمیم',
  };
}
