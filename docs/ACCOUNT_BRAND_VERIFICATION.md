# Account and brand verification

## Brand acceptance contract — recorded before implementation, 2026-10-12

This record covers BRAND only. Account requirements, implementation and evidence belong to the parent mission and are not claimed here.

- Outcome/entry: opening the existing root shell, Today, Calendar, Finance, Inbox, More, Settings or a pushed/modal consumer shows one shared restrained green + navy/teal identity derived from the actual launcher artwork. No permissions, account creation or network required for this presentation change.
- Success: both brightnesses have explicit primary green, secondary navy-family and tertiary teal roles; foreground/container pairs meet 4.5:1 normal-text contrast, essential focus/selection controls 3:1. Selection retains labels/icons; disabled controls remain readable and cannot invoke actions. Business status and commitment identity palettes stay independent and unchanged.
- Failure/cancellation/retry/Undo: existing behavior and feedback are retained, including form cancellation, errors and retry; this task adds no command or mutation needing Undo. Shared form errors remain Material error, not brand green.
- Trace: existing navigation/settings display-mode action → existing application/settings path → unchanged domain/persistence → root MaterialApp rebuild → shared ThemeData → root, pushed and modal consumers. Brand colors themselves are static presentation data; no durable writes, schema, migrations, backup changes, financial reinterpretation or permission changes.
- Scope: shared brand tokens/theme and their verification/documentation only. Preserve Persian RTL, existing sans/line heights, target sizes and motion. No account domain, forms, database, AGENTS or PRD account requirement changes; no new dependencies; no logo repetition.
- Evidence: asset pixel provenance, contrast/state tests, shared consumer tests, relevant existing route/layout regressions, analyzer/format checks, reproducible Light/Dark component artifacts where feasible. Generated goldens are regression artifacts, not human visual approval or native font/accessibility evidence.
- Minimal plan: explicitly define shared brightness-aware brand roles; centrally style selection and readable disabled actions; retain existing neutral surfaces to avoid native splash drift; review existing consumers and document exclusions; validate automated evidence independently of release acceptance.

## Brand asset inspection

The actual 1024×1024 launcher PNG was decoded with Windows System.Drawing, sampling every 16th pixel and quantizing channels downward to 16-value bins. Frequent bins include navy #003050 (123 samples), #002040 (109), #003040 (85); green #30E080 (72), #40F080 (60), #40F070 (54); teal #10D0B0 (48), #00C0B0 (46), #00B090 (43). Pale cool bins also occur. This sparse histogram is family evidence, not exact palette extraction or visual inspection; transparent black samples were not interpreted as brand color. Launcher configuration independently specifies #062B3A. The image-reading tool was unavailable/unsupported; no visual review is claimed. UI tones deliberately darken/lighten these families for contrast instead of copying neon pixels.

## Brand implementation / evidence

Implemented: one shared explicit green primary, navy secondary and teal tertiary scheme, with separate Light/Dark foreground/container pairs; shared selected chips/segments and readable disabled filled/outlined/text buttons. Neutral scaffold/base surfaces, status/identity palettes, typography, RTL, motion and all account code remain unchanged. No domain decisions, migrations, dependencies, durable writes or backup changes.

### Brand surface coverage inventory

Statuses below describe source-level shared-theme adoption, not human screenshot approval. All listed consumers were inspected for this scoped token change; native presentation remains unverified.

