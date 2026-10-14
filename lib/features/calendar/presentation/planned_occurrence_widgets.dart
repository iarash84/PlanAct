import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/application/week_timeline.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/presentation/commitment_identity_marker.dart';
import 'package:planact/features/scheduling/application/planned_occurrences.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

/// Browsing a date is always read-only; the shared picker stages selection.
Future<JalaliDate?> pickPlannedDate(
  BuildContext context,
  JalaliDate date,
) async {
  final selected = await showDialog<DateTime>(
    context: context,
    builder: (_) => PlanActJalaliDatePicker(initialDate: date.toDateTime()),
  );
  return selected == null ? null : JalaliDate.fromDateTime(selected);
}

class PlannedSlotTile extends StatelessWidget {
  const PlannedSlotTile({
    super.key,
    required this.slot,
    this.commitment,
    this.onTap,
    this.onPrepare,
    this.busy = false,
  });
  final PlannedOccurrenceSlot slot;
  final Commitment? commitment;
  final VoidCallback? onTap;
  final VoidCallback? onPrepare;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final at = slot.scheduledAt is DateTime
        ? WeekTimeline.displayDate(slot.scheduledAt)
        : slot.scheduledAt;
    final time = at is DateTime
        ? PersianNumbers.format(
            '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}',
          )
        : planActL10n(context).calendarCommitmentCardBuildText2;
    return ListTile(
      key: ValueKey('planned-slot-${slot.occurrenceKey}'),
      onTap: onTap,
      leading: commitment == null
          ? const Icon(Icons.event_note_outlined)
          : CommitmentIdentityMarker(commitment: commitment!),
      title: Text(
        commitment?.title ??
            planActL10n(context).plannedOccurrenceWidgetsBuildTitle,
      ),
      subtitle: Text(
        planActL10n(context).plannedOccurrenceWidgetsBuildSubtitle2(
          (commitment == null
                  ? ''
                  : planActL10n(context).plannedOccurrenceWidgetsBuildSubtitle)
              .toString(),
          (PersianDateFormatter.date(
            JalaliDate.fromDateTime(slot.date.toUtcDateForCalculation()),
          )).toString(),
          (time).toString(),
        ),
      ),
      trailing: onPrepare == null
          ? null
          : IconButton(
              tooltip: planActL10n(context)
                  .plannedOccurrenceWidgetsBuildTooltip,
              onPressed: busy ? null : onPrepare,
              icon: busy
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.add_task),
            ),
    );
  }
}

class PlannedDetailsRange extends StatefulWidget {
  const PlannedDetailsRange({
    super.key,
    required this.commitment,
    required this.repository,
    required this.builder,
    required this.onSaved,
    this.synchronizeReminders,
  });
  final Commitment commitment;
  final CommitmentPlanRepository repository;
  final Widget Function(CommitmentPlan, List<Occurrence>) builder;
  final Future<void> Function() onSaved;
  final Future<void> Function()? synchronizeReminders;
  @override
  State<PlannedDetailsRange> createState() => _PlannedDetailsRangeState();
}

class _PlannedDetailsRangeState extends State<PlannedDetailsRange> {
  late JalaliDate _month;
  CommitmentPlan? _plan;
  PlannedOccurrenceRange? _range;
  bool _loading = true;
  bool _error = false;
  bool _preparing = false;
  int _revision = 0;
  PlannedOccurrencesRepository? get _planned =>
      widget.repository is PlannedOccurrencesRepository
      ? widget.repository as PlannedOccurrencesRepository
      : null;

  @override
  void initState() {
    super.initState();
    final now = JalaliDate.now();
    _month = JalaliDate(now.year, now.month, 1);
    _load();
  }

