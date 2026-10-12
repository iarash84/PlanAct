# Focused QA fixes — acceptance and evidence

## Acceptance contract (2026-10-12)

Scope is limited to the five reported baseline test failures and Persian framework localization at the production app root. No redesign, domain semantics, schema, migration, broad dependency upgrade or device-data changes are included. QA-Account-1012 remains untouched. This correction pass performs no installation or device commands; existing user permission for non-destructive installation is not revoked. Uninstall, clear-data and phone-setting changes remain prohibited.

Entry paths and trace:
- Commitment Details correction → correction preview/confirmation → signed entitlement Adjustment and append-only audit → durable SQLite → ledger read ordered by occurredAt → encrypted backup restore → reconstructed state. Assert correction identity rather than insertion position; preserve every ledger field and exact full audit through restore and a second cold reopen. Failed validation retains existing backup safeguards. This test seam is not proof of the native backup journey.
- Contextual reconciliation → explicit financial-classification acknowledgement → application confirmation → durable financial write → refreshed related surfaces. Target the exact acknowledgement, settle scrolling, and verify checked state; do not bypass confirmation.
- Inbox → edit SMS suggestion → explicit currency/classification/timestamp review → transactional confirmation → Finance. Target semantic controls after scrolling settles. Cancellation must not write Finance; timestamp and classification safeguards remain required.
- Production PlanActApp → MaterialApp locale/delegates → root navigation and modal routes → framework-generated accessibility labels. Persian locale and RTL must propagate in Light and Dark; actual navigation tab and modal barrier semantics must use Persian framework strings. Cancellation of sheets must remain non-mutating. Existing custom Jalali date picker and persisted time semantics must not be replaced by Gregorian pickers.

Observable acceptance: focused regressions pass, full widget and unit/repository/scenario suites pass, analysis is clean, edited Dart is formatted, and debug APK builds if tooling permits. Dependency resolution adds only SDK flutter_localizations and required transitive packages. No new persistent data or migration is expected.

## Implementation chronology

The test-repair subtask completed before this record was written; this is a workflow gap, not a claim that its contract was recorded in advance. Localization acceptance is recorded before its edits. Parent instructions supplied the bounded test acceptance before delegation.

## Escape causes and release decision

- Backup test assumed the last temporally sorted row was the latest inserted correction; fixture clock dates and correction dates differ. Missing check: identity-based complete logical preservation, rather than aggregate remaining credit only.
- Widget tests used ambiguous/type-only or clipped controls and tapped before scroll animations settled. Missing check: unique semantic target, hit-testability, and observable acknowledgement state.
- Root RTL override and Persian app text did not install framework localization. Missing check: production-root framework semantics in both themes.

Native/TalkBack evidence and independent acceptance are not provided by Flutter widget tests or APK compilation. Owner: release QA; next action: independently exercise navigation, sheet dismissal/expansion, Persian announcement and date/time controls on a reference device in both themes, without altering existing personal data. Owner: product/release reviewer; next action: review this contract against logs and counterexamples. Release decision: no user-ready/release-ready claim; existing native, backup and domain release gates remain in force.

## Validation results

- Focused repaired regressions: 19 passed; original financial/currency/classification/timestamp assertions retained.
- Production-root localization: 2 passed (Light and Dark), including actual Persian tab/barrier semantics, RTL, sheet cancellation without writes, custom Jalali picker, framework time picker and expansion semantics.
- Full widget/unit/repository/scenario run after final fixes: 694 passed, zero failures (`build/qa-fix-full-tests-final.log`).
- Final Flutter analysis: no issues (`build/qa-fix-analyze-final.log`). Edited Dart files formatted.
- Localization exposed three existing route-test failures because Flutter's pageBack helper expects English tooltips. Tests now tap the actual BackButton, retaining navigation and refresh assertions. No production back-navigation behavior was changed.
- Dependency change: Flutter SDK flutter_localizations only; lockfile contains no unrelated upgrades or new transitive versions.
- Debug APK build: successful, assembleDebug 31.0 seconds (`build/qa-fix-build.log`); output build/app/outputs/flutter-apk/app-debug.apk. Final git diff --check passed.
- No schema, migration, persistent semantics, device installation or device-data changes. Native TalkBack/device checks and independent acceptance remain unexecuted as described above.

Logs are retained under build/qa-fix-*.log (ignored build artifacts, not committed evidence packages).

## Windows CI follow-up (2026-10-12)

- Bounded acceptance: retain the Commitment Details unsaved-edit confirmation and unchanged repository title while invoking the actual Material back button; no production, domain, persistence, dependency or CI changes.
- Reproduced the reported baseline: 702 passed, one failure. The remaining commitment-details test used Flutter's pageBack helper, which missed the localized Material tooltip and then looked for a nonexistent Cupertino back button. The earlier localization repair did not cover this test.
- Replaced that helper with a tap on the actual BackButton, retaining both original protection assertions. Escape check: rerun the entire suite after framework localization, including the unsaved-edit route rather than only successful save/refresh routes.
- Validation: Dart format unchanged; all 3 commitment-details tests passed; Flutter analyze reported no issues; full suite passed all 703 tests. The temporary local full-suite log was removed during user-requested cleanup.
- Release App Bundle build, signing, native/device checks and independent acceptance review were not executed in this follow-up. Passing the test stage does not claim full CI or release readiness; existing release gates remain unchanged.
