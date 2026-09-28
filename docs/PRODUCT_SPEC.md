# PlanAct Product Specification

**Status:** Product/domain contract for future implementation  
**Scope:** Current repository audit and target product definition  
**Last reviewed:** 2026-09-26  
**Normative language:** “Must” is a product invariant. “Should” is a target behavior. “Future” is intentionally out of the current implementation contract.

## 1. Product definition

PlanAct is a local-first personal commitment and reconciliation manager. It connects:

1. what the user planned or committed to do;
2. what actually happened;
3. evidence of what happened;
4. financial transactions when applicable; and
5. what currently requires attention.

PlanAct is not primarily a task list, calendar, reminder app, expense tracker, or accounting package. Those are projections and supporting subsystems around the commitment lifecycle:

```text
Plan → Schedule → Remind → Action → Actual → Reconcile → Completion / Resolution
```

The product must answer, with separate and explainable data:

- What was supposed to happen?
- What actually happened?
- What needs attention now?

The product supports both non-financial commitments and financial commitments. A commitment may be resolved by an activity, by a financial settlement, by both, or by an explicit user decision depending on its policy.

## 2. Scope vocabulary

### Current state

What the repository currently persists, exposes through domain/application code, or presents in the running UI. A domain model, test, or database table is not treated as a complete product feature unless a usable persisted flow exists.

### Target state

The product contract that subsequent implementation phases should satisfy. Target behavior is not claimed to exist today.

### Future ideas

Valuable extensions deliberately outside the target baseline, such as optional on-device AI, multi-currency reporting, advanced forecasting, and additional import adapters.

## 3. Product principles

- **Local-first:** core use cases work without internet, a cloud account, a backend, or cloud AI.
- **Persian-first:** user-facing labels, errors, statuses, empty states, accessibility text, onboarding, dates, numbers, and financial explanations are Persian by default.
- **RTL-first:** use Flutter directionality and start/end-aware layout semantics; do not reverse data or layouts manually.
- **Jalali-first presentation:** user-facing dates use the Persian/Jalali calendar and Persian locale conventions. Stored values retain unambiguous domain semantics.
- **Privacy-sensitive:** personal and financial data remains on-device by default; raw SMS, private notes, account identifiers, and sensitive amounts are not logged routinely.
- **No hidden mutation:** no silent date, amount, status, match, balance, entitlement, or historical change.
- **Plan and actual remain distinct:** a plan is an intention/expectation; an actual is an observation or recorded outcome. Neither overwrites the other.
- **Financial expectations remain distinct from transactions:** an expected payment is not money movement; a transaction is observed account movement.
- **Integer money:** financial amounts use integer minor units and an explicit currency; floating-point representations are prohibited.
- **Explainable matching:** the user can understand why two records were suggested as a match, including amount, date, direction, merchant/reference, and any uncertainty.
- **Reversible automation:** automation proposes or stages changes before confirmation; rejection, correction, rollback, or reversal preserve history.
- **Auditability:** critical financial actions, imports, corrections, matching, and settlement decisions retain an explainable history.
- **Human in the loop:** important historical, financial, entitlement, and matching decisions require explicit confirmation unless a previously approved deterministic rule applies.
- **Deterministic core:** recurrence, status, money, balance, entitlement, and reconciliation calculations are pure, testable, and rebuildable.

## 4. Capability matrix

