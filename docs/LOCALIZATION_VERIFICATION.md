# Localization resource migration

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

## Existing failed checks: baseline comparison

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

These were not fixed or hidden by changing test expectations. Owner: maintainer.
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

Maintainer owns independent acceptance, the five existing failures, and native
device checks. No new language is exposed. Before activating one, explicitly
localize the pure-default projection/error/helper/calendar/adapter boundaries,
verify directionality and formatting on actual routes, and preserve calendar/
recurrence/storage-unit semantics. This change does not close the existing native
authentication, reminder, backup or other feature release gates. Release build,
native screen-reader/notification/authentication execution and independent
acceptance were not run; debug compilation and Flutter tests are not substitutes.