  @override
  void didUpdateWidget(PlannedDetailsRange oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  Future<void> _load() async {
    final revision = ++_revision;
    final month = _month;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final plan = await widget.repository.findByCommitmentId(
        widget.commitment.id,
      );
      final start = LocalDate.fromDateTime(month.toDateTime());
      final range = await _planned?.loadPlannedRange(
        start,
        start.addDays(month.monthLength),
        LocalDate.fromDateTime(DateTime.now()),
        commitmentId: widget.commitment.id,
      );
      if (!mounted || revision != _revision) return;
      setState(() {
        _plan = plan;
        _range = range;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || revision != _revision) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  Future<void> _prepare(PlannedOccurrenceSlot slot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(PersianCopy.plannedOccurrenceWidgetsConfirmedTitle),
        content: const Text(
          PersianCopy.plannedOccurrenceWidgetsConfirmedContent,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(PersianCopy.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              PersianCopy.plannedOccurrenceWidgetsConfirmedActions,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _preparing) return;
    setState(() => _preparing = true);
    var committed = false;
    var pending = false;
    var refreshFailed = false;
    try {
      await _planned!.preparePlannedOccurrence(
        slot,
        LocalDate.fromDateTime(DateTime.now()),
      );
      committed = true;
      try {
        await widget.synchronizeReminders?.call();
      } catch (_) {
        pending = true;
      }
      await widget.onSaved();
    } catch (_) {
      refreshFailed = committed;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              committed
                  ? PersianCopy.plannedOccurrenceWidgetsPrepareContent
                  : PersianCopy.plannedOccurrenceWidgetsPrepareContent2,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _preparing = false);
        await _load();
      }
    }
    if (mounted && committed && !refreshFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pending
                ? PersianCopy.plannedOccurrenceWidgetsPrepareContent3
                : PersianCopy.plannedOccurrenceWidgetsPrepareContent4,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (plan != null) ...[
          Text(
            plan.schedule.occurrenceCount == null
                ? planActL10n(context).plannedOccurrenceWidgetsBuildChildren
                : planActL10n(context).plannedOccurrenceWidgetsBuildChildren2(
                    (PersianNumbers.format(plan.schedule.occurrenceCount!))
                        .toString(),
                  ),
          ),
          Text(
            plan.schedule.endDate == null
                ? planActL10n(context).plannedOccurrenceWidgetsBuildChildren3
                : planActL10n(context).plannedOccurrenceWidgetsBuildChildren4(
                    (PersianDateFormatter.date(
                      JalaliDate.fromDateTime(
                        plan.schedule.endDate!.toUtcDateForCalculation(),
                      ),
                    )).toString(),
                  ),
          ),
          Text(planActL10n(context).plannedOccurrenceWidgetsBuildChildren5),
        ],
        if (_planned != null)
          Row(
            children: [
              IconButton(
                tooltip: planActL10n(context)
                    .plannedOccurrenceWidgetsBuildTooltip2,
                onPressed: _preparing
                    ? null
                    : () {
                        _month = _month.addMonths(-1);
                        _load();
                      },
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _preparing
                      ? null
                      : () async {
                          final date = await pickPlannedDate(context, _month);
                          if (date != null && mounted) {
                            _month = JalaliDate(date.year, date.month, 1);
                            _load();
                          }
                        },
                  child: Text(
                    planActL10n(context).plannedOccurrenceWidgetsBuildChildren6(
                      (PersianDateFormatter.month(_month)).toString(),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: planActL10n(context)
                    .plannedOccurrenceWidgetsBuildTooltip3,
                onPressed: _preparing
                    ? null
                    : () {
                        _month = _month.addMonths(1);
                        _load();
                      },
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        if (_loading)
          const LinearProgressIndicator()
        else if (_error)
          Column(
            children: [
              Text(planActL10n(context).plannedOccurrenceWidgetsBuildChildren7),
              TextButton(
                onPressed: _load,
                child: Text(planActL10n(context).commonRetry),
              ),
            ],
          )
        else if (plan != null) ...[
          widget.builder(
            plan,
            _range == null
                ? plan.occurrences
                : _range!.recorded[widget.commitment.id.value] ?? const [],
          ),
          for (final slot
              in _range?.preview[widget.commitment.id.value] ??
                  <PlannedOccurrenceSlot>[])
            PlannedSlotTile(
              slot: slot,
              busy: _preparing,
              onPrepare: () => _prepare(slot),
            ),
          if (_range != null &&
              (_range!.recorded[widget.commitment.id.value] ?? []).isEmpty &&
              (_range!.preview[widget.commitment.id.value] ?? []).isEmpty)
            Text(planActL10n(context).plannedOccurrenceWidgetsBuildChildren8),
        ],
        const SizedBox(height: PlanActSpacing.sm),
      ],
    );
  }
}
