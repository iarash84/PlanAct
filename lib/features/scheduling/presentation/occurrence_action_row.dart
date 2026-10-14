import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/features/scheduling/presentation/occurrence_status_label.dart';
import 'package:flutter/material.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/actuals/application/actual_use_cases.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
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
    this.onEdit,
  });

  final Occurrence occurrence;
  final OccurrenceActionExecutor executor;
  final Future<void> Function() onChanged;
  final Future<void> Function(Occurrence)? onEdit;

  @override
  State<OccurrenceActionRow> createState() => _OccurrenceActionRowState();
}

class _OccurrenceActionRowState extends State<OccurrenceActionRow> {
  bool _busy = false;
  Occurrence? _updated;

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
    ActualOutcome result = ActualOutcome.completed;
    if (action.type == OccurrenceActionType.complete &&
        widget.executor is PersistedOccurrenceActionExecutor &&
        (widget.executor as PersistedOccurrenceActionExecutor).actuals !=
            null) {
      final selected = await showDialog<ActualOutcome>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text(PersianCopy.occurrenceActionRowSelectedTitle),
          children: [
            for (final entry in {
              ActualOutcome.completed:
                  PersianCopy.planactAppShowCommitmentDetailsTitle,
              ActualOutcome.attended:
                  PersianCopy.occurrenceActionRowSelectedChildren,
              ActualOutcome.cancelled:
                  PersianCopy.occurrenceActionRowSelectedChildren2,
              ActualOutcome.noShow: PersianCopy.occurrenceSkipped,
              ActualOutcome.partial:
                  PersianCopy.occurrenceActionRowSelectedChildren3,
            }.entries)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, entry.key),
                child: Text(entry.value),
              ),
          ],
        ),
      );
      if (selected == null || !mounted) return;
      result = selected;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(action.label),
          content: Text(
            PersianCopy.occurrenceActionRowConfirmedContent(
              (action.consequence).toString(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                PersianCopy.occurrenceActionRowConfirmedActions,
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(PersianCopy.financePageConfirmedActions),
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
          );
        default:
          return;
      }
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(PersianCopy.occurrenceActionRowPerformContent),
          ),
        );
      }
    } on OccurrenceReminderDeliveryPending catch (pending) {
      _updated = pending.occurrence;
      await widget.onChanged();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(PersianCopy.occurrenceActionRowPerformContent2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(PersianCopy.occurrenceActionRowPerformContent3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
              action.type == OccurrenceActionType.complete ||
              action.type == OccurrenceActionType.restore ||
              (action.type == OccurrenceActionType.reschedule &&
                  widget.onEdit != null),
        )
        .toList();
    return Card(
      child: ListTile(
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
            : actions.isEmpty
            ? null
            : PopupMenuButton<OccurrenceAction>(
                tooltip: planActL10n(context).occurrenceActionRowBuildTooltip,
                onSelected: _perform,
                itemBuilder: (_) => [
                  for (final action in actions)
                    PopupMenuItem(value: action, child: Text(action.label)),
                ],
              ),
      ),
    );
  }
}
