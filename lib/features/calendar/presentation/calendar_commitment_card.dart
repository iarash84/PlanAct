import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/features/calendar/application/week_timeline.dart';
import 'package:planact/features/calendar/presentation/planned_occurrence_widgets.dart';
import 'package:planact/features/calendar/presentation/week_timeline_view.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/features/commitments/application/checklist_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/presentation/commitment_card_layout.dart';
import 'package:planact/features/commitments/presentation/commitment_checklist_disclosure.dart';
import 'package:planact/features/commitments/presentation/commitment_identity_marker.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/reminders/presentation/occurrence_reminders.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

/// Selected-day summary; identity color does not imply an occurrence outcome.
class CalendarCommitmentCard extends StatefulWidget {
  const CalendarCommitmentCard({
    super.key,
    required this.commitment,
    required this.occurrences,
    required this.reminderRules,
    this.checklistRepository,
    this.onChecklistUpdated,
    this.onTap,
    this.onOccurrenceTap,
    this.previews = const [],
  });

  final Commitment commitment;
  final List<Occurrence> occurrences;
  final List<ReminderRule> reminderRules;
  final ChecklistRepository? checklistRepository;
  final Future<void> Function()? onChecklistUpdated;
  final VoidCallback? onTap;
  final ValueChanged<Occurrence>? onOccurrenceTap;
  final List<PlannedOccurrenceSlot> previews;

  @override
  State<CalendarCommitmentCard> createState() => _CalendarCommitmentCardState();
}

class _CalendarCommitmentCardState extends State<CalendarCommitmentCard> {
  bool _detailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final commitment = widget.commitment;
    final description = commitment.description?.trim();
    return CommitmentCardLayout(
      key: ValueKey('calendar-commitment-${commitment.id.value}'),
      leading: CommitmentIdentityMarker(
        key: ValueKey('calendar-identity-${commitment.id.value}'),
        commitment: commitment,
      ),
      title: commitment.title,
      onOpen: widget.occurrences.isNotEmpty && widget.onOccurrenceTap != null
          ? () => widget.onOccurrenceTap!(widget.occurrences.first)
          : widget.onTap,
      tags: commitment.tags.isEmpty ? null : TagLabels(labels: commitment.tags),
      metadata: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final slot in widget.previews)
            PlannedSlotTile(
              slot: slot,
              commitment: commitment,
              onTap: widget.onTap,
            ),
          if (widget.occurrences.isEmpty && widget.previews.isEmpty)
            Text(planActL10n(context).calendarCommitmentCardBuildChildren),
          for (final occurrence in widget.occurrences)
            InkWell(
              key: ValueKey('calendar-occurrence-${occurrence.id.value}'),
              onTap: widget.onOccurrenceTap == null
                  ? null
                  : () => widget.onOccurrenceTap!(occurrence),
              borderRadius: PlanActRadius.input,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: PlanActSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: PlanActSpacing.lg,
                      runSpacing: PlanActSpacing.sm,
                      children: [
                        _Metadata(
                          icon: Icons.schedule_outlined,
                          text: occurrence.currentScheduledAt is DateTime
                              ? planActL10n(context)
                                    .calendarCommitmentCardBuildText(
                                      reminderTimeLabel(
                                        WeekTimeline.displayDate(
                                          occurrence.currentScheduledAt,
                                        ),
                                      ),
                                    )
                              : planActL10n(context)
                                    .calendarCommitmentCardBuildText2,
                        ),
                        _Metadata(
                          icon: calendarStatusIcon(occurrence.status),
                          text: calendarStatusLabel(occurrence.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: PlanActSpacing.sm),
                    _Metadata(
                      icon: Icons.notifications_none_outlined,
                      text: _reminders(occurrence),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      actions: [
        if (widget.onTap != null)
          IconButton(
            tooltip: planActL10n(context).commitmentEdit,
            onPressed: widget.onTap,
            icon: const Icon(Icons.edit_outlined),
          ),
        TextButton.icon(
          key: ValueKey('calendar-details-toggle-${commitment.id.value}'),
          onPressed: () => setState(() => _detailsExpanded = !_detailsExpanded),
          icon: Icon(_detailsExpanded ? Icons.expand_less : Icons.expand_more),
          label: Text(
            _detailsExpanded
                ? planActL10n(context).detailsHide
                : planActL10n(context).detailsShow,
          ),
        ),
      ],
      expanded: _detailsExpanded,
      preview: widget.checklistRepository == null
          ? null
          : CommitmentChecklistDisclosure(
              repository: widget.checklistRepository!,
              commitmentId: commitment.id,
              onChanged: widget.onChecklistUpdated,
            ),
      details: description == null || description.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: PlanActSpacing.md),
              child: Text(description),
            ),
    );
  }

  String _reminders(Occurrence occurrence) {
    final rules = widget.reminderRules.where(
      (rule) => rule.enabled && rule.occurrenceId == occurrence.id,
    );
    return rules.isEmpty
        ? PersianCopy.calendarCommitmentCardRemindersMessage
        : PersianCopy.calendarCommitmentCardRemindersMessage2(
            rules.map(reminderRuleLabel).join(PersianCopy.commonListSeparator),
          );
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final maxWidth =
        MediaQuery.sizeOf(context).width -
        (2 * PlanActSpacing.lg + 48 + PlanActSpacing.sm);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth.clamp(48.0, double.infinity),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: PlanActSpacing.sm),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
