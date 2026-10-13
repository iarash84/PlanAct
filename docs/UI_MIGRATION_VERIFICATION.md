# UI design-system migration checkpoint — 2026-10-06

## Single-page commitment creation — acceptance contract (2026-10-13)

- Entry: global Quick Add → Commitment and existing direct capture routes; no new permission/account prerequisite. Title and existing one-off/recurring scheduling stay visible; optional details, reminders, package credit and financial expectation expand in place. No new schedule mode or semantic default.
- Success: explicit date/time and valid domain inputs, an editable live summary, one final save, durable creation followed by Today/Calendar refresh. Cancellation writes nothing; validation and persistence failures retain all inputs for correction/retry. Saving disables edits and duplicate submission.
- Trace: QuickCaptureSheet → HomeShell._saveCapturedCommitment → CreateCommitmentPlan → transactional production repository → _refresh → Today/Calendar/details/reminder and financial projections. Preserve this command path, calendar/termination rules, separate count and credit, and post-commit notification outcomes.
- Persistence: presentation change only; no schema/dependency/migration or backup-format change. Existing restart/backup coverage remains applicable; root creation/cold-reopen tests must exercise the new form.
- Evidence: widget journeys for optional sections, validation, retry/cancellation, pending save, narrow RTL Light/Dark with large text and keyboard; production recurrence/root refresh/cold reopen; full regression suite, formatting and analyzer. Native keyboard/accessibility and independent acceptance remain unexecuted until recorded. Maintainer owns device/release acceptance; do not claim release readiness from automated checks alone.

Implemented scope: single-page capture, separate optional sections retaining draft state, live summary, pinned actions, explicit existing scheduling inputs and unchanged durable command/refresh path. All text fields and form focus are disabled while saving; retry preserves the draft. Credit validation expands the affected optional section. No dependency, schema, migration, durable default or backup-format change.

Regression notes: the new empty-after-edit credit journey exposed an existing copyWith fallback retaining the previous units; explicit draft clearing now rejects submission without changing recurrence count. Previous coverage checked initial invalid credit but missed clearing a previously valid value. Narrow 320dp/2x keyboard coverage exposed horizontal date/time and finance overflow; these controls now stack without reducing text scale. A configured-credit journey also exposed expansion PageStorage identity colliding with nested text-field scroll storage; stable ordinary section keys and maintained child state avoid that collision. These are local form corrections, not ledger/history changes.

Coverage: Quick Capture migrated; Quick Add subtitle updated. Shared form shell, date picker, theme/tokens, Today, Calendar, details, Finance, reminders, backup and native adapters intentionally unchanged. Existing route tests retain durable/consumer assertions and replace step navigation with in-place edits.

Validation (2026-10-13, Windows, Flutter 3.47.5 / Dart 3.13.4, uncommitted working tree on `feature/new-capabilities` based on `b10603c`; no release artifact): dedicated form/draft checks passed (11); the final focused form/tag/root run passed all 21 tests. The stable final `flutter test --no-pub` run passed **787 tests** in about 4m30s. `flutter analyze --no-pub` found no issues; `dart format --output=none --set-exit-if-changed lib test` checked 307 files with no changes; `git diff --check` passed. Raw local output remains in ignored `build/verification/commitment-single-page-final-tests.log`.

Earlier attempts exposed the documented form defects, step-dependent root expectations and scrolling before layout settled. An overlapping test invocation also hit the loaded Windows SQLite DLL; no simultaneous test invocations were used for the successful final run. The first full attempt included edits during execution and is superseded by the stable final run, not accepted as evidence for the final code.

| Acceptance scope | Evidence | Result / remaining gate |
| --- | --- | --- |
| One-page create, validation, optional input retention, collapsed-credit correction and failure/retry | `quick_capture_sheet_test.dart`, `commitment_draft_test.dart`; explicit chosen date/time and independent expected credit/financial/reminder values | Passed locally; schedule count and credit remain separate. |
| Saving blocks duplicate submission, pointer, keyboard and focus edits | Pending-save widget journey asserts disabled save/cancel, disabled title and absorbed form input, then completes the same save | Passed locally; native keyboard behavior remains a device check. |
| Narrow RTL, Light/Dark, 2x text, keyboard inset, reduced motion | 320dp form journeys and production recurrence route matrix | Passed locally; no device screenshot, screen-reader or profile-performance certification. |
| Actual entry paths, refresh and durability | Direct Today create in `widget_test.dart`; Quick Add recurrence matrix verifies Today/Calendar and production database cold reopen; hybrid preview/prepare journeys retain their assertions | Passed locally; existing native reminder gates remain unchanged. |
| Related consumers and backup/migration regressions | Full 787-test suite includes finance, inbox, Today, Calendar, migration and backup tests | Passed for automated coverage; no blanket guarantee for untested platform behavior. |
| Independent acceptance and native/release checks | Not run | Maintainer owns review plus native keyboard/screen-reader and signed artifact validation before release. Development verification only; no release-ready claim or waiver of inherited gates. |

