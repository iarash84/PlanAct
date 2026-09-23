# AGENTS.md — Personal Commitment Manager

This file is the repository-level contract for human developers and AI coding agents.
Read it before changing code. If a task-specific prompt conflicts with this file, this file wins unless the prompt explicitly records an approved architecture decision.

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
4. preferably create a safety snapshot before replacement,
5. atomically replace the live state,
6. rebuild derived caches and scheduled reminders afterward.

## 13. Security and logging

- Never log raw SMS text, account identifiers, private notes, or sensitive financial values unless absolutely required for a controlled local debug build.
- Secrets/keys belong in secure platform storage.
- Sensitive exports require explicit user action and privacy warning.
- App lock/biometric protection is part of release hardening for sensitive data.
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

1. Read this file and the task-specific prompt.
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

1. Explicit approved ADR / latest product decision.
2. `AGENTS.md`.
3. `docs/ARCHITECTURE_AND_DOMAIN_RULES.md`.
4. Current milestone/task prompt.
5. Existing implementation conventions.

If there is still a conflict, preserve data/history and choose the least irreversible option.
