# Backup verification checkpoint

## Automated evidence

Historical local checkpoint: 2026-10-05. The recovery-key checkpoint below
supersedes key ownership and updates evidence; earlier native checks are not
retroactively claimed as executed.

- `flutter analyze`: no issues.
- `flutter test --reporter compact`: 245 tests passed.
- `git diff --check`: passed.
- New full-state repository tests: encrypted restore and failed-rebuild rollback,
  with all 23 persisted tables populated and every logical row compared after
  cold reopening. Export deliberately redacts raw SMS and platform notification
  IDs; rollback preserves both.
- New file-backed host widget test: admission retirement waits for persistence
  and a controlled delayed platform effect, old UI state is disposed, old
  repository commands are rejected, cancellation creates a fresh database and
  repository generation, and durable state remains available.
- Historical schema tests cover 12 committed migration fixtures. Compatibility
  accepts complete trusted declarations only and checks legacy rows against the
  current isolated schema. See ADR 0013 for the exact scope.

These tests do not constitute native picker, Keystore or device process-kill
verification.

## Isolated Android build

In Windows cmd.exe:

```bat
set PLANACT_ISOLATED_VERIFICATION=true&& flutter build apk --debug
```

The optional environment switch affects debug builds only. The built APK's
manifest application ID was inspected with Android apkanalyzer and confirmed as
`com.iarash.planact.verification`. Normal builds keep the existing ID; release
builds do not gain the suffix. Never install a normal-ID verification build over
an installation containing personal data.

At this checkpoint `flutter devices` lists no Android device. No installation,
key access, data clearing or process killing was performed on the personal-data
installation. Build identity verification is not functional Android evidence.

## Remaining native release checks

Use only the independent verification installation with synthetic data:

1. Create durable commitments, financial records and an inbox import. Export
   through the native document picker, cancel once and retry. Check visible
   success/failure and continued operation after cancellation.
2. Modify the synthetic data, import the exported file through the native picker
   and verify original data after a cold process restart.
3. Export format 2 and retain its key separately. In a second **isolated fresh
   installation**, offline and without old app/Keystore data, import with file
   plus key. Compare all synthetic logical records after cold restart. Check
   lost/wrong key, tampering and cancelled input preserve current data. Verify
   legacy format 1 warns and uses only the original installation key; missing
   legacy key rejects without provisioning. Never clear personal storage/keys.
4. Exercise restore interruption around replacement/rebuild and restart. Check
   original-state safety recovery and no candidate UI before commit.
5. Confirm native reminder queue clearing/rebuilding, rejected notification
   permission behavior and absence of stale listener effects.
6. Review filesystem durability on Android. Dart flush and same-directory rename
   are used; full directory-fsync power-loss guarantees are not established.

## Independent recovery-key checkpoint — 2026-10-10

Acceptance contract was recorded before code in ADR 0018. New production exports
are format 2, with a fresh cryptography-generated 256-bit AES key for every
attempt, shown before exclusive mode and acknowledged in the same export.
Persian warnings explain separate storage and unrecoverable loss. No automatic
clipboard write, secure-storage persistence, log or plaintext sidecar was added.
The focused follow-up below adds explicit user-initiated copy only; it does not
satisfy the safe-storage acknowledgement.
Format 1 remains legacy installation-key-only; import never rewrites/provisions.
No dependency or database migration was added.

### Automated evidence

Final focused run: 76 tests passed across 13 backup unit/repository/widget files.
Formatting completed; final `flutter analyze` reported no issues and
`git diff --check` passed. The whole repository suite and native tests are not
claimed. An initial journey-test fake-clock timeout was corrected by using the
existing real-async file-I/O test pattern; the final journey passed. The prior
missing acceptance check was independent key ownership, not encryption alone.

- Independent file-backed source/target directories: offline file+key restore,
  source-directory removal, no installation-key access, cold reopen, absent/wrong
  key and recomputed-checksum tamper rejection preserving target bytes.
- All persisted tables populated: format-2 full logical-state restore and failed
  rebuild rollback after cold reopen. Raw SMS/platform IDs remain the only
  deliberate export differences; rollback preserves the original.
- Fourteen committed historical-schema fixtures: actual migration, snapshot,
  format-2 encryption, restore into fresh current database and cold reopen;
  unknown/weakened schemas and invalid historical rows remain rejected.
- Format-2 injected safety/temp/flush/marker/rename/commit failures preserve
  original file-backed state. Existing crash-marker and reminder tests retained.
- Production FileBackupActions with controlled picker: fresh keys across retries,
  cancellation before snapshot/save, concurrent admission rejection, save failure,
  file+key import, legacy confirmation and unchanged legacy file. No key-storage
  reads on new exports/imports; no plaintext companion file.