| Surface / consumer | Status | Scope and reason |
| --- | --- | --- |
| [Root shell/navigation](../lib/app/planact_app.dart) | Migrated | Root supplies both shared themes; labelled navigation indicator inherits green container. No navigation changes. |
| [Today](../lib/features/today/presentation/today_page.dart) | Migrated | Brand headings/actions inherit scheme; attention/info and commitment identity stay independent. |
| [Calendar Month/Week](../lib/features/calendar/presentation/calendar_page.dart) | Migrated | Mode segments, today's heading and navigation inherit shared roles; identity and holiday colors unchanged. |
| [Finance](../lib/features/finance/presentation/finance_page.dart) | Migrated | Shared actions/fields/cards inherit scheme. Bank identity color exceptions and financial status colors intentionally unchanged; no account/form edits. |
| [Inbox](../lib/features/inbox/presentation/inbox_page.dart) | Migrated | Shared action/progress/empty brand cues inherit scheme; warning/error/review semantics unchanged. |
| [More](../lib/app/planact_app.dart:1637) | Compliant | Shared cards/list tiles and pushed Settings route; no feature-local brand palette. Backup/holiday controls inherit shared buttons. |
| [Settings](../lib/features/settings/presentation/settings_page.dart) | Migrated | Selected display-mode chips inherit shared container; root rebuild still updates pushed route. |
| [Quick Capture](../lib/features/capture/presentation/quick_capture_sheet.dart), Quick Add and Details | Migrated | Existing theme-based fields/buttons/modal surfaces inherit roles; no form, lifecycle or mutation changes. |
| [Shared form sheet](../lib/core/presentation/planact_form_sheet.dart) and [date picker](../lib/core/presentation/planact_jalali_date_picker.dart) | Migrated | Shared actions/focus/selection inherit scheme; live errors and holiday roles remain independent. |
| Reconciliation/tag forms and dialogs | Migrated | Theme-based actions/fields inherit scheme; existing Material error treatment retained. |
| [App Lock](../lib/app/app_lock.dart) | Migrated | Existing scheme-based protection surface inherits shared brand roles; no authentication changes. |
| About, startup/splash and launcher | Intentionally Unchanged | Existing logo brand moments retained. Native splash and Flutter scaffold background remain matched; no decorative logo repetition. |
| Loading/empty/error/saving/disabled views | Migrated | Theme progress/actions change centrally; readable disabled text and non-activation tested. Error/status palettes and existing retry behavior retained. |
| Typography, motion, identity/status colors and external bank/provider identity | Intentionally Unchanged | Independent meanings and established Persian/RTL geometry must not become brand aliases. |

### Golden portability correction contract — 2026-10-13

