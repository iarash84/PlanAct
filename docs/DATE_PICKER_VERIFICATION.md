# Shared Jalali date picker — responsive acceptance contract (2026-10-11)

## Outcome and entry paths

Offline users choosing a commitment start/end date, editing an occurrence or filling Finance's date field see a complete seven-column Saturday–Friday RTL grid within the dialog width. No permission/account is required for browsing. This user-approved responsive correction supersedes the initial oversized picker and its horizontal-scroll specification.

Trace: Quick Capture start/end → shared picker → draft → explicit create command → durable plan/occurrences → Today/Calendar; Details edit → picker → edit selection → existing explicit schedule command → durable versions/occurrences/reminder intent → refresh; Finance → picker → draft → confirmed write. The picker has no repository writer.

## Observable acceptance

- Fit all seven columns without horizontal scrolling. A normal 320/360/430dp-wide, 800dp-high phone at normal text scale exposes every day of a six-row month without scrolling. Limited height, expanded provenance or large text may require vertical scrolling, not horizontal scrolling.
- Measure weekday names; use full titles when they fit, otherwise distinct Persian compact labels with full-name semantics. Day semantics include weekday, Jalali date/year, selection and all typed reasons.
- Only dense Month/picker grids may use narrower-than-48dp targets when necessary. Preserve >=48dp height, non-overlapping regions and system text scaling; Week and other controls retain standard targets. Visual status icons are not separate targets.
- Day taps stage selection and show all overlapping weekly/official/special reasons beneath the grid. Expandable provenance retains source/version/scope. Explicit «تأیید تاریخ» returns the staged date; cancel/back discards it. A holiday never prevents selection or automatically changes schedules, reminders, entitlement or history. No time is invented.
- Reuse the bundled versioned provider and validated installed annual packages; no approximate lunar conversion or parallel dataset. Outside complete coverage show that missing markers do not guarantee a working day.
- Use shared Light/Dark holiday/attention roles and typography. Do not shrink text or disable scaling to fit.

## Scope and coverage inventory

- Shared modal picker: **Migrated** to fit-width cells, adaptive headings, staged confirmation and selected-day disclosure.
- Quick Capture start/end: **Migrated** interaction tests to explicit confirmation; existing creation/cancellation, cold reopen and Today/Calendar refresh paths retained.
- Details schedule edit: **Migrated** confirmation regression; preserves LocalDate and untouched input before application confirmation.
- Finance date: **Compliant** shared consumer; draft semantics unchanged. No new Finance date-specific durable journey claimed.
- Root pushed/modal provider scope: **Compliant** existing propagation seam; fresh provider getter retains installed annual packages.
- Calendar Month/Week and package import: **Intentionally Unchanged**; Month already fits width, Week retains standard targets. No app-wide visual redesign claimed.

No schema, migration, dependency, backup-format, logging or domain scheduling change. Public reference packages remain outside personal backup. Synthetic special-closure fixtures are not a shipped closure dataset.

## Verification status

Implementation: **bounded responsive picker implemented**. Verification: **scoped automated checks passed; native/independent acceptance pending**, not release-ready.

- Final [responsive regression run](../date-picker-responsive-results.txt): **68 tests passed**, covering ten picker checks, edit, design-system scaled layout, Quick Capture, tagged creation, root creation, nine recurrence creation/cancellation journeys with durable reopen/refresh, Calendar navigation/reminder details, responsive Month, holidays and Finance forms.
- Six new normal-text cases cover a complete six-row month at 320/360/430 × 800dp in Light/Dark: grid in viewport, every day hit-testable without scrolling, >=48dp height and staged selection. Two 320×640dp cases retain 2× text scale, incomplete coverage, adaptive labels, no horizontal scroll and no rendering exceptions. Overlap/provenance and full date semantics remain covered.
- [Static analysis](../date-picker-responsive-analyze.txt): no issues. Changed Dart files formatted; diff whitespace check passed.
- Prior 35 widget and 16 holiday checks proved the earlier holiday integration, not this responsive correction; their counts are not added to current evidence. No full application-suite or native acceptance claim.

Regression escape: earlier tests checked no render overflow and minimum target size, but did not check whether the grid actually fit the viewport. New checks cover grid bounds, no horizontal scrolling, complete six-row month hit visibility and confirmation/cancellation. Initial responsive runs exposed intrinsic-layout incompatibility and wrapped day numbers at large text; both corrected before final validation.

## Remaining checks and exposure

- QA/release owner: isolated native TalkBack/keyboard focus, real Persian-font rendering, device screenshots and compact hit-target usability; widget geometry does not prove these gates. Next action: review narrow-phone and large-text picker in both themes before release sign-off.
- Independent reviewer: compare actual creation/edit paths with this contract. Full installed-package-to-root-to-picker native journey and full application suite are not claimed by isolated seam/package tests.
- Holiday data owner: official-PDF independence, future-year factual coverage and actual special-closure dataset gates remain unchanged.
- Exposure: retain existing local date paths with explicit confirmation and incomplete-coverage warnings, without scheduling automation. Independent/native acceptance remains release-blocking; all pre-existing release gates still apply.
