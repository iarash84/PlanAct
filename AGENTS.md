# AGENTS.md — Personal Commitment Manager

This file is the repository-level execution contract for human developers and AI coding agents.
It defines **how PlanAct must be implemented**, while `docs/product/PRD.md` defines **what product behavior must exist and why**.
Read both files before changing product behavior. Read `docs/DESIGN_SYSTEM.md` before meaningful presentation or design-system work. If implementation guidance and product behavior appear to disagree, follow the source-of-truth hierarchy in Section 19 and do not silently invent a compromise.

## 1. Product mission

The product answers three questions reliably:

1. What was supposed to happen?
2. What actually happened?
3. What needs attention now?

The core lifecycle is:

`Plan → Schedule → Remind → Action → Actual → Reconcile → Done`

The product is **not** primarily a calendar, to-do list, reminder app, expense tracker, or accounting package. Those are views/subsystems around the commitment lifecycle.

## 2. Non-negotiable product principles

- **Local-first / offline core.** Core use cases must work without internet, backend, cloud account, or cloud AI.
- **Privacy by design.** Personal and financial data stays on-device by default.
- **Automation first, AI later.** Prefer deterministic rules, parsers, heuristics, and local algorithms before ML/AI.
- **Human in the loop.** Suggestions may be automated; important historical, financial, matching, and entitlement changes require explicit user confirmation unless the rule is deterministic and previously approved.
- **Simple UI, rich domain.** Absorb complexity in domain rules instead of exposing long forms and settings.
- **History is a feature.** Reschedule, cancellation, correction, matching, entitlement use, and financial corrections must not silently destroy history.
- **Deterministic core.** Time, status, balance, entitlement, and reconciliation calculations must be explainable and testable.
- **No silent mutation.** Do not silently change dates, amounts, matches, balances, or consumed sessions.
- **User-controlled backup.** Offline-first must not mean data-loss-prone.
- **Persian-first experience.** The primary product language is Persian; user-facing labels, actions, statuses, errors, empty states, accessibility text, and onboarding copy must be Persian unless a documented exception exists.
- **RTL by default.** The application UI must use right-to-left layout semantics correctly. Do not achieve RTL by manually reversing lists or hard-coding directional padding/icons; use Flutter directionality and start/end-aware layout APIs.
- **Jalali calendar for users.** User-facing dates, date pickers, calendar views, recurrence editing, and date-related summaries must use the Persian (Jalali) calendar and Persian locale conventions. Domain persistence must retain unambiguous, testable date/time semantics and must not conflate display-calendar conversion with stored instants or local dates.
- **Locale-aware formatting.** Persian digits, weekday/month names, number formatting, and pluralization must be handled through locale-aware presentation code, not scattered string replacements.

## 3. Current implementation baseline

- Client: **Flutter**.
- Local database: **SQLite via Drift**.
- Core domain must not depend on Flutter widgets, Drift tables, platform notification APIs, SMS APIs, or file-system APIs.
- Repository interfaces live in domain/application-facing code; persistence implementations live in data/infrastructure code.
- Notifications, backup/restore, SMS/import, secure storage, and future AI are adapters behind interfaces.
- State-management library is intentionally not fixed here. Reuse the existing project choice. If none exists, do not introduce one before the UI milestone without an ADR.

## 4. Preferred repository structure

For a new repository, use feature-first organization with explicit layers. If an established repository already has a coherent structure, preserve it instead of refactoring for aesthetics.

```text
lib/
  core/
    errors/
    ids/
    time/
    money/
    database/
    logging/
  features/
    commitments/
      domain/
      application/
      data/
      presentation/
    scheduling/
    sessions/
    reminders/
    today/
    calendar/
    actuals/
    finance/
    reconciliation/
    inbox/
    automation/
  app/

test/
  unit/
  repository/
  scenario/
  integration/
  fixtures/

docs/
prompts/
```

Do not create generic `utils/`, `helpers/`, or `services/` dumping grounds. Put behavior next to the domain it belongs to.

## 5. Dependency direction

Allowed direction:

`presentation → application → domain`

`data/infrastructure → domain/application contracts`

Domain code must not import UI, persistence, or platform packages.

A UI event must call an application/domain command or use case. **UI code must never directly mutate database tables.**

## 6. Domain model invariants

### 6.1 Commitment hierarchy

