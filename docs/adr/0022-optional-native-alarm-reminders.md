# 0022 — Optional Android alarm delivery

Status: implementation decision for the user-approved 2026-10-14 scope;
independent/native release acceptance remains open.

Delivery is an explicit domain enum, separate from timing and occurrence outcome.
Notification remains the legacy/default. Creation stores one method for the
commitment template; Details edits only that occurrence, replacing rules when
switching method while retaining disabled rules and history.

Use AlarmManager.setAlarmClock with immutable, instance-owned PendingIntents.
Flutter need not run between scheduling and delivery. A nonexported receiver starts
a nonexported mediaPlayback foreground service only at the deadline. One USAGE_ALARM
player serves concurrent rings, each with separate controls and a two-minute
deadline; snooze is ten minutes. No full-screen permission, overlay, permanent
service, cloud or new dependency is introduced.

Native AlarmStore is a bounded persistence/application adapter. It takes SQLite
writer admission, verifies fresh rule/instance method, active owner/cycle, unresolved
occurrence, current timing and delivery token, then claims delivery or commits user
snooze. It never writes occurrence, actual, money, entitlement or recurrence state.
Native status indices and epoch-second storage are explicitly coupled to schema 19;
another schema requires updating the adapter and database/device evidence. Domain
calculations remain Dart-only. Native Java time conversion only checks fresh intent;
local/DST/fixed/absolute cases require independent evidence.

`reminder_delivery_v1:rule:<id>` and `...:instance:<id>` in the existing metadata
extension store preserve method; recurrence JSON carries `generationReminderDelivery`.
Absent values mean notification, unknown values fail. No schema migration is needed.
Snapshots preserve both extensions. Older binaries cannot honor alarm semantics;
schema compatibility does not approve downgrade.

Native preferences carry only database path, paused flag, rebuildable queue IDs and
ring tokens. Backup/restore suspends native access under the native lock, clears
queued/ringing work and drains/replaces the DB. Reconfiguration after validation
authorizes rebuild while a restore marker exists; this authorization is process-local
and cannot survive a crash. Export/cancel/restore resumes from durable SQLite intent.
No native connection is retained across replacement.

Notifications contain generic private copy. Tapping opens the protected Flutter
root; stop/snooze disclose no personal data and never imply completion. Full-screen
UI and opening sensitive Details from the lock screen are outside this decision.
Native copy is generated from ARB (`x-planact-android-resource`) and checked by the
existing copy generator.

References: [acceptance/evidence](../ALARM_REMINDER_VERIFICATION.md),
[Android alarms](https://developer.android.com/develop/background-work/services/alarms),
[foreground rules](https://developer.android.com/develop/background-work/services/fgs/restrictions-bg-start),
[media service type](https://developer.android.com/develop/background-work/services/fgs/service-types#media).
