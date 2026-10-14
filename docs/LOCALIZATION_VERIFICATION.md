# Localization resource migration

2026-10-14 Undo follow-up: new approved operation/confirmation/error/history copy is added with `x-planact-introduced: undo-2026-10-14`. The frozen original-template checksum is retained and excludes only that explicitly marked introduction; all catalog descriptions/placeholders and generated resources remain checked. No original Persian template is changed. This is the bounded Undo behavior change recorded in SCHEDULE_ACTUAL_VERIFICATION.md, not a new language or a localization-foundation waiver.

## Acceptance contract — 2026-10-13

User request: collect application-owned Persian copy into a structured resource
catalog, safely preparing later translations. This is localization foundation;
adding another language, language settings or changing calendar/currency policy
is outside scope.

- Entry paths: existing root navigation, creation/editing sheets, Settings/lock,
  Today, Calendar, Finance, Inbox, reconciliation, reports and backup routes.
  Existing prerequisites, commands, confirmation/cancellation/retry and Undo
  behavior must remain identical. No additional account/network requirement.
- Preserve Persian copy, punctuation, placeholders, accessible labels, RTL,
  Jalali selection/recurrence, exact integer monetary formatting and Material/
  Cupertino localization. Use a Persian ARB template with stable semantic keys,
  descriptions and typed placeholders; generate application localization APIs.
- Trace: widgets/application projections currently compose inline Persian copy;
  widgets dispatch the existing command/domain rules, write through the existing
  repositories, refresh and reconcile related consumers. Only copy retrieval
  changes. No database schema, settings, ledger, schedule, match, backup format,
  saved notes/categories, source evidence or parsing token changes are authorized.
- Pure domain code must remain independent of Flutter. Application-owned default
  messages outside widget contexts use a generated pure-Dart Persian companion
  from the same catalog, preserving legacy API/data semantics. A future language
  capability must explicitly localize these boundaries; this foundation does not
  claim a complete multilingual product.
- Exclude user data, bank-SMS recognition patterns, canonical persisted tokens,
  bundled holiday source datasets, numeric normalization and digit/separator
  definitions from blanket translation. Record remaining uses explicitly.
- Evidence: catalog generation reproducibility/content parity, analyzer, full
  regression suite, production-root Persian navigation/modal tests, critical
  lock/backup/money/calendar checks and locale-delegate/placeholder tests.
  Native authentication/notification evidence and independent acceptance are
  separate gates; automated tests must not claim those have been executed.

## Implemented scope

2026-10-14: **Persian-only foundation implemented**. `lib/l10n/app_fa.arb`
contains 1,177 unique messages/templates. Application-owned copy was extracted
from 74 existing source files, including routes, accessibility, validation,
projections and adapter messages. The root registers generated `AppLocalizations`
beside the existing framework delegates; isolated widget embeddings retain the
documented immutable Persian fallback. Standard resources and the 742 default
companion entries are generated from the same catalog. The default companion
has no imports or Flutter dependencies. See the [catalog maintenance guide](../lib/l10n/README.md)
and [ADR 0020](adr/0020-localization-resource-boundaries.md).

No language picker, locale preference, database schema/migration, backup format,
permission, state-management change or package-version upgrade. `intl 0.20.3`,
already pinned transitively, is declared directly because Flutter's generated
resources import it. Parser vocabularies, bank/holiday source datasets, persisted
financial notes/categories, canonical currency identity, numeric normalization
and all user/source text retain their prior semantics and contents.

## Verification evidence

Environment: Windows, Flutter 3.47.5 / Dart 3.13.4. Working tree based on
`5c79331c661562332d35307c8e6da0542998835c`, not a committed release revision.
Raw local artifacts are under ignored `build/verification/localization/`.