```text
Commitment
  └─ CommitmentCycle
       ├─ ScheduleDefinition
       ├─ SessionPolicy / EntitlementPlan (optional)
       ├─ Occurrence*
       │    ├─ ReminderInstance*
       │    └─ Actual / Evidence*
       └─ ReminderRule*
```

- `Commitment` is the stable concept, e.g. “music class”.
- `CommitmentCycle` is a registration/term/package/active period. Buying a new package creates a new cycle; do not rewrite the old one.
- `Occurrence` is one scheduled instance.
- `Actual/Evidence` records what happened.

### 6.2 Status separation

Commitment lifecycle is separate from occurrence status.

Typical commitment states:

`Active | Paused | Archived`

Typical occurrence states:

`Scheduled | Due | Completed | Skipped | Cancelled | Rescheduled | Overdue`

Completed/cancelled/skipped occurrences are historical records. Do not hard-delete them in routine operations.

### 6.3 Schedule is not entitlement

This is a core invariant:

- **Schedule** answers: “When should a session happen?”
- **Entitlement** answers: “How many sessions/units does the user still have a right to consume?”

Teacher cancellation, allowed absence, no-show, makeup session, holiday, pause/freeze, and term extension must be modeled through policy + ledger + occurrence history, not UI special cases.

### 6.4 Entitlement is ledger-based

Remaining sessions/units are derived from an entitlement ledger.

Allowed entry concepts include:

`Grant | Consume | Restore | Adjustment | Expire | Refund`

Never maintain a second independent mutable “remaining sessions” counter as a source of truth. A cached value is allowed only if it is rebuildable and verified against the ledger.

### 6.5 Financial balance is ledger-based

Financial accounts include bank accounts, cash wallets, digital wallets, and potentially credit accounts later.

- Store money as integer minor units, never floating-point.
- Account balance must be rebuildable from account entries.
- A transfer between the user’s own accounts is **not** income and **not** expense.
- A correction/reversal must leave an audit trail; do not erase history.
- Accounts with history should be archived, not hard-deleted.

## 7. Scheduling rules

Supported schedule modes must be able to represent at least:

- One-off.
- Open-ended recurring.
- Fixed date-range recurring.
- Fixed count.
- Manual package.
- Hybrid recurrence + entitlement.

Occurrence generation rules:

- Generate future occurrences in a bounded horizon; do not materialize infinite series.
- Generation must be idempotent.
- Past or manually edited occurrences must not be regenerated.
- Recurrence edits must not rewrite completed history.
- Use schedule versioning for “this and following”.
- Editing a series must support at least: `only this occurrence`, `this and following`, and `entire active cycle` when safe.

Time semantics must distinguish:

- Floating local wall-clock time (e.g. class every Saturday at 18:00).
- Fixed instant (e.g. a globally fixed webinar/flight time).
- All-day local date (e.g. insurance renewal date).

Do not convert date-only values to midnight UTC as a storage shortcut.

Month-end, leap-year, DST, timezone changes, holidays, pauses, conflicts, and schedule changes are explicit edge cases, not afterthoughts.

## 8. Session-policy rules

The domain must support configurable policies including:

- Provider cancellation consumes or does not consume entitlement.
- User cancellation notice threshold.
- Late cancellation consumption.
- No-show consumption.
- Free absence quota.
- Holiday/facility closure consumption.
- Whether a makeup occurrence is required.
- Auto-extension until units are consumed.
- Maximum extension date when contractually limited.
- Partial unit consumption as a future-compatible concept.

Required reference scenarios:

- Fixed-term language class.
- Four-session music package where teacher cancellation does not burn a session and may extend actual end date.
- Ten-session swimming package with two allowed absences and later sessions appended to the end.
- Freeze/pause period.
- Makeup session cancelled again.

`plannedEndDate` and `actualEndDate` are separate concepts.

## 9. Reminder rules

- `ReminderRule` defines the relative/absolute rule.
- `ReminderInstance` is the concrete scheduled notification.
- Rescheduling an occurrence must cancel/recompute future reminder instances.
- Cancelled/skipped/completed occurrences must not retain unnecessary active notifications.
- Snooze must not mutate the base rule.
- App restart/reboot must reconcile upcoming reminders.
- Platform notification IDs are not portable backup data; reminders are rebuilt after restore.
- Avoid orphan and duplicate notifications.