| Capability | Current classification | Evidence / current boundary | Target contract |
|---|---|---|---|
| Commitments | **Partially implemented** | `Commitment` lifecycle, metadata, Drift persistence, create/edit/status UI exist. | Stable commitment with cycles, history, policy, and durable commands. |
| Scheduling | **Partially implemented** | Schedule definitions, time semantics, generation, and plan persistence exist; basic capture creates a plan. | Durable versioned schedules, bounded generation, explicit edits, conflict/pause policies. |
| Recurrence | **Partially implemented** | Daily/weekly/monthly/yearly rule model and tests exist. | User-visible recurrence editing with history preservation and edge-case policies. |
| Occurrences | **Partially implemented** | Domain model, generation, persistence, and calendar projection exist. | First-class occurrence UI and status/actual/reconciliation workflow. |
| Reminders | **Partially implemented** | Rule/instance domain, repository, service, and integration tests exist. | Durable reminder lifecycle wired to all occurrence mutations and platform rebuild. |
| Actuals | **Partially implemented** | `Actual`, outcomes, repository, and tests exist. | User-facing actual recording linked to occurrence and history. |
| Evidence | **Domain/schema only** | Evidence domain and table exist; no complete attachment/evidence UI or storage flow. | Evidence linked to actuals with local references/documents and provenance. |
| Financial accounts | **Partially implemented** | Account domain, Drift table/repository, balance fold, and basic UI exist. Composition currently injects an in-memory finance repository. | Durable bank/cash/digital/credit accounts with archive and account history. |
| Account entries / transactions | **Partially implemented** | Entry domain, ledger table, income/expense/transfer primitives exist; UI records expenses only. | Durable auditable transaction ledger with corrections, refunds, reversals, and provenance. |
| Financial expectations | **Missing** | No explicit persisted/domain expectation model. | Expected amount, direction, due date/account, occurrence link, policy, and settlement state. |
| Transaction matching | **Partially implemented** | Match/allocation domain, repository, schema, and planned-vs-actual calculation exist. | Explainable suggestions, confirmation, correction/reversal, and user-facing history. |
| Allocations | **Partially implemented** | Many-to-many allocation model and amount guard exist. | Full/partial/multiple/overpayment/refund/correction allocation workflows. |
| Inbox | **Partially implemented** | Staged imports, drafts, suggestions, statuses, and repositories exist. No product navigation/review surface. | Review queue for all uncertain imported/suggested data with accept/edit/reject/rollback. |
| SMS ingestion | **Partially implemented** | Local parser and staging use case exist; parser supports a narrow message format. No device SMS adapter/UI. | Adapter → parser → staged import → review → confirmed transaction. |
| Today | **UI only / partially implemented** | Persian Today screen exists, but attention is a placeholder and future section is not domain-derived. | Centralized query for Today, Attention, and Next from actual persisted state. |
| Attention | **Placeholder** | UI label exists; it counts unresolved same-day commitments and displays placeholder text. | Explainable prioritized attention items: overdue, due, unmatched, failed reminder, anomaly, etc. |
| Next | **Placeholder** | UI section says future plans will appear but does not render them. | Upcoming projection from occurrences, expectations, and reminders. |
| Calendar | **Partially implemented** | Jalali calendar UI and schedule projection exist; edits and full occurrence semantics are incomplete. | Projection only; all edits route through domain commands and preserve history. |
| Accounting/reporting | **Missing** | No reporting/accounting projection beyond basic balance and planned-vs-actual domain calculation. | Lightweight personal financial dashboard, balances, cash flow, expectations, settlement, and variances. |
| Session/entitlement policies | **Domain/schema only to partially implemented** | Entitlement ledger, policies, replacements, repositories, and tests exist; not integrated into product navigation/flows. | Generic schedule/entitlement separation with explicit attendance, cancellation, makeup, freeze, and extension outcomes. |
| Backup/restore | **Partially implemented** | Backup metadata/validation service and tests exist; complete database package/atomic replacement flow is not evidenced in composition/UI. | User-controlled validated backup, safety snapshot, atomic restore, and rebuild hooks. |
| Automation/prediction | **Domain/schema only** | Local automation/predictive interfaces exist. | Deterministic suggestions first; optional local AI later, never required for core flows. |

## 5. Core domain model

The canonical relationship is:

```text
Commitment
  └─ CommitmentCycle
       ├─ CommitmentPlan / policy context
       ├─ Schedule (versioned definition)
       ├─ Occurrence*
       │    ├─ Reminder*
       │    ├─ Actual*
       │    │    └─ Evidence*
       │    └─ FinancialExpectation?*
       └─ EntitlementPlan / SessionPolicy? 

FinancialAccount
  └─ AccountEntry / Transaction*

Transaction ── Match ── Allocation ── Occurrence / FinancialExpectation

InboxItem / StagedImport ── Draft / Suggestion ── confirmed Transaction
```

### 5.1 Commitment

