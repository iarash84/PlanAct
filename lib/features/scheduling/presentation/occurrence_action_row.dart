import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/presentation/undo_feedback.dart';
import 'package:planact/features/scheduling/presentation/occurrence_status_label.dart';
import 'package:flutter/material.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/actuals/application/actual_use_cases.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/sessions/domain/session_policy.dart';

/// Presents only the actions supported by the current occurrence command seam.
class OccurrenceActionRow extends StatefulWidget {
  const OccurrenceActionRow({
    super.key,
    required this.occurrence,
    required this.executor,
    required this.onChanged,
    this.onEdit,
    this.useActionsMenu = false,
  });

  final Occurrence occurrence;
  final OccurrenceActionExecutor executor;
  final Future<void> Function() onChanged;
  final Future<void> Function(Occurrence)? onEdit;

  /// Keeps the compact presentation local to the Commitment Details route.
  /// Today and Calendar intentionally keep the expanded action rows.
  final bool useActionsMenu;

  @override
  State<OccurrenceActionRow> createState() => _OccurrenceActionRowState();
}

class _OccurrenceActionRowState extends State<OccurrenceActionRow> {
  bool _busy = false;
  Occurrence? _updated;

  Future<void> _undo(
    Occurrence occurrence,
    ScaffoldMessengerState messenger, {
    required String successMessage,
    required String pendingMessage,
    required String conflictMessage,
  }) async {
    if (mounted && _busy) return;
    if (mounted) setState(() => _busy = true);
    try {
      await widget.executor.restore(occurrence);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(successMessage)));
      await widget.onChanged();
    } on OccurrenceReminderDeliveryPending catch (pending) {
      if (mounted) _updated = pending.occurrence;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(pendingMessage)));
      await widget.onChanged();
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(conflictMessage)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _perform(OccurrenceAction action) async {
    if (_busy) return;
    final occurrence = _updated ?? widget.occurrence;
    if (action.type == OccurrenceActionType.reschedule) {
      setState(() => _busy = true);
      try {
        await widget.onEdit?.call(occurrence);
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    setState(() => _busy = true);
    try {
      switch (action.type) {
        case OccurrenceActionType.complete:
          final result = ActualOutcome.completed;
          final executor = widget.executor;
          if (executor is PersistedOccurrenceActionExecutor &&
              executor.actuals != null) {
            _updated = await executor.recordResult(occurrence, result);
          } else {
            await executor.complete(occurrence);
            _updated = occurrence.withStatus(OccurrenceStatus.completed);
          }
        case OccurrenceActionType.restore:
          await widget.executor.restore(occurrence);
          _updated = Occurrence(
            id: occurrence.id,
            cycleId: occurrence.cycleId,
            scheduleDefinitionId: occurrence.scheduleDefinitionId,
            occurrenceKey: occurrence.occurrenceKey,
            originalScheduledAt: occurrence.originalScheduledAt,
            currentScheduledAt: occurrence.currentScheduledAt,
            status: occurrence.isManualOverride
                ? OccurrenceStatus.rescheduled
                : OccurrenceStatus.scheduled,
            isManualOverride: occurrence.isManualOverride,
            resultRevision: occurrence.resultRevision + 1,
          );
        case OccurrenceActionType.providerCancelled:
          await widget.executor.cancel(
            occurrence,
            outcome: SessionOutcome.providerCancelled,
          );
          _updated = _withResult(occurrence, OccurrenceStatus.cancelled);
        case OccurrenceActionType.userCancelled:
        case OccurrenceActionType.cancel:
          await widget.executor.cancel(
            occurrence,
            outcome: SessionOutcome.userCancelled,
          );
          _updated = _withResult(occurrence, OccurrenceStatus.cancelled);
        case OccurrenceActionType.noShow:
          await widget.executor.cancel(
            occurrence,
            outcome: SessionOutcome.noShow,
          );
          _updated = _withResult(occurrence, OccurrenceStatus.skipped);
        case OccurrenceActionType.makeup:
          return;
        case OccurrenceActionType.reschedule:
          return;
      }
      await widget.onChanged();
      final changed = _updated;
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final l10n = planActL10n(context);
        showRecordedActionFeedback(
          context,
          l10n.occurrenceActionRowPerformContent,
          onUndo: changed == null
              ? null
              : () => _undo(
                  changed,
                  messenger,
                  successMessage: l10n.undoSuccess,
                  pendingMessage: l10n.undoRefreshPending,
                  conflictMessage: l10n.undoConflict,
                ),
        );
      }
    } on OccurrenceReminderDeliveryPending catch (pending) {
      _updated = pending.occurrence;
      await widget.onChanged();
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final l10n = planActL10n(context);
        showRecordedActionFeedback(
          context,
          l10n.occurrenceActionRowPerformContent2,
          onUndo: () => _undo(
            pending.occurrence,
            messenger,
            successMessage: l10n.undoSuccess,
            pendingMessage: l10n.undoRefreshPending,
            conflictMessage: l10n.undoConflict,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        showRecordedActionFeedback(
          context,
          planActL10n(context).occurrenceActionRowPerformContent3,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Occurrence _withResult(Occurrence occurrence, OccurrenceStatus status) =>
      Occurrence(
        id: occurrence.id,
        cycleId: occurrence.cycleId,
        scheduleDefinitionId: occurrence.scheduleDefinitionId,
        occurrenceKey: occurrence.occurrenceKey,
        originalScheduledAt: occurrence.originalScheduledAt,
        currentScheduledAt: occurrence.currentScheduledAt,
        status: status,
        isManualOverride: occurrence.isManualOverride,
        resultRevision: occurrence.resultRevision + 1,
      );

  Future<void> _showHistory() async {
    final executor = widget.executor;
    if (executor is! PersistedOccurrenceActionExecutor) return;
    final repository = executor.actuals;
    if (repository is! ActualRepository) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(PersianCopy.occurrenceActionRowShowHistoryTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<List<Actual>>(
            future: (repository as ActualRepository).list(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  PersianCopy.occurrenceActionRowShowHistoryBuilder,
                );
              }
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final items = snapshot.data!
                  .where((item) => item.occurrenceId == widget.occurrence.id)
                  .toList();
              if (items.isEmpty) {
                return const Text(
                  PersianCopy.occurrenceActionRowShowHistoryBuilder2,
                );
              }
              return ListView(
                shrinkWrap: true,
                children: [
                  for (final item in items)
                    ListTile(
                      title: Text(switch (item.outcome) {
                        ActualOutcome.completed =>
                          PersianCopy.planactAppShowCommitmentDetailsTitle,
                        ActualOutcome.attended =>
                          PersianCopy.occurrenceActionRowActualOutcomeAttended,
                        ActualOutcome.cancelled =>
                          PersianCopy.occurrenceActionRowSelectedChildren2,
                        ActualOutcome.missed =>
                          PersianCopy.occurrenceActionRowActualOutcomeMissed,
                        ActualOutcome.noShow => PersianCopy.occurrenceSkipped,
                        ActualOutcome.partial =>
                          PersianCopy.occurrenceActionRowSelectedChildren3,
                        ActualOutcome.reopened =>
                          PersianCopy.occurrenceActionRowActualOutcomeReopened,
                      }),
                      subtitle: Text(
                        [
                          PersianDateFormatter.date(
                            JalaliDate.fromDateTime(item.recordedAt.toLocal()),
                          ),
                          if (item.note != null) item.note!,
                        ].join('\n'),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(PersianCopy.commonClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final occurrence = _updated ?? widget.occurrence;
    final scheduled = occurrence.currentScheduledAt;
    final label = scheduled is DateTime
        ? PersianDateFormatter.date(JalaliDate.fromDateTime(scheduled))
        : scheduled is LocalDate
        ? PersianDateFormatter.date(
            JalaliDate.fromDateTime(
              DateTime(scheduled.year, scheduled.month, scheduled.day),
            ),
          )
        : planActL10n(context).occurrenceActionRowLabelMessage;
    final actions = availableOccurrenceActions(occurrence)
        .where(
          (action) =>
              action.type != OccurrenceActionType.makeup &&
              (action.type != OccurrenceActionType.reschedule ||
                  widget.onEdit != null),
        )
        .toList();
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(label),
            subtitle: Text(
              planActL10n(context).occurrenceActionRowBuildSubtitle(
                (occurrenceStatusLabel(occurrence.status)).toString(),
              ),
            ),
            onTap: _busy ? null : _showHistory,
            trailing: _busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : widget.useActionsMenu
                ? PopupMenuButton<OccurrenceActionType>(
                    key: ValueKey(
                      'occurrence-actions-menu-${occurrence.id.value}',
                    ),
                    tooltip: planActL10n(context)
                        .occurrenceActionRowBuildTooltip,
                    onSelected: (type) => _perform(
                      actions.firstWhere((action) => action.type == type),
                    ),
                    itemBuilder: (context) => [
                      for (final action in actions)
                        PopupMenuItem<OccurrenceActionType>(
                          value: action.type,
                          child: Row(
                            children: [
                              Icon(_iconFor(action.type)),
                              const SizedBox(width: 12),
                              Flexible(child: Text(action.label)),
                            ],
                          ),
                        ),
                    ],
                  )
                : null,
          ),
          if (!widget.useActionsMenu)
            for (final action in actions)
              ListTile(
                key: ValueKey(
                  'occurrence-action-${occurrence.id.value}-${action.type.name}',
                ),
                leading: Icon(_iconFor(action.type)),
                title: Text(action.label),
                onTap: _busy ? null : () => _perform(action),
              ),
        ],
      ),
    );
  }

  IconData _iconFor(OccurrenceActionType type) => switch (type) {
    OccurrenceActionType.complete => Icons.check_circle_outline,
    OccurrenceActionType.providerCancelled => Icons.event_busy_outlined,
    OccurrenceActionType.userCancelled => Icons.cancel_outlined,
    OccurrenceActionType.cancel => Icons.cancel_outlined,
    OccurrenceActionType.noShow => Icons.person_off_outlined,
    OccurrenceActionType.reschedule => Icons.schedule_outlined,
    OccurrenceActionType.restore => Icons.restore_outlined,
    OccurrenceActionType.makeup => Icons.add_task_outlined,
  };
}