## 10. Actual, history, and reconciliation

Actual/Evidence may represent:

- Completion.
- Attendance.
- Outcome such as cancellation, missed/no-show, partial.
- Note.
- Local document/evidence reference later.
- Transaction link.

Planned-vs-actual logic belongs outside UI and must be testable.

Financial matching between transactions and occurrences is many-to-many to support partial payments, multiple payments, overpayment, and corrected matches.

## 11. Persistence and migration rules

- Use foreign keys, indexes, transactional writes, and explicit migrations from the beginning.
- Use stable IDs independent from local row auto-increment. UUIDv7 or ULID are acceptable implementation choices; record the final choice in an ADR.
- Every schema change requires a forward migration and tests using older-version fixtures.
- Destructive migrations require an explicit approved decision and safe backup path.
- Derived caches must be rebuildable.
- Historical financial records, resolved occurrences, entitlement ledger entries, and audit records are not routine hard-delete candidates.

## 12. Backup and restore rules

Backup is a release gate, not a future nice-to-have.

A backup package should carry at least:

- schema version,
- app version,
- creation timestamp,
- checksum,
- encryption metadata,
- attachment manifest if attachments exist.

Restore must:

1. validate in a temporary location,
2. verify checksum and schema compatibility,
3. preserve the current database if validation fails,
4. create a safety snapshot before replacement,
5. atomically replace the live state,
6. rebuild derived caches and scheduled reminders afterward.

## 13. Security and logging

- Never log raw SMS text, account identifiers, private notes, or sensitive financial values unless absolutely required for a controlled local debug build.
- Secrets/keys belong in secure platform storage.
- Sensitive exports require explicit user action and privacy warning.
- App lock/biometric protection is part of release hardening for sensitive data.
- App-lock protection must cover the root navigation stack, including modal and pushed routes, without discarding form state. Setting changes require fresh device authentication and successful persistence before changing the effective setting. Background transitions must invalidate in-flight authentication results; failures must not silently disable protection. Device-authenticator absence is not permission to introduce a recovery bypass. Native authentication/lifecycle and recents privacy require independent device evidence; Flutter tests alone do not prove these release gates.
- Do not add telemetry or crash reporting that uploads personal data without a deliberate privacy review.

## 14. Coding conventions for vibe coding

These conventions operationalize the roadmap and exist to keep AI-generated changes reviewable:

- Prefer small, single-purpose classes/functions.
- Use explicit domain types/value objects for IDs, money, dates/time semantics, statuses, and policy concepts where ambiguity would create bugs.
- Prefer pure functions for calculation-heavy logic: recurrence, status derivation, entitlement folding, money math, reconciliation.
- Avoid “god services”. Split commands/use cases by behavior.
- No magic status strings in business logic.
- Do not duplicate domain rules in UI.
- Do not add a package/dependency just to save a few lines. If a new dependency is materially useful, explain why and record it in the task report/ADR.
- Do not reformat unrelated files during a focused task.
- Do not perform opportunistic large refactors unless the current task requires them.
- Public APIs and persisted schemas require more caution than private implementation details.

## 15. Required test strategy

At minimum, each completed feature must include relevant tests at the lowest effective layer.

- Domain unit tests: state machines, recurrence, session policy, entitlement folding, money math, reconciliation.
- Repository/database tests: constraints, transactions, migrations, indexes where meaningful.
- Scenario tests: language/music/swimming classes, monthly bill, bank↔wallet transfer, partial payment, restore.
- Platform integration: notifications, backup file operations, secure storage.
- UI flow tests only where they protect a critical user journey.

Important invariants to continuously test:

- Rebuilt account balance == cached balance, if a cache exists.
- Rebuilt remaining entitlement == cached remaining entitlement, if a cache exists.
- Match allocation never exceeds allowed transaction allocation unless an explicit policy allows it.
- No active reminder points to a completed/cancelled occurrence.
- Future occurrences do not use an expired schedule version after its effective boundary.
- Restore produces the same logical state even when platform-specific notification IDs differ.

## 16. Definition of Done for every task

A task is not done merely because the UI works.

Before marking a task complete, verify:

- Scope in the task prompt is fully implemented.
- No out-of-scope feature was added.
- Domain invariants are preserved.
- Relevant tests are added and passing.
- Database changes include migration/tests.
- Historical behavior is preserved.
- Backup/restore impact has been considered for persisted changes.
- Errors and empty states are handled where relevant.
- No sensitive data is newly logged.
- Code is formatted/analyzed according to repository tooling.
- Documentation/ADR is updated if a durable architecture decision was made.

## 17. How an AI coding agent must work

For every prompt:

1. Read this file and the task-specific prompt; also read `docs/product/PRD.md` for product behavior changes and `docs/DESIGN_SYSTEM.md` before meaningful UI/design-system work.
2. Inspect the existing repository before proposing structure.
3. State the minimum implementation plan internally and keep the code change focused.
4. Reuse existing conventions and dependencies.
5. Implement only the current task and prerequisites explicitly allowed by the prompt.
6. Add tests before or alongside business logic.
7. Run the relevant test/analyzer commands available in the repository.
8. Do not “fix” unrelated code.
9. If a required architectural decision is missing, create a small ADR or clearly stop at an interface/seam rather than inventing a hidden irreversible choice.
10. End with a concise report containing:
   - files changed,
   - domain decisions made,
   - migrations/dependencies added,
   - tests run and result,
   - known limitations / next task.

## 18. Explicitly prohibited shortcuts

Do not:

- make cloud connectivity required for core flows,
- call cloud LLM APIs from core features,
- put persistence logic directly in widgets,
- directly edit cached balance/remaining-session values as source of truth,
- use `double`/`float` for money,
- treat internal transfers as expense/income,
- hard-delete historical records to simplify code,
- regenerate history after recurrence changes,
- silently consume a session on provider cancellation,
- silently modify financial matches or historical outcomes,
- skip migration tests for persisted schema changes,
- store date-only values as midnight UTC and assume equivalence,
- merge multiple milestones into one giant AI-generated change unless explicitly requested.

## 19. Source-of-truth hierarchy

When instructions conflict, use this order:

1. Explicit approved ADR / latest approved product decision.
2. `docs/product/PRD.md` for product scope, user-visible behavior, acceptance criteria, release priorities, and non-goals.
3. `AGENTS.md` for implementation constraints, architecture rules, data-integrity rules, testing expectations, and agent workflow.
4. `docs/ARCHITECTURE_AND_DOMAIN_RULES.md` for deeper architecture/domain detail that does not contradict items above.
5. Current milestone/task prompt, provided it stays within approved product scope and architecture.
6. Existing implementation conventions.

Interpretation rules:

- `docs/product/PRD.md` owns **what/why**; `AGENTS.md` owns **how/safeguards**.
- A task prompt may narrow scope but must not silently weaken a PRD acceptance criterion or an AGENTS data-integrity rule.
- When `docs/product/PRD.md` changes product behavior, update `AGENTS.md` in the same change if implementation rules are affected.
- When `AGENTS.md` introduces a durable product-visible constraint, verify whether `PRD.md` also needs an update.
- If there is still a conflict, preserve user data/history, prefer the least irreversible option, and require an explicit ADR/product decision before shipping behavior that changes semantics.

For presentation and visual-design decisions, use this additional order, subject to the product and engineering hierarchy above:

1. Product/domain requirements and established product behavior in `docs/product/PRD.md`.
2. Design governance in `AGENTS.md`.
3. The visual specification in `docs/DESIGN_SYSTEM.md`.
4. Shared PlanAct `ThemeData`, `ColorScheme`, `ThemeExtension`s or equivalent tokens.
5. Shared PlanAct components.
6. Feature-local composition.
7. One-off local styling, only when genuinely unavoidable and documented.

Feature widgets must not silently override a shared visual rule. If current implementation and the visual specification disagree, determine whether the implementation predates the current shared contract; follow the shared contract unless that would break product behavior, and record an intentional exception. Do not treat a current implementation detail as approval to create further visual variants.

## 20. PRD ↔ AGENTS consistency contract

`docs/product/PRD.md` and `AGENTS.md` are complementary and must evolve together.

Before completing a feature that changes product behavior, verify all of the following:

- Every applicable PRD acceptance criterion has an implementation path.
- No implementation rule contradicts the PRD's product semantics.
- A database/schema change has persistence, migration, restart, backup/restore, and test implications reviewed.
- A new user-visible default is documented in the PRD and represented explicitly in the domain model.
- A new archive/delete/status semantic is consistent across PRD, domain rules, UI language, and history behavior.
- A new recurrence or scheduling behavior specifies both recurrence frequency/pattern and termination/versioning semantics.
- A feature is not marked implemented merely because schema or UI exists; the complete product path must be wired.

If a PRD requirement is intentionally deferred, the implementation/report must label it as partial rather than implemented.


## Production State and Persistence

Production behavior must never depend on transient in-memory state when that state is expected to survive application restart.

Any domain information that affects future user-visible behavior must have a durable source of truth.

Examples include, where applicable:

* commitment scheduling
* recurrence configuration
* user-modified occurrence state
* financial records
* archive state
* automation configuration
* other user-created durable data

In-memory repositories are acceptable only for:

* tests
* fixtures
* isolated previews
* explicitly temporary state

Presentation-layer caches, maps, providers, controllers, or widget state must never become the authoritative source of durable domain information.

After a cold restart, the application must be able to reconstruct the same user-visible state from persistent domain data.

---

## No Hidden Semantic Defaults

Never silently invent meaningful user data.

Do not automatically assign important values such as:

* time
* date
* amount
* recurrence
* status
* category
* reminder
* destructive behavior

unless the product explicitly defines that value as a visible and documented default.

If the user has not selected a time, do not silently convert that absence into an arbitrary time such as `09:00`.

Defaults that affect behavior must be:

* explicitly defined
* consistent
* visible or understandable to the user
* represented correctly in the domain model

Absence of a value and a default value are not interchangeable unless the domain explicitly defines them as equivalent.

---

## Semantic UI Correctness

Visual language must always match the actual domain action.

Icons, labels, colors, animations, confirmations, and feedback must communicate the same semantic operation.

Examples:

* Archive must use archive semantics, not delete semantics.
* Delete styling must only represent actual deletion.
* A reversible action should offer Undo where appropriate.
* Irreversible actions require stronger confirmation.
* Navigation arrows and directional controls must follow the same RTL convention across the application.

Do not use a destructive visual style for a non-destructive action.

Callback, method, and component names should also reflect the real semantic action.

Prefer `onArchive` over `onDelete` when the operation archives an item.

---

## Archived and Historical Data

Archived domain objects must have explicitly defined behavior.

For every feature involving archival, verify:

* whether archived objects appear in Today
* whether they appear in Calendar
* whether they contribute to Attention
* whether they appear in search/history
* whether they can be restored
* whether their historical occurrences remain visible

Do not allow each screen to independently invent archive behavior.

Archive semantics belong in the domain/application layer.

---

## User Action Feedback

Every meaningful user action must produce appropriate feedback.

For each action, consider applicable states:

* idle
* pressed
* loading
* success
* failure
* disabled
* undo/recovery

Async actions must not fail silently.

Errors must be:

* visible
* understandable
* actionable where possible
* written in natural Persian for user-facing UI

Do not swallow exceptions simply to keep the UI responsive.

Technical error details may be logged, but user-facing feedback must remain human-readable.

---

## Core Journey Quality

Critical product journeys must be treated as complete flows rather than independent screens.

For PlanAct, interactions such as:

Create
→ schedule
→ display
→ change status
→ undo
→ archive
→ undo

must remain semantically and visually coherent from beginning to end.

When modifying any step in a critical journey, check the effects on all downstream screens and states.

Do not optimize a single screen at the expense of flow consistency.

---

## Today Screen Semantics

The Today screen is a primary decision surface, not merely a list of today's records.

Its sections must be derived from real application/domain state.

Sections such as:

* Today
* Attention
* Next

must not remain placeholder UI once corresponding domain information exists.

The classification of an item into Today, Attention, Next, archived, completed, overdue, or other states must be centralized and testable.

Avoid duplicating classification rules inside widgets.

---

## Brand Identity

PlanAct must remain recognizably PlanAct rather than looking like an unbranded Flutter/Material sample. Derive its visual personality from the actual brand assets and the product's calm, trustworthy, organized, focused, modern, approachable, financially credible, action-oriented, low-noise, Persian-first character. The identity should be expressed consistently through color families, surface hierarchy, selected and interaction states, Persian typography, shape, icon treatment, motion, and visual hierarchy—not by repeatedly placing the logo on screens.

