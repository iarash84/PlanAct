# Android reminders: implementation and verification checkpoint

Date: 2026-10-05. Priority 2 remains **partial**, not release-complete.

## Implemented in this checkpoint

- Explicit, user-initiated notification and exact-alarm permission activation in Settings. No startup permission prompt.
- Denied permissions do not make successful commitment creation appear to have failed. The result reports pending delivery and the UI explains how to activate reminders.
- Production commitment creation persists all reminder instances in its database transaction before attempting Android scheduling.
- Cancellation retries the platform operation even when durable cancellation was already saved.
- Changed reminder times cancel superseded intent; disable/re-enable preserves instance identity; repeated scheduling does not revive delivered history.
- Occurrence completion, cancellation, rescheduling and restoration invoke reminder synchronization in the production details action executor.
- Android IDs use deterministic SHA-256-derived positive integers rather than runtime hash codes. Existing persisted IDs remain honored.
- Pending alarms carry reminder ownership payloads. Reconciliation cleans owned orphan alarms without removing unrelated notification payloads. Legacy bare UUIDv7 payloads are recognized; duplicate legacy IDs are removed before scheduling.
- An occupied pending notification ID is rejected rather than silently replacing another owner's alarm.
- Normal startup can continue with durable reminder intent when optional notification/exact-alarm permissions are unavailable. Recovery rebuild remains strict; no backup release gate has been weakened.

No dependency or persisted-schema changes were introduced. Platform IDs remain nonportable and excluded from backup exports.

## Automated evidence

- Formatting completed for changed Dart sources.
- Flutter analyzer: no issues.
- Full Flutter test suite: **254 passed**.
- Git whitespace validation: passed.
- Added tests cover cancellation failure/retry, superseded time cleanup, identity-preserving re-enable, delivered-history preservation, permission denial preserving every intent, occurrence edit/cancel/restore/complete synchronization, and explicit permission UI/loading/error/retry.
- Existing backup all-table, rollback and host-generation tests remain passing.

Repository tests in this checkpoint largely use in-memory SQLite; these are not independent cold-process/native persistence evidence.

## Actual native evidence

A dedicated verification entry point, `tool/reminder_verification.dart`, refuses to run unless the package name is `com.iarash.planact.verification`. It never opens the production database. Build using the existing isolated-debug environment switch and this target; inspect the built APK application ID before installation.

The APK application ID was verified as `com.iarash.planact.verification`. The original `com.iarash.planact` installation was not replaced, cleared, or uninstalled.

On Samsung SM A505F, Android 11 / API 30, the isolated probe emitted:

```
PLANACT_NATIVE_REMINDER_PASS: exact delivery, retry deduplication, cancellation, orphan cleanup
```

The probe checked one pending owned alarm after repeated scheduling, waited for actual native delivery, verified the active notification ID, cancelled it and verified removal, then scheduled a future alarm and verified orphan cleanup. This is real plugin/native evidence, **not** proof of the whole product journey or reboot behavior. The API 30 device does not exercise Android 13 notification permission or Android 14 exact-alarm default denial.

## Remaining acceptance work

- Actual reboot/update/process-interruption tests with durable app state and reminders; manifest receivers alone are insufficient evidence.
- Android 13+ notification denial/revocation and Android 14+ exact-alarm denial/revocation matrix, including return from system settings.
- Lifecycle/resume reconciliation and accurate current capability status, not merely a successful activation message.
- Recover an occurrence edit interrupted between the durable occurrence write and reminder synchronization; derive reminders from current occurrence data rather than stale saved delivery time.
- Transactional/concurrent rule updates and collision-safe durable platform ID allocation, including cancellation ownership under collisions.
- Complete user-facing snooze and notification-tap routing. Service-level snooze alone is not a complete product flow.
- Consistent post-save failure feedback for non-permission platform failures; a committed domain write must not invite duplicate submission.
- Reminder-specific startup warning placement rather than reusing backup status messaging.
- Explicit recovery UX for unavailable optional notification permissions after restore, without weakening backup synchronization guarantees.
- Review all occurrence action consumers and series-edit paths, and archived/paused commitment reminder policy.
- Persian Light/Dark, scaling, accessibility and native product-flow visual review.

Do not mark Priority 2 complete from the automated count or the single native probe above.
