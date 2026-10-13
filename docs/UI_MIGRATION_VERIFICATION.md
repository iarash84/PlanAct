# UI design-system migration checkpoint — 2026-10-06

## Presentation polish — acceptance contract (2026-10-13)

User outcome: clearer navigation and calmer presentation with the existing brand,
Persian RTL, domain actions and durable state preserved. Entry paths: root AppBar
menu, Today, embedded/standalone Finance, Reports, Calendar and shared form sheets.
The upper menu must retain creation/timeline and open the existing Reports/Inbox
routes without creating records or starting SMS ingestion. Finance has one header
when embedded and retains its header when standalone. Today groups retain every
action without nested card surfaces. Reports keeps its current filters, date and
read semantics while grouping controls. Loading/error/empty remain distinct;
retry/cancel/save guarantees remain unchanged. Motion uses existing tokens and
honors disableAnimations, without delaying commands or remounting drafts.

No schema, dependency, palette, font, default, ledger, notification or backup change.
Evidence required: actual menu navigation, existing affected widget journeys,
narrow RTL Light/Dark large-text/reduced-motion checks, analyzer and full tests.
Native visual/TalkBack/profile evidence and independent acceptance remain separate
unexecuted release checks owned by the maintainer. Existing platform/data gates
remain in force. Implementation and test results will be recorded below.

### Presentation polish implementation and coverage

Trace: root menu → existing `_openReports` / `_openInbox` → unchanged readers,
review commands and repositories → existing route refresh. New shortcuts perform
no write or scan. Finance composition only sets `embedded`; account-creation and
root hosts own the single header, while standalone defaults remain intact.
Today classification and action callbacks, report filters/reads, Calendar selection
and shared-form pending/save/cancel remain owned by their original paths.

| Surface | This change |
| --- | --- |
| Root / More | Root menu shortcuts, operation/destination divider, below-anchor placement, short title fade; More links retained. |
| Today / attention | Plain rows inside attention grouping cards; shared inline error/empty feedback; all callbacks retained. |
| Finance / account creation | Remove embedded duplicate headers; standalone header and ledger/filters/forms unchanged. |
| Reports | Wrapping date-control spacing, quieter supporting copy, stable progress slot, shared error/retry feedback. |
| Calendar Month | Short reduced-motion-aware selected-surface color transition; geometry, semantics and navigation unchanged. |
| Shared form consumers | Animated action-content size with readable pending progress; inputs, focus, keyboard, errors and command guards retained. Includes capture, quick add, accounts, SMS editors and financial expectation forms. |
| Details / scheduling / tags | Existing themed expansion and row treatments retained; inherits shared form action polish where applicable. No changes to correction or historical semantics. |
| Inbox / reconciliation | Existing review panels, consent, per-item pending feedback and confirm/recovery retained; Inbox gains a root shortcut only. |
| Settings / About / backup / holidays / reminders | Existing theme and confirmations retained; no new local styling, authentication or platform behavior. |
| Week / date picker / startup / app lock | Existing bounded/responsive or security-specific compositions intentionally retained. No decorative entry motion or new geometry. |

The four new widget cases cover upper-menu Reports/Inbox navigation and return,
no scan/request-permission call on Inbox entry (mocked native adapter), one root
Finance header, standalone Finance header, and 320dp/2x RTL Light/Dark menu with
disabled animations. Existing affected tests cover report kinds, Finance last-row
access, capture retry/pending guards, shared forms/calendar and root create.
The initial new test used an English back-tooltip helper and then lacked the SMS
platform mock; these test-harness issues were corrected. The final new four-case
run passed. The prior focused run passed the other 46 cases; full-suite final
results below supersede that intermediate run. No native visual claim is made.

Final verification: `flutter test --no-pub` passed **813 tests** in 4m26s;
`flutter analyze --no-pub` found no issues. Formatting checked all eight changed
Dart files with zero changes; `git diff --check` passed. The suite emitted debug
warnings about multiple test database instances and a non-hit test tap; these
were not failures and were not suppressed or used as native evidence.

Implementation is complete for the bounded presentation changes above. Automated
verification passed. Self-review checked menu cancellation/return, native scan
consent, single-header hosting, unchanged callbacks, pending form guards, and
reduced-motion final state against the contract. Independent review, physical
device visual/TalkBack/keyboard and profile-frame checks were not executed;
maintainer owns those checks before release. No claim of release readiness or
waiver of existing product release blockers is made. No domain, persistence,
schema, migration, dependency, backup or palette change was introduced.

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