- Real card → production actions → key acknowledgement → encrypted save journey;
  existing host test proves full-command drain, old UI disposal, stale callbacks
  rejection and repository generation rebind. These platform effects are mocked.
- Persian dialogs: per-export acknowledgement reset, cancellation, input validation,
  legacy warning, RTL Light/Dark, 360dp width and 1.5 text scale.

Proportional visual coverage: backup card/dialogs **Migrated** using existing
Material component themes/spacing; More/root shell **Intentionally Unchanged**
(no shared visual role changed); exclusive loading/retry host **Intentionally
Unchanged** except actionable recovery-key error wording. No new palette,
typography, radius or motion token.

### Unexecuted acceptance and release decision

Native picker/storage, actual second fresh-install offline restore, OS process
interruption, reminder/listener integration, Android power-loss durability and
independent acceptance review are **not executed** by this task. There was no
personal-install data access or destructive native operation. Unit/widget tests
are not device-loss readiness evidence. Owner: release maintainer; next action:
execute the isolated Android checklist above, retain file+key separately and
record independent review. Exposure: implementation is local-only; Priority 1
remains **partial/release-blocked**, not device-loss-ready until those gates pass.
Managed-memory clearing is best effort, not a guarantee against memory/screen
capture; retaining the key securely remains the user's responsibility.

## Explicit key copy follow-up — 2026-10-10

### Acceptance contract (recorded before code)

Entry: More → backup card → production file actions → fresh recovery key →
export confirmation dialog, before exclusive snapshot/encryption/save. No new
account, permission or network prerequisite. Add Persian «کپی کلید» beside the
key, wrapping below it when width/text scaling requires it. Only an explicit tap
writes the exact displayed key to Flutter Clipboard; no automatic clipboard
write. Explain briefly that other apps may access this sensitive clipboard.
Show Persian success or actionable failure feedback, prevent duplicate pending
copies, allow retry and safely ignore completion after dialog disposal. Copy is
not safe-storage acknowledgement: the existing checkbox alone enables saving,
and cancellation/per-export reset remain unchanged. Emphasize unrecoverable key
loss using the shared bold title typography, not a local font-weight override.

No domain, durable state, backup format, migration, dependency, import or native
build/install changes; do not touch the separate Gradle memory configuration.
Related consumers are the existing backup card and file actions; their save and
cancellation guarantees remain unchanged. Evidence required: mocked exact
clipboard payload, no automatic copy, failure/retry, pending duplicate prevention,
dismissal safety, acknowledgement isolation, emphasized warning, RTL Light/Dark
narrow/large-text standard targets, plus existing card/file-action regressions.
Run formatter, analyzer and focused tests serially due to host memory limits.
Native clipboard/privacy behavior and independent acceptance review remain
unexecuted release-maintainer checks; existing Priority 1 release blockers stand.

### Implementation and verification evidence

Implemented: adjacent/wrapping themed copy button, exact key copy only on tap,
Persian clipboard sensitivity and live success/failure/pending feedback, pending
admission guard and mounted check. Shared titleLarge (bold w700) emphasizes loss;
checkbox/save/cancel/per-export semantics remain unchanged. No secrets are logged.
No domain decision, persisted schema, format, migration or dependency changed.

Executed serially:
- `dart format` on the two changed Dart files: passed.
- `flutter analyze`: no issues (76.8s in the captured final run).
- `flutter test --concurrency=1` for recovery_key_dialogs_test,
  backup_settings_card_test and file_recovery_backup_actions_test: 13 passed.
- `git diff --check`: passed.

Dialog regressions prove no automatic write, exact payload, failure/retry,
duplicate admission, dismissal during pending copy, copy not enabling save,
per-export reset, cancellation and shared bold warning. Light/Dark RTL checks at
360dp and 1.5 text scale pass without layout exceptions and retain at least
48×48dp copy targets. Existing production card → actions → acknowledgement →
encrypted-save journey and file cancellation/error/legacy tests pass.

Coverage: export dialog **Migrated**; import/legacy dialogs and backup card
**Intentionally Unchanged** (regression-tested, no shared theme changes).
The first analyzer invocation returned no captured result; the final captured
run above is the evidence. A stale four-day-old serial test runner was stopped
before the final analyzer/test sequence; no native tooling was run.

Limitations: whole-repository suite, native clipboard/privacy/screen-reader
checks and independent acceptance review were not executed. No native build,
install or personal-data access. Separate android/gradle.properties memory edits
were untouched. Owner: release maintainer; next action: isolated-device clipboard
review and existing backup release checklist. Exposure remains local-only and
Priority 1 partial/release-blocked; these widget results are not device-loss
readiness or native clipboard confidentiality evidence.