Use the logo primarily in appropriate brand moments such as the launcher, startup/splash, About, and deliberately chosen root-branding moments. Do not add it to every AppBar or use decorative logo repetition as a substitute for a coherent visual system. Material 3 remains the interaction and component foundation; it is not PlanAct's brand identity.

Before proposing a foundational palette or identity change, inspect the actual app icon/launcher assets and current theme implementation; do not infer palette values from this guidance alone.

## Design System First

`docs/DESIGN_SYSTEM.md` is the authoritative concrete visual specification; `AGENTS.md` governs how that specification is maintained. Before adding or changing a recurring color, text style, radius, spacing, shadow/elevation, animation timing, or component pattern, inspect the specification, current theme/tokens, and shared components.

Repeated visual decisions MUST be centralized in the existing `ThemeData`, `ColorScheme`, `TextTheme`, component themes, PlanAct tokens (including a `ThemeExtension` or equivalent where semantic roles require it), or shared components. Reuse a fitting semantic role. If multiple surfaces need a missing role, extend the shared system rather than creating feature-local alternatives. Feature presentation code must not become a second design system, and local styles must not silently override shared rules.

Centralize design decisions, not every geometry literal. Component-specific geometry may remain local when it is genuinely unique; recurring visual values and patterns may not. A one-off style is acceptable only when it is necessary for a specific surface, does not conflict with shared semantics, and its reason and scope are documented. Avoid both copy-pasted local UI and universal widgets with sprawling APIs.

App-wide visual consistency is required; app-wide architectural rewriting is not. Apply changes proportionally: a small isolated behavior or UI adjustment does not require redesigning the app, while a shared design-system change or broad visual refactor requires reviewing all affected surfaces and updating any equivalent surfaces that would otherwise be left in a knowingly incompatible visual language.

## Brand Colors and Semantic Colors

Keep brand hierarchy and business/status meaning distinct. Material brand roles such as primary, secondary, tertiary, their containers, surfaces, and outlines establish product hierarchy. Success, warning, danger/error, information, attention, overdue, paused, archived, and disabled are semantic roles. Do not map a Material brand role to a business state merely because its color looks convenient (for example, `tertiary == success` or `error == overdue`); a role may serve both purposes only when the meaning is deliberately defined, semantically correct, and documented.

Use `ColorScheme` for Material brand and surface roles and the existing PlanAct semantic-color mechanism (currently `PlanActColors`, or an architecture-aligned `ThemeExtension` if needed) for non-Material statuses. Semantic foreground/container pairings and contrast must be defined for each brightness; do not assume a Light value is valid in Dark. Never communicate a status by color alone. Official external brand colors are limited exceptions for representing that external entity, not substitutes for PlanAct brand or status colors.

## Material 3 and Theme Parity

Use Material 3 components and interaction conventions. When a shared PlanAct theme role or component treatment exists, do not leave recurring components at framework defaults or compensate with extensive screen-local styling. Prefer theme-level configuration for recurring Material components.

Light and Dark are both intentional designs. A design-system change is incomplete until both have been reviewed; Dark must not be produced by mechanically inverting Light. Check text and icon contrast, surface levels, outlines, selected and disabled states, semantic colors, chips/badges, navigation, dialogs, and sheets. PlanAct's identity and status meanings must remain recognizable in both themes.

## App-Wide Visual Coverage

For a broad visual redesign or shared design-system change, create or update a concise coverage inventory of applicable user-visible surfaces. Depending on what exists or is affected, include the root shell/navigation, Today, Calendar, Quick Add, Quick Capture, Commitment Details, Finance, Inbox, More, Settings, About, App Lock, startup/splash, dialogs, bottom sheets, forms, date pickers, and loading/empty/error/other state views. Mark each applicable surface as **Compliant**, **Migrated**, or **Intentionally Unchanged**, with a short reason for the latter. No applicable surface may remain **Not Reviewed** for work claiming app-wide visual consistency.

The inventory is proportional to scope: a tiny isolated change does not require a full-app audit. A shared component change must include its known consumers; a broad refactor must consider the full applicable inventory. Do not knowingly leave equivalent screens visually stale after changing their shared pattern.

---

## Typography

PlanAct is Persian-first.

Typography must therefore be intentionally designed for Persian readability.

Text hierarchy must be semantic and reusable.