Scope: test-only correction for the Light/Dark gallery, not a production theme or font change. Preserve the existing Windows baselines and use separate Linux baselines from the actual Flutter 3.47.5 CI failure artifact. Select by the real host OS (not Flutter's simulated target platform); retain exact pixel comparison and all contrast, interaction, RTL and modal assertions. Do not skip CI checks or introduce percentage tolerance. No persistence, migration, backup or dependency impact.

Evidence required: validate the artifact's master images against the committed baselines before importing its Linux test images; pass normal Windows gallery tests and analyzer/format checks; rerun Linux CI. Imported CI outputs are regression candidates, not independent visual approval. Maintainer/release reviewer owns the next Linux run and visual inspection; unresolved Linux execution or visual acceptance must not be described as verified release readiness.

Correction evidence: both artifact master PNGs matched the existing committed PNGs by SHA-256 before importing the two Linux test PNGs into `test/widget/goldens/linux/`. Windows references remain untouched. The fixture now selects Linux references on an actual Linux host and existing references otherwise; unsupported/unverified hosts are not certified by this change. Normal Windows run: all four brand tests passed; Dart formatting unchanged; full Flutter analyzer reported no issues; diff whitespace check passed. No full-suite, Linux rerun, Android build or independent visual acceptance is claimed. Linux baselines are imported observed outputs, not newly executed verification. The next Linux CI run remains required, and independent visual review remains an acceptance gap owned by the maintainer/release reviewer.

Regeneration: run the brand test in golden-update mode separately on each supported real host with pinned Flutter 3.47.5; Windows updates the original paths, Linux updates the Linux subdirectory. Review image changes before committing; never copy one host's output over the other's references.

### Automated evidence and reproducibility

- [Brand tests](../test/widget/brand_theme_test.dart): four checks passed in golden generation. Both brightnesses test all six brand pairs at ≥4.5:1, primary text on scaffold, focus on highest surface at ≥3:1, disabled filled text at ≥4.5:1, selection role resolution, unchanged status extension, disabled non-activation, 48dp filled target, RTL and modal theme inheritance.
- [Light artifact](../test/widget/goldens/brand_light.png) and [Dark artifact](../test/widget/goldens/brand_dark.png): 400×800 synthetic shared-control gallery, not full product screenshots. Regenerate with Flutter test golden-update mode targeting [brand tests](../test/widget/brand_theme_test.dart); normal test mode verifies baselines. Test font does not prove native Persian shaping. No image inspection tool/human visual sign-off was available.
- Focused files formatted. Full analyzer passed with no issues. Normal-mode regression run passed all 75 tests across brand, existing design system, pushed Settings/Today/Finance refresh, Today identity/Calendar toggle, Calendar Month/responsive, Quick Add/Capture, Finance layout and Inbox review. This includes narrow screens, doubled text scaling and both brightnesses where covered by those suites; it does not certify every native surface.
- Product note: no user-visible domain default or product behavior changed. Existing PRD Persian/RTL, display-mode and readiness requirements remain intact; no PRD account requirement or AGENTS edit is necessary for this presentation-only alignment.

### Acceptance gaps / exposure

Implementation is complete for the bounded shared palette/state treatment; verification is automated and partial, not release acceptance. Native screenshots, real Persian font rendering, screen-reader/focus journeys, pressed/hover overlays on actual devices and independent visual acceptance are unavailable in this task. Owner: maintainer/release reviewer; next action: review generated artifacts and actual root/pushed/modal journeys in both brightnesses on a reference device, including narrow screens and large text. Exposure: development checkpoint only until acceptance; no existing native/data-integrity gate is waived. No app-wide visual approval or account capability completion is claimed.


## ACCOUNT acceptance contract — 2026-10-12 (separate from BRAND)

Recorded before account behavior changes.

- Outcome/entry: Finance navigation → افزودن حساب or account عملیات/ویرایش; account picker creation uses the same Finance form. No network, SMS permission or banking credentials required. Name and visibly selected type are sufficient; bank/card/IBAN/account number are optional, independently editable strings preserving leading zeros. Never infer bank, type or identifiers from names/numbers.
- Success: field-specific Persian validation normalizes Persian/Arabic digits with the shared formatter; supplied card is 16 digits with checksum, Iranian IBAN is IR + 24 digits with mod-97 checksum, account number is 1–30 digits (no institution-specific checksum claim). Blank optional fields are accepted. Create and optional exact IRR opening entry commit atomically. Validation/save failures retain form for retry, cancellation writes nothing, pending save blocks duplicate actions/dismissal.
- Editing: explicit save compares the original editable fields against fresh durable state in the write transaction; conflict rejects without overwrite, retaining fresh status/currency. Metadata editing never adds/changes ledger entries, balance, matches or history. Clearing optional values is supported; correction is another explicit edit, no automatic financial Undo.
- Display/privacy: informational shared-theme card, readable wrapping name/type/explicit bank/status and exact rebuilt ledger balance, no payment-card imitation. Identifiers masked by default including semantics, individually explicit reveal/hide, reset on background/update. Clipboard requires a separate warning/confirmation and gives Persian success/failure; no automatic copying, no PIN/CVV/password storage, logging or credential fields. Masking is presentation protection, not database encryption or clipboard control.
- Durability/compatibility: use existing versioned per-account schema metadata if suitable; absent legacy metadata means no identifiers. Preserve SQLite schema 18, generated tables and strict trusted backup signatures if no schema change. Test cold file reopen, legacy defaults, exact schema compatibility and production snapshot/validated restore. Older binaries are not approved writers for new metadata until independent downgrade acceptance.
- Path trace: Finance navigation → shared retryable account sheet → FinanceUseCases create/edit → domain identifier validation → Drift transactional fresh admission + account row/versioned metadata (and opening entry only for creation) → sheet success → Finance refresh/onDataChanged → account pickers and ledger consumers read durable account identity; balance remains ledger-derived. Existing archive/restore must not restore stale editable metadata.
- Scope/non-goals: account metadata/create/edit/display/copy only; preserve brand theme/goldens and unrelated work. No banking integration, payment/transfer initiation, credentials, automatic bank detection, new currency migration, ledger correction redesign or broad app redesign.
- Evidence required: domain validation/leading zeros; transactional conflict/failure/ledger preservation; production cold reopen/legacy/backup strictness; real Finance creation/edit retry/cancel and picker regression; masked/reveal/copy success/failure semantics; narrow 320dp/large-text RTL in Light/Dark. Native clipboard/IME/screen-reader/background privacy and independent review require device/reviewer evidence, separately tracked, not inferred from widgets.

### ACCOUNT minimum plan and exposure

Domain identifiers → durable versioned metadata and fresh compare-and-edit command → shared-theme retryable form and informational card → regression/backup evidence → PRD/AGENTS/privacy documentation. Account implementation and automated verification will be reported separately. Development-only checkpoint; no release readiness until maintainer/release reviewer completes native and independent acceptance.


## ACCOUNT implementation and verification checkpoint — 2026-10-12

Implementation: optional validated string identifiers, explicit editable bank/type, retryable create/edit sheets, wrapping informational account cards, default masking in cards/forms, explicit reveal/hide and foreground-exit remasking, separately confirmed clipboard copy with Persian feedback. Both Finance and picker creation reuse the same form. Opening balance remains an exact atomic ledger entry; metadata edits leave ledger/history/matches untouched. No banking credentials, bank inference or payment-card presentation is introduced. Existing BRAND contents, shared theme and golden assets are preserved; account surfaces consume them without local palettes.

### Durable decision and compatibility

The existing per-entity metadata convention is reused: per-account JSON version 1 under the account-identifiers metadata key, containing nullable canonical strings. Missing metadata means empty identifiers; unsupported versions or malformed supplied values reject reads rather than silently inventing data. Account row plus metadata plus optional opening entry commit transactionally. Compared editing reads fresh row/metadata in the transaction, compares original name/type/bank/identifiers and writes only editable columns/metadata. Fresh currency/status are retained. Archive/restore writes only status; legacy snapshot save is creation-only in the production adapter. The separate atomic-editing contract avoids adding persistence requirements to unrelated repository implementations. No schema migration, generated table change, trusted signature change or dependency was added.

Schema 18 and strict backup validation are unchanged. Snapshot/validated replacement and cold reopen preserve exact identifiers/leading zeros and ledger values. Older readers may ignore identifiers; this does not approve older writers, whose snapshot edits may overwrite bank/name/type without new conflict semantics. Owner: maintainer; next action: explicit older-binary read/write acceptance before permitting downgrade. Exposure: older writers are not approved for new account metadata. No semantic downgrade safety is claimed.

### Executed evidence

- [Domain identifier tests](../test/unit/account_identifiers_test.dart): optional blanks, shared Persian/Arabic digit normalization, leading zeros, checksum/structure rejection and short-value masking. Checksums do not prove ownership, account existence or bank identity.
- [Account repository tests](../test/repository/account_metadata_test.dart): legacy-empty metadata, atomic opening creation, file-backed cold reopen, production snapshot/strict validation/replacement, fresh status/currency retention, optional clearing, stale edit rejection, archive/restore without metadata overwrite and injected transactional rollback.
- [Account widget journeys](../test/widget/account_flow_test.dart): real Finance create/edit retry and refresh, invalid opening retained, optional omission/no bank inference, cancellation, field errors, masked semantics, explicit reveal/hide/background remasking including edit fields, clipboard cancel/success/failure, 320dp doubled-text informational card in Light/Dark.
- Existing Finance layout/loading/tags/transaction form, Inbox account-selection, Today/Settings/Finance refresh, ledger/correction, production encrypted restore/full-state/snapshot and strict historical-schema compatibility suites passed. Admission/Inbox test setup now uses the safe status command instead of snapshot upserts; assertions were not weakened. Historical migrated fixtures and negative schema-tampering checks remain intact. BRAND golden tests passed without regeneration.
- Final selected regression run: **115 tests passed** across 18 test files. Full analyzer: **No issues found**. Touched Dart code formatted; whitespace/diff check passed. An existing transaction-form test emits a missed-tap warning while testing disabled submission; the test passes, but this warning is not treated as evidence that the disabled action received a hit.
- Process note: previous creation closed before validation and editing used stale snapshot persistence. The missing checks were retryable form admission and fresh transactional metadata comparison; new widget/repository checks directly protect those acceptance criteria.

### Scoped visual coverage

Finance account list: Migrated to wrapping shared-theme informational cards with exact ledger balance. Finance create/edit and picker-create modal: Migrated to the shared form sheet and progressive optional details. Account picker rows and other financial consumers: Intentionally Unchanged; existing selection semantics and refresh are retained and regression-tested. Shared theme, BRAND gallery and unrelated screens: Intentionally Unchanged by ACCOUNT; no app-wide redesign or native visual approval is claimed.

### Acceptance status, unexecuted checks and release decision

Implemented scope is complete for this bounded ACCOUNT path; automated verification passed. Release acceptance remains **Partial**. This is agent self-verification, not independent sign-off. No full-repository suite or native device run is claimed. Masking is presentation-only, not local database encryption, screenshot protection or clipboard revocation. Sensitive-flow documentation states that identifiers persist in SQLite/backups and clipboard data can escape through OS history/sync/other applications.

| Missing evidence / gate | Owner | Next action | Exposure decision |
| --- | --- | --- | --- |
| Clipboard access/failure, IME suggestions/history, background/recents and screen-reader identifier privacy | Maintainer / native QA | Run isolated reference-device create/edit/reveal/copy/lifecycle journeys; verify limits and Persian feedback | Development checkpoint only; blocks privacy release claim |
| Native Persian shaping, mixed IBAN text, keyboard/focus, Light/Dark contrast and narrow large-text forms | Design/accessibility reviewer | Inspect actual Finance/picker modal journeys and card states in both themes | Blocks independent visual/accessibility acceptance |
| Independent contract review and counterexamples | Release reviewer other than implementer | Compare route, fresh-write, retry/cancel and durable evidence against this contract | No release-ready claim until accepted |
| Older-binary writing and existing production backup native gates | Maintainer / release reviewer | Exercise explicit compatibility policy and retain existing backup device-loss/rebind gates | Do not permit unreviewed downgrade or waive backup gates |
