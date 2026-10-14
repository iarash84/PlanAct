import 'package:flutter/material.dart';
import 'package:planact/core/application/undo_token.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/undo_feedback.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/scheduling/application/schedule_undo.dart';

class ScheduleUndoButton extends StatefulWidget {
  const ScheduleUndoButton({
    super.key,
    required this.repository,
    required this.commitmentId,
    required this.onChanged,
    this.reminders,
  });
  final ScheduleUndoRepository repository;
  final StableId commitmentId;
  final Future<void> Function() onChanged;
  final ReminderService? reminders;
  @override
  State<ScheduleUndoButton> createState() => _ScheduleUndoButtonState();
}

class _ScheduleUndoButtonState extends State<ScheduleUndoButton> {
  bool _busy = false;
  Future<void> _undo(UndoToken token) async {
    if (_busy ||
        !await confirmRecordedAction(
          context,
          planActL10n(context).undoConfirmMessage,
        ) ||
        !mounted) {
      return;
    }
    setState(() => _busy = true);
    bool pending;
    try {
      pending = await UndoScheduleChange(
        widget.repository,
        reminders: widget.reminders,
      )(widget.commitmentId, token, DateTime.now());
    } catch (_) {
      if (mounted) {
        showRecordedActionFeedback(context, planActL10n(context).undoConflict);
      }
      if (mounted) setState(() => _busy = false);
      return;
    }
    try {
      await widget.onChanged();
    } catch (_) {
      if (mounted) {
        showRecordedActionFeedback(
          context,
          planActL10n(context).undoRefreshPending,
        );
      }
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (mounted) {
      setState(() => _busy = false);
      showRecordedActionFeedback(
        context,
        pending
            ? planActL10n(context).planactAppBuildContent
            : planActL10n(context).undoSuccess,
      );
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<UndoToken?>(
    future: widget.repository.scheduleUndo(widget.commitmentId),
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton(
          onPressed: () => setState(() {}),
          child: Text(planActL10n(context).commonRetry),
        );
      }
      if (!snapshot.hasData) return const SizedBox.shrink();
      return OutlinedButton.icon(
        onPressed: _busy ? null : () => _undo(snapshot.data!),
        icon: const Icon(Icons.undo),
        label: Text(planActL10n(context).undoScheduleAction),
      );
    },
  );
}