| Contract / check | Evidence | Result / limit |
| --- | --- | --- |
| Standard generation and unchanged package versions | `flutter gen-l10n`; `flutter pub get --enforce-lockfile --offline` | Passed; lockfile changes only `intl` dependency classification. |
| Pure-domain/default generation | `dart run tool/generate_persian_copy.dart --check`; generator/unit test | Passed; CI PowerShell/Bash check the companion; no additional generator package. |
| Exact original copy and placeholder handling | Frozen SHA-256 of pre-migration templates in `localization_resources_test.dart`; temporary exhaustive runtime parity test | Passed: all 1,177 Flutter outputs and 742 companion outputs matched original templates, including argument text with quotes, dollars, braces, Persian digits and line breaks. |
| Route resources, Persian root/delegates and cancellation | `localization_resource_consumers_test.dart`, `planact_localization_test.dart` | Passed; injected resource overrides reach Settings; production Light/Dark root, quick-add/capture/Jalali/time modal paths retain Persian/RTL and cancellation. This does not certify a second language. |
| Final localization and exact monetary regressions | `flutter test --no-pub test/unit/localization_resources_test.dart test/unit/currency_codes_test.dart test/unit/persian_money_text_test.dart test/unit/iranian_money_unit_test.dart test/unit/money_input_formatter_test.dart test/widget/localization_resource_consumers_test.dart test/widget/planact_localization_test.dart --reporter expanded` | Passed: 17 tests. |
| Broad regression, including domain/repositories/restore/lock/calendar/layout/routes | `flutter test --no-pub --reporter expanded` | 836 passed, 5 failed. The five identical cases also fail against isolated original source; see below. Full CI is not green. |
| Analyzer and format/diff | `flutter analyze --no-pub`; `dart format --output=none --set-exit-if-changed lib test tool/generate_persian_copy.dart`; `git diff --check` | Passed on final source. Longer resource references required eight brace-only lint fixes. |
| Android compilation | `flutter build apk --debug --no-pub` on final source | Passed. Debug APK SHA-256 `c0da2e09d3b2a1c689a1d3f841850e643540d196239c46d8a7638afd1923e94e`. No installation/device execution or release/signing certification. |

The full-suite run preceded the final brace-only formatting, six new resource
tests and the extraction of the unchanged Rial display label. Final analyzer,
focused tests, exhaustive resource parity and APK build cover those final edits;
the entire suite was not repeated without a new regression indication.

## Historical failed checks: baseline comparison

This section preserves the historical localization checkpoint. The current
repair and test status is recorded in the five-test follow-up below; the original
failure evidence is retained rather than overwritten.

An isolated `git archive HEAD` checkout in `build/verification/localization/baseline_check`
ran the same three test files with their original code and dependency versions.
The existing, unchanged SQLite native dependency cache was reused to avoid a
stalled native-library download; application sources/tests were the original
checkout. Result: 27 passed, the same five failed with the same assertions:

- `quick_capture_sheet_test.dart`: collapsed credit validation expects retained
  `۱۲۳۴۵`; the existing money input controller contains `12,345`.
- `sms_currency_review_test.dart`: both theme cases expect the ambiguous-unit
  error after saving; the existing visible/default-unit review behavior differs.
- `sms_editable_review_test.dart`: both narrow/large-text actual-transfer cases
  cannot tap the expected visible `واحد مبلغ` label.

At that checkpoint these were not fixed or hidden by changing test expectations.
Owner: maintainer.
Next action: compare each check with the approved grouped-money-input and explicit
SMS-unit-review contracts, then repair the affected test or behavior with an
independent acceptance decision. Exposure: existing Persian development paths
remain unchanged; the failing checks block a claim of green full CI/release
readiness. Localization-specific checks passed and no additional failing case
was found in the broad run.

## Acceptance review and remaining gates

Implementation status: **Foundation implemented**, not a multilingual product.
Automated verification: **Passed for the bounded resource/Persian-route scope**,
with the separately disclosed inherited full-suite failures. Self-review checked
source/copy parity, scoped diffs, parser/persistence exclusions and PRD/AGENTS
consistency. Independent reviewer/sign-off: **Not performed**.

The inherited failure status above belongs to the migration run; consult the
follow-up below for the repaired checks. Other-language/native/independent
acceptance gates are unchanged.