Implementation: complete for this bounded form redesign. Automated verification: passed. Self-review compared the contract with correction, missing-input, cancellation, retry, pending-save, recurrence and downstream counterexamples; this is not independent sign-off. Independent review and native device/release acceptance remain unexecuted.

## Scope and integrity

This is an implemented presentation migration, not an audit-only deliverable. The shared theme now separates business semantics from brand roles, provides brightness-specific contrast pairs, improves typography/component treatments, and constrains root content and sheets. Calendar, shared forms/date picker, Finance picker, Inbox, startup, Today and root navigation received focused changes. No database schema, domain lifecycle, historical data, authentication, reminder intent, financial matching or backup behavior changed. No dependency, font asset or migration was added.

The existing system-sans font remains an explicit limitation. No licensed Persian font was available in repository assets. Platform font shaping/metrics still require real-device review.

## Coverage inventory

Statuses describe implementation/source review, not universal visual certification. “Migrated” includes surfaces consuming changed shared themes even when local composition remains unchanged. “Intentionally Unchanged” identifies retained composition and its reason. All listed surfaces were considered; none is claimed device-certified.

| Surface | Status | Scope / reason |
| --- | --- | --- |
| Root shell and navigation | Migrated | Removed repeated AppBar logo; theme-owned primary selected container, readable 840dp content width, reduced-motion-aware page transitions. Existing navigation destinations and page controller retained. |
| Today / Attention / Next | Migrated | Brightness-aware information/status accents and shared typography. Central domain classification and actions preserved. |
| Commitment rows | Migrated | Success/attention/inactive roles; cancellation/archival no longer error-colored. Text/icon labels retained. |
| Calendar | Migrated | Holiday information, selected/unselected foregrounds and shared radius retained. Follow-up phone fix fits seven RTL columns without horizontal scrolling, uses compact weekday labels with full semantics, and measures text-scale-aware cell height. Narrow target-width exception documented in DESIGN_SYSTEM/AGENTS/PRD. Existing holiday coverage warning and all reasons preserved. |
| Quick Add | Migrated | Shared form action overflow, live error announcements, typography, fields/buttons/sheet treatment. Local scheduling and default semantics retained. |
| Quick Capture | Migrated | Shared form changes and reduced-motion-aware step switch. Capture command, draft, retries and progressive disclosure preserved. |
| Commitment Details | Migrated | Shared typography, Material fields/cards/dialogs/actions. Existing occurrence, reminders, tags, financial expectation and historical controls retained; no new detail-page architecture. |
| Finance | Migrated | Shared themes/typography; duplicate Jalali picker removed in favor of shared accessible picker, aligning month-control direction. Ledger/source-of-truth and save failure semantics unchanged. |
| Inbox | Migrated | Review warnings use attention rather than error; state panels scroll safely; shared component themes. Raw SMS/privacy and confirmation unchanged. |
| Transaction relationship | Migrated | Shared fields/buttons/cards/typography; existing scrolling, saving guard, error feedback and many-to-many confirmation retained. |
| More | Migrated | Root readable width and shared typography/list treatment; existing routes retained. |
| Settings / About | Migrated | Shared typography/cards/buttons/list treatment. About retains appropriate brand asset. No setting defaults changed. |
| App lock and lock settings | Intentionally Unchanged | Existing lock panel already scrolls and uses semantic theme roles. It inherits typography/button changes; root coverage, device authentication, lifecycle and persisted setting behavior deliberately untouched. |
| Flutter startup | Migrated | Static logo/title with scroll-safe content and named progress; removed decorative glow, shadow and entrance controller. Loader/error/retry behavior preserved. |
| Android launcher/native startup | Intentionally Unchanged | Inspected actual launcher and adaptive/light/dark resources; existing navy/teal artwork and brightness-specific backgrounds retained. No native release/device evidence obtained. |
| Dialogs / sheets / forms | Migrated | Central popup, segmented-button and sheet themes; 640dp sheet cap; overflow form actions and live errors. Unique product confirmations retained. |
| Jalali date picker | Migrated | Explicit grid dimensions avoid dialog intrinsic-viewport failure; scalable cells, selected-date semantics and horizontal overflow retain targets. Finance and capture reuse it. |
| Reminder controls / permissions | Migrated | Shared Material theme/typography; existing platform permission and command/reconciliation handling preserved. |
| Tags and financial expectation editor | Migrated | Shared fields, chips, dialogs, buttons and typography; local wrap-based metadata/action patterns retained. |
| Backup and holiday package settings | Intentionally Unchanged | Existing cards/actions inherit shared theme. Destructive confirmation, trust approval, import/restore exclusions and security release gates not altered. |
| Loading / empty / error / saving / disabled states | Migrated | Shared progress theme, live form errors, inbox scroll-safe state panels and retained operation-specific Persian feedback. No replacement universal state widget or swallowed exceptions introduced. |