Before meaningful UI work, follow the font strategy and semantic roles in `docs/DESIGN_SYSTEM.md`; prioritize Persian readability and line height, correct shaping, mixed Persian/Latin content, Persian digits where appropriate, and legible numeric/money content. Reuse semantic theme typography and locale-aware formatters; do not invent feature-local font families, arbitrary font sizes/weights, or scattered digit replacements.

Typography should distinguish roles such as:

* screen title
* section title
* primary content
* secondary content
* metadata
* label
* action
* amount/status where applicable

RTL, text scaling, and mixed Persian/Latin content must remain usable.

---

## Semantic Colors

Use the brand/status separation in **Brand Colors and Semantic Colors** and the role definitions in `docs/DESIGN_SYSTEM.md`. Keep meaning consistent across surfaces and define appropriate Light and Dark values. Do not introduce arbitrary feature-local colors or communicate status by color alone.

---

## Motion System

Motion is part of the interaction system.

Animation must communicate:

* state change
* continuity
* hierarchy
* insertion/removal
* expansion/collapse
* success/failure
* navigation context

Do not add animation purely for decoration.

Animation durations and curves must come from centralized PlanAct motion tokens.

Prefer lightweight implicit Flutter animations for simple transitions, including where appropriate:

* `AnimatedSize`
* `AnimatedSwitcher`
* `AnimatedContainer`
* `AnimatedOpacity`

Use explicit animation controllers only when the interaction requires them.

Avoid independently invented animation durations inside feature widgets.

---

## Progressive Disclosure

Complex forms should reveal optional complexity progressively.

Do not overwhelm users with all configuration fields at once when they are not required.

Expanded and collapsed states should maintain:

* visual continuity
* keyboard behavior
* focus
* scroll position where practical

Related controls should be visually and semantically grouped.

For example, recurrence configuration should behave as one coherent section rather than unrelated fields scattered through the form.

---

## UI State Completeness

A screen or component is not complete when only the happy path works.

Consider all applicable states:

* initial
* content
* empty
* partial
* loading
* refreshing
* saving
* success
* error
* disabled
* archived

Do not introduce placeholder sections when real domain data is already available.

Do not leave async operations without a defined loading and failure experience.

---

## Accessibility

Visual polish must not reduce usability.

Always verify:

* adequate touch targets
* readable contrast
* text scaling
* RTL behavior
* semantic labels
* icon-only button descriptions
* keyboard/focus behavior where applicable
* status communication beyond color

Do not make interactive elements artificially small for visual compactness.

For visual and interaction expectations, use the measurable requirements in `docs/DESIGN_SYSTEM.md`, including its minimum touch target and contrast guidance. Do not fix overflow by shrinking text or disabling text scaling. The explicitly requested Calendar-page fit-to-screen grid is a narrow exception to minimum target width when seven 48dp columns cannot fit: keep all seven RTL columns visible, at least 48dp target height, non-overlapping hit regions, full Persian semantics and text-scale-aware height. Other controls and the modal date picker retain the standard target requirement.

---

## RTL Consistency

RTL behavior must be intentional and consistent across the entire application.

Use directional Flutter APIs where appropriate.

Do not manually reverse layouts as a substitute for correct RTL support.

Directional icons, including:

* previous/next
* forward/back
* expand/collapse
* navigation

must use a single consistent semantic convention throughout PlanAct.

When introducing a new directional interaction, compare it with existing PlanAct conventions before implementation.

---

## Changes to Shared UI

Before creating a new visual component:

1. Search existing shared components, themes, and tokens for an equivalent pattern.
2. Reuse it if suitable.
3. Improve the shared implementation when that is the appropriate way to preserve consistency.
4. Create a new abstraction only when it represents a recurring product pattern not served by existing components.

Keep shared component APIs small and semantic; avoid near-duplicates in feature folders and avoid giant universal widgets with many unrelated options. If changing a shared component affects other presentation surfaces, inspect and update those consumers as required by the app-wide coverage rule. Do not perform an unrelated architecture rewrite as a visual-consistency exercise.

---

## Required Validation for Feature Changes

For any meaningful feature or UI change, check:

1. Does the state survive restart if it should?
2. Is the domain still the source of truth?
3. Are there hidden semantic defaults?
4. Does the visual language match the actual action?
5. Are RTL semantics correct?
6. Are loading/error/empty states handled?
7. Is Undo or confirmation required?
8. Does the implementation reuse the design system?
9. Are new arbitrary design values being introduced?
10. Does the change affect another part of the core user journey?
11. Are relevant tests present?
12. Does the change follow `docs/DESIGN_SYSTEM.md` and reuse the current PlanAct design system?
13. Is it visually aligned with related surfaces, including affected shared-component consumers?
14. Did it introduce recurring raw visual values or near-duplicate patterns that belong in shared tokens/components?
15. Does it work intentionally in both Light and Dark?
16. Are RTL semantics, Persian typography, text scaling, touch targets, contrast, and color-independent status cues usable?
17. Are applicable loading, error, empty, saving, and disabled states coherent?
18. Is any visual exception genuinely necessary, scoped, and documented?

A change should not be considered complete until applicable items are addressed.

For broad visual/design-system tasks, also complete the app-wide visual coverage inventory above; no applicable surface may remain unreviewed. Do not claim app-wide consistency based only on the edited screen.

---

## Testing Expectations

Changes affecting persistence must include restart/reinitialization tests where practical.

Changes affecting domain classification must include unit tests.

Changes affecting critical UI interactions should include widget tests where practical.

Tests must validate behavior, not merely implementation details.

In-memory tests are not sufficient proof of persistence behavior.

After meaningful changes run:

* `dart format`
* `flutter analyze`
* relevant unit tests
* relevant widget/integration tests

Do not report a task as complete when analysis or relevant tests fail.


## Offline Iranian holiday safeguards

Holiday lookup must use versioned, traceable offline data and explicitly distinguish weekly weekends, official fixed/variable holidays, and scoped special closures. Preserve overlapping reasons. Published Iranian lunar dates must not be replaced by an approximate Islamic conversion. Incomplete annual coverage must be visible; missing markers are not evidence of a working day. Special closure inputs require a durable versioned source, not authoritative transient widget state. Holiday refreshes must not silently mutate occurrences, reminders, entitlement or financial history. Current-year 1405 coverage is checked against all twelve time.ir published months; do not describe that secondary source as independent verification of the official PDF. Future-year coverage and actual special closure datasets still require explicit source review, as recorded in docs/IRANIAN_HOLIDAYS_VERIFICATION.md.

## Schedule/actual checkpoint safeguards

Priorities 6 and 7 are partial as recorded in docs/SCHEDULE_ACTUAL_VERIFICATION.md. Explicit reopening appends a result, preserves earlier history, and restores an actionable scheduled/rescheduled occurrence; it must not be described as an exact prior-status, financial, or entitlement reversal. Persisted outcome enum indices must remain stable. Date/time editing must reject unsupported recurrence/termination semantics rather than silently changing session counts or recurrence phase. Full intermediate schedule audit, version-safe generation, durable concurrency revisions, and interrupted reminder reopening remain required gates, not waived requirements.

## Transactional/platform consistency

Domain commits and external platform delivery are separate outcomes. Do not report a committed creation or occurrence mutation as wholly failed because subsequent reminder synchronization failed. Persist replacement reminder intent transactionally before platform cancellation/scheduling; reconcile from durable rules and occurrences without destroying delivery, snooze or cancellation history. CommandGate admission is not general command serialization. The Priority 5 checkpoint and unresolved same-time restore/concurrency/native gates are recorded in docs/TRANSACTIONAL_PLATFORM_VERIFICATION.md.

## Production backup verification status

The production adapter decisions and unresolved release gates are recorded in docs/adr/0013-production-backup-restore.md and the PRD implementation-status note. Do not describe installation-bound encrypted exports as portable device-loss recovery. Do not weaken isolated schema validation to bypass migrated-schema incompatibility without tested compatibility rules. Backup integration must prove in-flight command exclusion, repository/listener rebind, full logical-state preservation, and isolated native platform behavior before release.

## Independent holiday package safeguards

Annual packages use explicit first-publisher fingerprint approval and pinned Ed25519 signer continuity; a valid signature is not evidence of official source accuracy or factual completeness. Keep source review separate from structural coverage validation. Preserve old data on rejection or transactional failure, never reset trust silently, and never mutate personal history on reference-data imports. Public package storage is outside personal backup/restore; retain original packages. See docs/adr/0014-independent-holiday-packages.md.