Maintainer owns independent acceptance and native device checks; the follow-up
below records resolution of the five inherited test failures. No new language
is exposed. Before activating one, explicitly
localize the pure-default projection/error/helper/calendar/adapter boundaries,
verify directionality and formatting on actual routes, and preserve calendar/
recurrence/storage-unit semantics. This change does not close the existing native
authentication, reminder, backup or other feature release gates. Release build,
native screen-reader/notification/authentication execution and independent
acceptance were not run; debug compilation and Flutter tests are not substitutes.

## Five-test repair follow-up — 2026-10-14

Acceptance contract, recorded before the repair:

- User outcome: resolve the five inherited failures against the latest approved
  PRD monetary-input/SMS-unit-review contract, rather than alter product behavior
  just to satisfy obsolete expectations. Entry paths are commitment capture after
  failed saving, and Inbox edit/cancel/save, including narrow RTL with 1.8x text
  in Light/Dark.
- Grouping may normalize the display of typed money; failed saving/reopening must
  preserve that formatted editing value and the exact canonical amount, session
  credit and reminder selections.
- Ambiguous SMS units visibly suggest the default. Opening the editor or
  cancelling an edited choice must preserve the unresolved draft/revision/source
  evidence and create no financial entry. Explicit saving of the chosen unit
  must preserve source evidence and convert the reviewed amount exactly.
- Exercise the actual unit dropdown rather than its floating decoration label;
  transfer source evidence must continue blocking income/expense confirmation
  after direction/unit edits. Keep all existing blocking assertions.
- Scope: focused test repairs and evidence updates; no database/schema,
  dependency, resource-copy or production behavior change unless investigation
  proves one necessary. Existing durable SMS/default-unit repository/route tests
  remain the persistence evidence. Run the three affected files, related
  money/default-unit/repository checks, analyzer/format and the complete suite.
  Independent acceptance/native checks remain separate.

Investigation: the latest PRD (money unit/financial input section) explicitly
requires grouped input and permits visible default-unit suggestion until explicit
review saving. The existing formatter and editor implement those rules; the
five failures reproduce before localization. The missed checks were stale
cross-feature assertions left over when those behaviors were approved, and
using a floating field label as the interactive target. The minimal repair
updates the checks while strengthening cancellation/input/evidence guarantees.

## Follow-up verification result

**Implemented:** focused repairs in `quick_capture_sheet_test.dart`,
`sms_currency_review_test.dart` and `sms_editable_review_test.dart`; no test
was skipped or disabled and the transfer-confirmation blocking assertions were
retained. Additional checks protect formatted editing state, exact amounts,
review revisions, cancellation and immutable original evidence. Only these
three test files and the two existing verification records changed. No
production code, resource catalog, schema/migration, dependency or backup change.

**Verified:** Windows, Flutter 3.47.5 / Dart 3.13.4, working tree based on
`363ded82aca0f2a56ee76ed13b45e26d915b5941`, 2026-10-14. Raw artifacts are in
ignored `build/verification/failed-test-repair/`.

| Check | Result |
| --- | --- |
| Reproduce the three original test files | 27 passed / same 5 failed before repair. |
| Repaired three test files | 32 passed / 0 failed, including all five original cases. |
| `flutter test --no-pub --reporter expanded` on repaired source | **847 passed / 0 failed**, including money formatter, explicit default review, production SMS admission/cold-reopen/backup, root routes and Light/Dark narrow/large-text cases. |
| `flutter analyze --no-pub` | No issues. |
| `dart format --output=none --set-exit-if-changed lib test tool/generate_persian_copy.dart` | Passed, 0 changes required. |
| `git diff --check`, scope and local documentation links | Passed. |

The five-test/full-suite regression blocker is **resolved** for this working
tree. This supersedes the historical five-failure status above; it does not
rewrite the original migration evidence or claim an executed release build/full
release CI. Self-review compared the updated assertions with the approved PRD,
preserved negative-path/evidence guarantees, and verified the scoped diff.

**Unexecuted / release status:** independent acceptance and native device/release
checks were not performed; there is no production behavior change requiring a
new native journey in this test-only repair. The existing SMS, monetary-input
and localization feature readiness/exposure decisions remain in their respective
records. Maintainer owns those independent/native gates. No new language,
product feature, release or deployment is introduced by this follow-up.