## Automated evidence

- New regression suite: `test/widget/design_system_test.dart`, eight tests covering Light/Dark normal-text contrast of Material and semantic pairs, 320dp RTL calendar target dimensions and 200% text scale, picker/form overflow and reduced motion.
- Contrast assertions require at least 4.5:1 for every tested foreground/background pair, including business foregrounds on scaffold surfaces. Tests do not certify arbitrary alpha blends or every external bank color.
- Existing focused journey run: 22 tests passed across shared calendar/reminders, capture retry, root create/navigation/startup, finance transaction form and new design-system tests.
- Initial full run exposed picker intrinsic-dimension failures affecting three flows. Corrected by giving its grid explicit calculated height; focused rerun passed all formerly failing flows.
- Static analysis after migration: no issues found.
- Final post-fix full run: flutter test --no-pub — 343 tests passed in approximately 72 seconds.
- Final flutter analyze --no-pub: no issues found (5.8 seconds). Formatting completed and git diff --check passed.

## Calendar phone follow-up validation

- Focused files: calendar_page.dart, PersianDateFormatter compact weekday labels, design_system_test.dart and new calendar_responsive_test.dart; governance/spec/product requirements updated with the bounded target-width exception. Previous tagging, Today, Settings and Finance work was preserved.
- Twelve new widget cases cover 320/360/390dp, Light/Dark, RTL and 100%/200% text scale. They assert no horizontal scrollable, all weekday columns in bounds and RTL order, all 31 date targets in bounds and selectable with full Persian semantics, and month navigation without overflow. Existing holiday/count/selected-day/reminder and picker regressions also pass.
- Focused Dart formatting completed. Flutter analyze: no issues found. Final flutter test --no-pub: **375 tests passed**. Git diff --check passed.
- No domain/persistence/schema/backup behavior, dependency or migration changed. Physical-device font metrics, TalkBack and visual acceptance remain unverified; this is not native release certification.

## Remaining production validation / limitations

- No Android physical-device screenshots, TalkBack/focus traversal, native date/time/authentication dialogs, system bars/recents evidence, or profile frame/memory measurements were collected.
- Existing Android/native integration gates remain separate; Flutter tests do not prove security or notification release readiness.
- The Calendar-page follow-up supersedes the migration's horizontal-scroll behavior: all seven columns fit even on narrow phones. At 320dp, day targets are approximately 40dp wide with at least 48dp height; this explicitly documented exception trades minimum target width for simultaneous weekday visibility. Text scaling, holiday/count cues and full Persian semantics remain. The modal date picker intentionally retains minimum 48dp cells and horizontal scrolling when needed; no shared picker consumer changed in this follow-up.
- Root uses existing bottom navigation rather than introducing a rail or new state-management architecture. The readable width cap is not a complete tablet-specific redesign.
- Test coverage demonstrates specified pairs and journeys, not exhaustive screenshots of every content combination, brightness, text scaler or viewport. Additional device visual acceptance is required before claiming comprehensive production UI certification.
- All durable domain and product release limitations in existing verification documents remain in force.
