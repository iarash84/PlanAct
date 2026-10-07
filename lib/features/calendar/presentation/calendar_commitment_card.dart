import 'package:flutter/material.dart';
import 'package:planact/features/commitments/presentation/commitment_identity_marker.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/calendar/application/week_timeline.dart';
import 'package:planact/features/calendar/presentation/week_timeline_view.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/reminders/presentation/occurrence_reminders.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

/// Selected-day summary; identity color does not imply an occurrence outcome.
class CalendarCommitmentCard extends StatelessWidget {
  const CalendarCommitmentCard({
    super.key,
    required this.commitment,
    required this.occurrences,
    required this.reminderRules,
    this.onTap,
  });

  final Commitment commitment;
  final List<Occurrence> occurrences;
  final List<ReminderRule> reminderRules;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: ValueKey('calendar-commitment-${commitment.id.value}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: PlanActRadius.card,
        child: Padding(
          padding: const EdgeInsets.all(PlanActSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommitmentIdentityMarker(
                    key: ValueKey('calendar-identity-${commitment.id.value}'),
                    commitment: commitment,
                  ),
                  const SizedBox(width: PlanActSpacing.md),
                  Expanded(
                    child: Text(
                      commitment.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: PlanActSpacing.sm),
                    const Icon(Icons.chevron_right),
                  ],
                ],
              ),
              if (commitment.tags.isNotEmpty) ...[
                const SizedBox(height: PlanActSpacing.sm),
                TagLabels(labels: commitment.tags),
              ],
              if (occurrences.isEmpty) ...[
                const SizedBox(height: PlanActSpacing.md),
                const Text('جزئیات رخداد در دسترس نیست.'),
              ],
              for (final occurrence in occurrences) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: PlanActSpacing.md),
                  child: Divider(height: 1),
                ),
                Wrap(
                  spacing: PlanActSpacing.lg,
                  runSpacing: PlanActSpacing.sm,
                  children: [
                    _Metadata(
                      icon: Icons.schedule_outlined,
                      text: occurrence.currentScheduledAt is DateTime
                          ? 'ساعت ${reminderTimeLabel(WeekTimeline.displayDate(occurrence.currentScheduledAt))}'
                          : 'تمام‌روز (بدون ساعت)',
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
            ],
          ),
        ),
      ),
    );
  }

  String _reminders(Occurrence occurrence) {
    final rules = reminderRules.where(
      (rule) => rule.enabled && rule.occurrenceId == occurrence.id,
    );
    return rules.isEmpty
        ? 'بدون یادآوری'
        : 'یادآوری: ${rules.map(reminderRuleLabel).join('، ')}';
  }
}

class _Metadata extends StatelessWidget {
  const _Metadata({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: PlanActSpacing.sm),
      Flexible(
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}
