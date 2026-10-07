# Backup verification checkpoint

## Automated evidence

Latest local checkpoint: 2026-10-05.

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
3. Verify the platform secure-storage key persists across cold restarts; verify
   missing/wrong keys reject import without changing current data. Do not clear
   the personal installation's storage or keys.
4. Exercise restore interruption around replacement/rebuild and restart. Check
   original-state safety recovery and no candidate UI before commit.
5. Confirm native reminder queue clearing/rebuilding, rejected notification
   permission behavior and absence of stale listener effects.
6. Review filesystem durability on Android. Dart flush and same-directory rename
   are used; full directory-fsync power-loss guarantees are not established.

The package key remains installation-bound. These exports are not portable
recovery after device loss or uninstall. Portable recovery requires an approved
product/security decision and separate implementation/tests. Priority 1 remains
open until applicable native release evidence exists; green host tests do not
waive that gate.