A stable human concept that persists across cycles, schedules, and occurrences. Examples include “language class”, “rent”, “insurance renewal”, or “loan repayment”. It owns identity and broad metadata, not a particular date or payment.

Commitment lifecycle and occurrence lifecycle are separate. Archiving a commitment must not delete historical cycles, occurrences, actuals, evidence, transactions, or matches.

### 5.2 CommitmentCycle

A bounded or logical period within a commitment: a term, subscription period, service package, loan phase, or active registration. A new purchase/term/package creates a new cycle rather than rewriting the prior cycle.

A cycle may have `plannedEndDate` and `actualEndDate`; they answer different questions. Completion rules may be date-based, unit-based, combined, or manual.

### 5.3 CommitmentPlan

The application-level aggregate used to create and retrieve the commitment’s operational plan. It groups the commitment, active cycle, schedule, generated occurrences, and reminder rules for a workflow. It is not a replacement for persisted domain entities and must not become a second source of truth.

### 5.4 Schedule

A versioned definition of when an occurrence should happen. It may be one-off, recurring, fixed-range, fixed-count, manual-package, or hybrid. It stores time semantics:

- floating local wall-clock time;
- fixed instant; or
- all-day local date.

Schedule generation is bounded and idempotent. Past, completed, cancelled, or manually overridden occurrences are not silently regenerated. “Only this” changes one occurrence; “this and following” creates a new effective schedule version; “entire active cycle” is allowed only when history remains intact.

### 5.5 Occurrence

One planned instance generated from a schedule. It records original and current scheduled values, status, schedule version, and manual override state. An occurrence is the principal bridge between plan, actual, reminders, expectations, and reconciliation.

An occurrence status such as completed, skipped, cancelled, rescheduled, due, or overdue describes the planned instance; it does not by itself prove what happened financially or physically.

### 5.6 Actual

A durable record of an observed outcome for an occurrence: completed, attended, cancelled, missed, no-show, partial, or another explicitly modeled outcome. Actuals may include notes and are append/history-oriented. Recording an actual must not rewrite the original schedule.

### 5.7 Evidence

A reference supporting an actual, such as a note, local document reference, receipt, or later attachment. Evidence is not the actual itself and is not required for every actual. Evidence must retain provenance and must not require cloud storage for the core flow.

### 5.8 Reminder

A `ReminderRule` expresses intent (relative to an occurrence or at an absolute time). A `ReminderInstance` is a concrete delivery schedule. Completion, cancellation, rescheduling, restart, and restore reconcile instances without mutating the underlying rule or leaving active orphan notifications.

### 5.9 FinancialAccount

A user-owned bank account, cash wallet, digital wallet, or later credit-style account. It provides identity, currency, type, and active/archived state. Accounts with history are archived, not deleted.

### 5.10 Transaction / AccountEntry

A transaction is observed or manually recorded financial movement. In the current implementation, `AccountEntry` is the ledger representation of income, expense, transfer, opening balance, adjustment, refund, or reversal. The product should use “transaction” for the user-facing observed event and retain account entries as the account-specific ledger postings.

A transfer creates paired entries linked by a transfer group; it is neither income nor expense. Balance is rebuilt by folding entries, not maintained as an independent authority.

### 5.11 FinancialExpectation

A planned financial obligation or receipt associated with an occurrence or commitment. It answers: “What amount, direction, account, and due date did we expect?” It is not a transaction and does not change an account balance.

An expectation may be outgoing (rent, loan installment, bill), incoming (salary, reimbursement, receivable), or informational. It may be one-off or recurring through occurrences. It supports planned-vs-actual variance and settlement state.

### 5.12 Match / Reconciliation

A match is an auditable relationship between an observed transaction and one or more planned financial expectations/occurrences. Reconciliation is the process of comparing plan and actual, proposing or confirming relationships, allocating amounts, explaining variance, and preserving corrections.

Matching must support full payment, partial payment, multiple payments, one payment covering multiple expectations, overpayment, refund, and correction/reversal. A suggestion is not a confirmed match.

### 5.13 Allocation

An allocation assigns a specific integer minor-unit amount from a transaction/match to a target occurrence or financial expectation. The sum of allocations cannot exceed the source transaction amount unless an explicit overpayment policy is introduced. Allocations are immutable history entries in the sense that corrections supersede them rather than silently editing the past.

