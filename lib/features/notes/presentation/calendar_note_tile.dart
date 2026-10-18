import 'package:flutter/material.dart';
import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/notes/domain/calendar_note.dart';

class CalendarNoteTile extends StatelessWidget {
  const CalendarNoteTile({super.key, required this.note, this.onTap});
  final CalendarNote note;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: ValueKey('calendar-note-${note.id.value}'),
      color: theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(PlanActSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(PlanActSpacing.xs),
                    decoration: BoxDecoration(
                      color: CommitmentIdentityPalette.background(
                        note.color,
                        theme.brightness,
                      ),
                      borderRadius: PlanActRadius.chip,
                    ),
                    child: Icon(
                      Icons.note_alt_outlined,
                      color: CommitmentIdentityPalette.foreground(
                        note.color,
                        theme.brightness,
                      ),
                    ),
                  ),
                  const SizedBox(width: PlanActSpacing.sm),
                  Expanded(
                    child: Text(
                      planActL10n(context).calendarNoteLabel,
                      style: theme.textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PlanActSpacing.xs),
              Text(note.title, style: theme.textTheme.titleMedium),
              if (note.description.isNotEmpty)
                Text(
                  note.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
