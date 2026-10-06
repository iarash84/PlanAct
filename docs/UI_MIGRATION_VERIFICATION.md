# UI design-system migration checkpoint — 2026-10-06

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
| Calendar | Migrated | Holiday information replaces error semantics, selected/unselected foreground correctness, shared radius, minimum cell targets and scalable horizontal calendar plane. Existing holiday coverage warning and all reasons preserved. |
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

## Remaining production validation / limitations

- No Android physical-device screenshots, TalkBack/focus traversal, native date/time/authentication dialogs, system bars/recents evidence, or profile frame/memory measurements were collected.
- Existing Android/native integration gates remain separate; Flutter tests do not prove security or notification release readiness.
- Calendar requires horizontal scrolling on very narrow screens or enlarged text to retain seven-column ordering and minimum target dimensions. This is intentional rather than shrinking digits, hiding holidays or clipping labels.
- Root uses existing bottom navigation rather than introducing a rail or new state-management architecture. The readable width cap is not a complete tablet-specific redesign.
- Test coverage demonstrates specified pairs and journeys, not exhaustive screenshots of every content combination, brightness, text scaler or viewport. Additional device visual acceptance is required before claiming comprehensive production UI certification.
- All durable domain and product release limitations in existing verification documents remain in force.