### 5.14 InboxItem / StagedImport

A staged import is raw or normalized external input held outside the final ledger. It stores source, source key, fingerprint, adapter version, and status. An inbox suggestion contains a draft transaction or other proposed action.

The required flow is:

```text
Raw source → parse/normalize → staged import → review → confirm/edit/reject → final domain command
```

Raw source must never directly mutate the financial ledger.

## 6. Planned, actual, expectation, transaction, reconciliation, completion

| Question | Concept | Meaning |
|---|---|---|
| What was intended to happen? | Commitment / Schedule / Occurrence | User plan and its generated planned instances. |
| What money did we expect? | FinancialExpectation | Planned amount, direction, due date, account, and settlement policy. |
| What happened in real life? | Actual | Recorded outcome of an occurrence. |
| What supporting proof exists? | Evidence | Note/reference/document supporting an actual or imported event. |
| What money movement was observed? | Transaction / AccountEntry | Recorded bank, cash, wallet, or manually entered movement. |
| How do plan and money relate? | Match / Allocation | Confirmed, auditable relationship with amount and explanation. |
| What does completion mean? | Resolution policy | A domain decision derived from occurrence actual, financial settlement, entitlement, or explicit user confirmation. |

Financial settlement and task completion **can differ**. Examples:

- A bill may be paid but the service appointment is not completed.
- A class may be attended while payment remains outstanding.
- A transaction may cover several expectations but none of the underlying tasks is complete without an actual outcome.
- A refund may financially reverse settlement while the original occurrence remains historical and requires a separate resolution.

The UI must never infer completion solely from a transaction unless the commitment’s explicit policy permits that deterministic rule and makes the consequence visible.

## 7. Primary user journeys

### 7.1 Non-financial commitment

1. Create a commitment.
2. Create or select a cycle and schedule.
3. Generate bounded future occurrences.
4. Configure reminder rules and materialize reminder instances.
5. User acts.
6. User records actual outcome and optional evidence.
7. Occurrence resolves; commitment/cycle completion is evaluated by its explicit rule.
8. History remains queryable.

### 7.2 Financial outgoing commitment

1. Create commitment and cycle.
2. Define expected outgoing amount, account (if known), due date/occurrence, currency, and recurrence.
3. Remind the user before due date.
4. Detect or record actual bank/cash transaction.
5. Generate a matching suggestion using explainable signals.
6. User reviews and confirms, edits, or rejects.
7. Create match and allocations; compute remaining/variance.
8. Mark the expectation settled only when the settlement rule is met; retain the occurrence’s separate actual/task state.

### 7.3 Financial incoming commitment

1. Create an expected incoming payment with amount, expected date, payer/reference, account, and recurrence if applicable.
2. Wait without creating balance movement.
3. Detect or record deposit transaction.
4. Suggest a match with visible reasons.
5. User confirms or corrects.
6. Allocate and mark the expectation fulfilled when policy conditions are met.

### 7.4 SMS transaction flow

```text
Bank SMS → local parser → StagedImport → Inbox review → confirm/edit/reject → AccountEntry/Transaction → reconciliation suggestion
```

Parsing must preserve raw provenance, detect duplicates, avoid silent assumptions, and never directly write to the final ledger. Unsupported or ambiguous SMS remains staged for user review.

### 7.5 Recurring financial commitment

1. Define recurring plan and financial expectation policy.
2. Generate the next bounded occurrence and expectation.
3. Remind before due date.
4. Match actual transaction after it appears.
5. Reconcile variance and settle only that occurrence.
6. Keep the recurring plan active and generate the next occurrence without rewriting history.

## 8. User-facing surfaces

### Today

Today is the primary decision surface. It must derive three projections from domain/application queries:

- **Attention:** overdue, due, unresolved, failed, unmatched, anomalous, or otherwise actionable items;
- **Today:** planned occurrences and expectations for the local Jalali date;
- **Next:** upcoming occurrences, reminders, and financial expectations.

The classification and ordering rules must be centralized and testable, not implemented independently inside widgets.

