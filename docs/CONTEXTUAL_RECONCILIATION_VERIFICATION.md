# Priority 10 — Contextual reconciliation checkpoint

Date: 2026-10-06

## Implemented scope

- Today unmatched-transaction actions pass the exact stable transaction identity, rather than switching to generic Finance.
- Finance transaction actions open the same contextual route.
- SMS confirmation feedback passes the identity of the committed imported entry, not the staged suggestion or another ledger entry.
- The application layer reloads durable transaction, account, existing allocations and commitment occurrences. Income/expense forms are unchanged and not duplicated.
- Users explicitly select an occurrence and enter an integer allocation. Partial allocation is supported; subsequent submissions can allocate the remaining amount to another occurrence.
- Refresh and failed confirmation retain selected occurrence and entered amount. Back returns to the source without creating a match. Successful confirmation persists through existing reconciliation repositories and refreshes Today.
- Matching does not create expectations, mutate occurrence outcomes, consume entitlement or change account entries. Reversed entries and internal transfers are not eligible for this bounded flow.
- Archived commitment occurrences remain selectable as labelled historical targets.

## Evidence

The focused regression file is [contextual_reconciliation_test.dart](../test/widget/contextual_reconciliation_test.dart).

Seven tests cover exact transaction navigation from Today in Light/Dark, SMS confirmation identity with another transaction present, cancellation without ledger mutation, partial allocation and excess rejection, preserved draft after refresh and stale-allocation failure, explicit retry, and file-backed database restart preserving transaction/occurrence identity and remaining allocation.

Final validation:

- Dart formatting completed.
- Flutter analyzer: no issues found.
- Full Flutter test suite: **335 passed**.
- Existing full-state backup/restore tests also passed in that run. No persisted schema or dependency was added; existing match and allocation tables remain the backup source of truth.

## Proportional visual coverage

| Surface | Status | Scope |
| --- | --- | --- |
| Today | Migrated | Existing action now opens contextual route; shared visuals unchanged. |
| Finance | Migrated | Existing transaction menu gains relationship action; transaction forms unchanged. |
| Inbox | Migrated | Confirmation feedback gains contextual action. |
| Relationship route | Compliant | Shared Material themes/spacing, Persian labels, Jalali year/date/time, selected indicator, loading/error/empty/exhausted states; Light/Dark widget coverage. |
| Other screens | Intentionally Unchanged | No shared visual-system change. |

## Explicit limitations and remaining gates

This is the bounded contextual navigation flow, not completion of all PRD matching requirements. Match correction, explicit overpayment policy, commitment-only targets without occurrences, bulk allocation and automatic suggestions are not added.

The UI prevents duplicate submissions and confirmation reloads the remaining amount before saving. This is **not cross-command serialization**: validation and match persistence do not form one atomic admission transaction. Independent concurrent match writers still require an atomic repository-level allocation gate before this flow can claim a general concurrency invariant. Existing CommandGate is not such a gate.

Draft preservation applies while the route remains alive; unsaved form drafts are not persisted across application termination. Saved matching and transaction context are durable.

Native SMS permission/delivery and device accessibility/visual evidence remain separate platform gates; these Flutter tests do not replace them. No sensitive telemetry or raw-message logging was introduced.
