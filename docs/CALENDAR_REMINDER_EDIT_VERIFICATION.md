# Calendar and occurrence reminder editing

Scope: correction of shared Jalali month arrows, reminder editing in commitment details, and selected-day Calendar metadata. This does not complete the broader Priority 6–7 or native reminder release gates.

## Behavior

- Shared Jalali picker follows Calendar's existing previous/next icon convention; Persian tooltips identify each action. Year rollover is covered by a widget test.
- Details shows date/time-labelled reminder rows for each occurrence. The editor explicitly applies to this occurrence only. Users can retain, remove, replace, add preset/custom nonnegative-minute offsets, or select no reminders. Persian and Arabic digits are normalized centrally.
- Existing absolute rules are displayed and may be retained or removed; creation/editing of absolute date-time reminders is not introduced here. All-day occurrences are not silently assigned a time and cannot add relative reminders through this editor.
- Resolved occurrences cannot be edited until explicitly reopened. Production edits require persistent eligibility/schedule contracts and a reminder-intent transaction. Stale rule selections are rejected.
- Removed rules are disabled, not deleted; active instances are cancelled in the same transaction. Delivered history and retained snooze values are preserved. New instances are committed before platform reconciliation. Platform failure reports saved configuration with pending notification synchronization rather than failed persistence.
- Calendar displays selected-day occurrence times and enabled reminder rules, not another day's reminders. Fixed instants are displayed in local time; date-only occurrences retain explicit all-day semantics. Display-only local DateTime conversion does not change persistence.

## Focused visual coverage

| Surface | Status | Review |
| --- | --- | --- |
| Shared picker: Quick Capture and schedule editing | Migrated | Existing month convention and accessible Persian labels; no new theme values |
| Commitment details reminder rows/editor | Migrated | Shared Material controls, spacing and semantic typography; scrollable optional custom field |
| Calendar selected-day rows | Migrated | Reuses shared commitment row with occurrence metadata; Light/Dark widget coverage |
| Today/shared row other consumers | Intentionally Unchanged | Optional supporting metadata leaves existing callers' rendering unchanged |

## Evidence and limitations

Tests cover file-backed cold restart after platform failure, stale selection rejection, transaction rollback, removal of all reminders with delivered history retained, shared picker arrows/year rollover, Persian custom input and selected-day metadata in Light and Dark.

No schema migration or dependency is added. Existing rule/instance tables remain included in backup; this task does not claim independent native interruption/reboot delivery, general durable concurrency revisions, whole-series reminder editing, or complete absolute reminder authoring.