### Calendar

Calendar is a Jalali projection of schedules and occurrences. It is not the source of truth. Editing from the calendar invokes the same domain commands as other surfaces and requires an explicit edit scope.

### Finance

Finance is a lightweight personal financial dashboard, not a full accounting package. It should show accounts, rebuildable balances, recent transactions, upcoming expectations, settlement/variance, and transfers without double-counting income or expense.

### Inbox

Inbox is the review queue for imported or uncertain data: SMS drafts, file imports, matching suggestions, and future automation suggestions. It must communicate source, confidence/reasons, affected records, and available confirm/edit/reject/rollback actions.

## 9. Current architecture and gaps

### Current architecture

- Flutter client with feature-first organization.
- Domain/application/data/presentation separation is present in most features.
- SQLite via Drift with schema version 10 and foreign-key activation.
- Stable UUIDv7-style identifiers and integer minor-unit money primitive exist.
- Commitment, scheduling, session, reminder, actual, finance, reconciliation, inbox, backup, automation, and prediction modules exist at differing maturity.

### Major gaps

1. Financial composition uses `InMemoryFinanceRepository` in the application shell; durable finance is not the production source of truth.
2. `FinancialExpectation` does not exist as a first-class concept, so planned financial obligations/receipts cannot be represented cleanly.
3. Transaction matching is modeled but not connected to a user-facing review/suggestion flow or expectation target.
4. Actuals and evidence are persisted/domain-modeled but not integrated into the main occurrence journey.
5. Inbox and SMS parsing are application/domain capabilities without a visible inbox or platform SMS adapter.
6. Today’s Attention and Next are placeholders rather than centralized domain projections.
7. Calendar is primarily a projection of commitment plan dates; editing and occurrence-level resolution are incomplete.
8. Finance UI is a narrow in-memory cash/expense demo with a hidden currency default and no account/entry persistence wiring.
9. Schema tables lack complete indexes and some relationships are represented by untyped text rather than explicit foreign keys; this requires future persistence hardening.
10. Full backup/restore packaging and atomic live-database replacement are not evidenced as an end-to-end user flow.
11. Audit history for financial corrections, matching, and user decisions is not yet a complete product surface.

## 10. Target invariants and acceptance gates

Future implementation must preserve these gates:

- Restart reconstructs the same durable user-visible domain state.
- No raw import writes directly to a final ledger.
- No occurrence history is regenerated or erased after schedule changes.
- No completed/cancelled occurrence retains an unnecessary active reminder.
- Account balance equals a rebuild from account entries.
- Entitlement remaining equals a rebuild from its ledger.
- Match allocations never exceed allowed source amount.
- A financial transfer is not counted as income or expense.
- Planned amount, actual amount, matched amount, and variance remain separately inspectable.
- User can see why an automated match was suggested.
- Corrections/reversals create history rather than deleting or overwriting it.
- Date-only values are not stored as midnight UTC as a semantic shortcut.
- User-facing dates, numbers, errors, and controls remain Persian-first and RTL-correct.

## 11. Future ideas, not current commitments

- Optional on-device AI adapter after deterministic rules and heuristics are reliable.
- Multi-currency conversion and cross-currency reporting.
- Bank APIs or other external account connectors.
- Broader file import formats and richer SMS provider parsers.
- Attachment encryption and advanced document indexing.
- Forecasting, anomaly detection, subscription detection, and cash-flow simulation beyond deterministic baseline.
- Full accounting/reporting features beyond the lightweight personal dashboard.

These ideas must not become prerequisites for the local core or silently expand the current product scope.

## 12. Source references

This specification was derived from the repository contract in [`AGENTS.md`](../AGENTS.md), the current product summary in [`README.md`](../README.md), domain rules in [`docs/ARCHITECTURE_AND_DOMAIN_RULES.md`](ARCHITECTURE_AND_DOMAIN_RULES.md), implementation sequencing in [`docs/IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md), the Drift schema in [`lib/core/database/app_database.dart`](../lib/core/database/app_database.dart), and the current composition/UI in [`lib/main.dart`](../lib/main.dart) and [`lib/app/planact_app.dart`](../lib/app/planact_app.dart).
