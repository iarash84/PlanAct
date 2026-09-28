# PlanAct Release Security and Stability Gate

**Status:** Release candidate evidence — 2026-09-28
**Scope:** dependency audit, security regressions, persistence/restore safety, Android release readiness

## 1. Dependency audit

Source command: `flutter pub outdated`

| Dependency | Before/locked | Result | Decision and risk |
|---|---:|---|---|
| `flutter_local_notifications` | 19.5.0 | Upgraded to `^22.3.1` | Accepted breaking API migration: v22 requires named `initialize`, `zonedSchedule`, and `cancel` arguments. The adapter was updated and analysis/tests pass. Android build still requires network access to resolve the plugin's Android Gradle artifacts. |
| `timezone` | 0.10.1 | Upgraded to `^0.11.1` | Upgraded together with notifications because the old notification line constrained timezone to 0.10.x. Existing timezone initialization/location behavior remains unchanged. |
| `sqlite3_flutter_libs` | 0.5.42 locked / `^0.5.29` constraint | **Not upgraded** | Latest resolvable line is `0.6.0+eol`. No change was made: taking an explicitly EOL SQLite packaging line without a replacement/compatibility ADR is not a safe release improvement. |
| `drift` / `drift_dev` | 2.28.1 | Not upgraded | No independent upgrade was required for this gate; no schema migration was introduced. |

No destructive migration, schema rewrite, or broad refactor was performed.

## 2. Regression coverage

The following gates are covered by tests:

- **Backup tampering/encryption:** authenticated AES-GCM round trip; checksum, malformed JSON, missing metadata, incompatible schema, wrong key, and oversized payload rejection.
- **Atomic restore:** safety snapshot and rollback when rebuild fails; current state remains intact.
- **Raw SMS retention:** expired raw text is removed while fingerprint/decision metadata remains; retention metadata survives database restart.
- **Permission denial/non-blocking platform behavior:** reminder persistence and offline operation do not depend on notification delivery; Android permission behavior is non-blocking by adapter contract.
- **Malformed platform payload:** malformed Android SMS maps are rejected at the platform boundary.
- **Database restart:** SQLite/Drift data, schedules, staged imports, and retention metadata survive close/reopen.
- **Logger redaction:** sensitive fields and diagnostic messages do not expose account, amount, SMS, or other sensitive values.
- **Reminder integration:** restart reconciliation rebuilds active notifications and rescheduling cancels the prior platform operation.

## 3. Validation evidence

### Passed

- `flutter pub get` after notification/timezone upgrade.
- `flutter analyze` — passed with no issues.
- `flutter test` — passed, 121 tests.
- `flutter test test/repository` — passed, 12 tests.
- `flutter test test/integration` — passed, 3 tests.
- Focused security/persistence suite — passed, 27 tests:
  - `test/unit/android_sms_source_test.dart`
  - `test/unit/backup_test.dart`
  - `test/unit/app_logger_test.dart`
  - `test/unit/inbox_test.dart`
  - `test/repository/app_database_test.dart`
  - `test/integration/reminder_integration_test.dart`
- `dart format` on changed Dart files.

### Blocked / must be rerun in a networked release environment

- `flutter build apk --release` — blocked while Gradle attempted to download Android Gradle Plugin 8.11.1 artifacts from `dl.google.com`; this is an environment/network failure, not a Dart compilation failure.
- Merged manifest audit and APK signing verification — cannot be completed until a release APK is produced.

## 4. Android release checklist

- [ ] Run `flutter build apk --release` on a machine with Android SDK, Gradle dependencies, and Google Maven access (or a warm, approved dependency cache).
- [ ] Run `:app:processReleaseMainManifest`, `:app:mergeReleaseResources`, and `:app:assembleRelease`.
- [ ] Inspect merged manifest for `allowBackup="false"`, cleartext denial, network security config, extraction rules, exported components, and protected SMS receiver.
- [ ] Verify release APK with `aapt dump permissions`, `aapt dump xmltree`, and `apksigner verify --verbose --print-certs`.
- [ ] Confirm release uses the configured non-debug signing key; never accept a debug fallback.
- [ ] Perform a real backup → close app → restore → reopen flow using a disposable test dataset. Verify invalid/tampered restore leaves the live database unchanged.
- [ ] Test Android 13+ and one pre-13 API level: notification denial, SMS denial, exact-alarm denial, reboot reminder rebuild, and later permission grant.
- [ ] Verify no raw SMS body, sender identifier, private note, account identifier, or financial value is present in release logs or release evidence.

## 5. Accepted risks

- The notification/timezone upgrade is a major-version API migration. It is limited to the platform adapter and is covered by analysis, unit, and integration tests; physical Android delivery still requires device validation.
- SQLite packaging remains on the existing non-EOL-compatible line because the reported latest resolvable package is marked EOL. A future SQLite stack decision must include Drift compatibility, native ABI coverage, migration/restart tests, and backup/restore verification.
- Android release build and merged manifest/signing evidence are not verified in this environment because Google Maven was unreachable.

## 6. Known limitations

- This gate does not claim production signing or device-matrix completion.
- Permission denial tests are contract/unit-level in this repository; Android system-dialog behavior requires emulator/device execution.
- Backup restore was tested through the storage abstraction and atomic rollback harness; a real filesystem backup package restore remains a release-candidate manual gate.
- Platform-specific limitations must be recorded per release, including notification scheduling/exact-alarm behavior, SMS permission availability, and reboot behavior.
