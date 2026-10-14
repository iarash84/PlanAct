# Priorities 6 and 7 — partial implementation checkpoint

Status: **Partial**, not release acceptance. Existing priorities 1–5 keep their independent unresolved gates. Priorities 8–10 were outside the original checkpoint; the user-approved Undo follow-up below includes a bounded real-match correction path.

## Review regression fixes acceptance contract — 2026-10-14

User-authorized scope, in review priority order: (1) Finance cancellation/correction
of an allocated payment must restore its unpaid remainder consistently in Today,
expectation settlement and Reports; (2) successful Actual/schedule reopening must
consume its recovery intent without overriding a later explicit reminder-instance
cancellation; (3) editing an archived/paused commitment through history/Details
must not schedule notifications for an ineligible owner/cycle. Existing explicit
confirmation, retry and committed-versus-platform-delivery feedback stay intact.

Trace: Finance menu → atomic reversal/correction → retained ledger/matches → root
refresh → read-only settlement/Today/report projections. Details reopening/edit →
durable occurrence/result command → atomic reminder intent → post-commit platform
delivery → Details/root refresh and startup/resume reconciliation. Keep existing
history, matching, entitlement and recurrence semantics; no automatic unmatching,
legacy repair, new permission, dependency, schema migration or UI redesign.

Required evidence per fix before proceeding: failing regression followed by focused
passing tests and analyzer; financial file-backed reopen/snapshot preservation and
remaining live allocations; reminder interruption/rollback, multi-rule recovery,
later cancellation, snooze and delivery failure; archived/paused owner and inactive
cycle admission with active-owner scheduling retained. Finish with the full suite,
scoped formatting and diff checks. Native delivery/reboot, device restore,
older-writer compatibility and independent acceptance remain unexecuted release
gates owned by release QA/product reviewer. Maintainer owns software fixes;
exposure remains Partial until those gates are evidenced.

## Review regression fixes implementation and evidence — 2026-10-14

This checkpoint supersedes the earlier software-safety claims only for the three
review findings. All unrelated limitations below remain open.

1. Settlement reads expectations, match history and ledger evidence in one SQLite
   read transaction. Reversed transaction allocations are excluded from current
   settlement and Today totals, consistent with Reports. Matches and ledger rows
   remain intact; a corrected transaction requires its own explicit allocation.
2. Occurrence synchronization prepares every rule's intent and consumes reopening
   recovery in one writer transaction, before external cancellation/scheduling.
   Persistence failure rolls back the whole batch and retains recovery; delivery
   failure retains complete committed intent. Later instance cancellation, snooze
   and delivered history survive reconciliation and cold reopen. Schedule Undo
   uses the same synchronization path.
3. Shared scheduling checks fresh owner/cycle/occurrence eligibility inside writer
   admission. Inactive history edits keep their approved durable schedule behavior
   while cancelling stale delivery and avoiding a new cancelled replacement that
   would suppress recovery on resume. Pending reopening is retained for inactive
   owners until eligible restoration. No new notification is scheduled for them.

Per-fix evidence before proceeding: the six new financial repository cases failed
on the original settlement logic, then the focused eight-file suite passed **51**
tests and the added root Finance → Today cancellation journey passed **1**. The
four reopening regressions failed before repair; the focused eight-file reminder
suite passed **42** tests afterward. Nine eligibility cases failed before repair;
an additional archived-reopening counterexample drove preservation of pending
intent. Final eligibility/reopening/real-route checks passed **22** tests. Each
stage's analyzer passed. An incorrect new test expectation was corrected from
15 minutes after to the approved 15 minutes before the occurrence; modal journey
tests now pump dialog transitions without waiting on the underlying busy spinner.
These were test corrections, not recurrence or reminder-policy changes.

New regression sources: `reversal_settlement_regression_test.dart` covers both
directions, correction, remaining valid partial payments, production file-backed
reopen and redacted personal SQLite snapshot restoration without history mutation.
`reminder_reopening_regression_test.dart` covers atomic multi-rule rollback,
interrupted recovery, post-commit delivery failure and subsequent cancellation.
`reminder_eligibility_regression_test.dart` covers archived/paused owner restoration,
inactive cycles, resolved outcomes and deferred reopening. Added actual widget
journeys exercise root Finance cancellation/Today refresh and the Details Jalali
date editor for archived and paused owners with a fake platform adapter.

Escape-process note: previous coverage tested reversals and matching separately,
cancelled reminders after startup recovery rather than after successful reopening,
and lifecycle eligibility only in reconcile. The added tests cross those boundaries
and protect both direct scheduling and downstream financial projections.

Implemented scope: all three reported software fixes; no schema/migration,
dependency, user copy, persisted enum or history repair. Backup effect: existing
reversal/reopening evidence is read or consumed through established durable stores;
no new backup format. Acceptance comparison is self-review, not independent release
sign-off. Native notification permission/delivery/reboot, isolated device restore,
older-writer compatibility and independent acceptance remain unexecuted blockers.
Maintainer owns software follow-up; release QA/product reviewer owns the remaining
device/independent gates. Exposure remains **Partial**, with production release
blocked by those gates.

Final integration evidence (Windows host, working tree based on `5d9445a`):
`flutter test --no-pub --reporter expanded` passed **888 tests, zero failures**
in **4m36s**, including 23 new regression cases. The three original external
review counterexamples also passed after all fixes. Final
`flutter analyze --no-pub` reported **no issues** (5.8s); scoped
`dart format --output=none --set-exit-if-changed` covered all eight changed/new
Dart files with **zero changes**, and `git diff --check` passed. Raw full-suite
output is an ignored local artifact at
`build/verification/review-regression-full-tests.log`. A simultaneous external
test attempt hit the shared native-assets DLL lock; after the full run completed,
the external tests ran successfully. No build/device/native delivery was executed.

## Undo repair acceptance contract — 2026-10-14

User-approved scope: Finance transaction cancellation/correction and account archive/restore; commitment lifecycle Undo; real-match removal/correction; partial-result reopening; audited date/time schedule Undo and consistent Persian feedback. Actual entry routes are Finance transaction/account menus, commitment action sheet and Details occurrence menus. Core paths are offline and require no new permission.

Success requires fresh SQLite writer admission, atomic append-only history plus domain writes, explicit confirmations, preserved financial/entitlement/Actual history, stale-token rejection, durable recovery after cold reopen, and root Today/Calendar/report refresh. Transfer cancellation reverses both legs and its recorded fee together, visibly confirmed. Repeated cancellation cannot alter balance again. Undo restores only the latest eligible operation, never overwrites a later command, and is available beyond a transient snackbar. Unknown legacy history is not synthesized or silently repaired. Reopening a result changes no money or consumed entitlement; partial outcomes can be explicitly reopened. Schedule Undo refuses past/protected/changed effects and retains all schedule versions.

Persistence decision: use versioned append-only records in the established schema_metadata extension store, with per-owner durable heads and before/after snapshots. No table/schema/dependency change is planned. Native SQLite personal backup preserves these records; prior snapshots without them remain readable. Semantic older-writer/downgrade safety is not implied. Evidence required: production SQLite stale/repeat/rollback/cold-reopen/backup checks, real route cancellation/confirmation/Undo/error/refresh journeys, report/attention counterexamples, localization generation and analyzer/full regression. Device notification delivery and independent release acceptance remain separate gates. No automatic entitlement consumption, historical legacy repair, overpayment policy or new recurrence mode is included.

## Implemented path

- Commitment Details exposes a shared Jalali date picker and explicit date/time edit scopes: only this, this and following, or future automatic occurrences of the active cycle.
- Writes reload the plan transactionally, reject stale input and resolved/past occurrences, preserve manual overrides, original values and stable occurrence identifiers, and retain older schedule definitions.
- Recurring date/time edits create a schedule version. Fixed-count/manual schedules, monthly/yearly date shifts and non-unit interval date shifts are rejected instead of inventing termination or recurrence semantics.
- Result choices include completion, attendance, cancellation, no-show and partial completion. Actual insertion and occurrence status update commit in one SQLite transaction. Reopening appends a new result and retains earlier results; it is not a financial or entitlement reversal.
- Existing actual fields cannot be overwritten through the repository; evidence addition still uses the existing evidence contract.
- Details offers result history with loading, empty and error states. Database commit and reminder delivery remain separate outcomes.
- No schema migration or dependency was introduced; the new outcome is appended to the persisted enum to retain existing indices.

## Evidence

Repository tests cover file-backed reopening, same-second append order, stale result rejection, transaction rollback, persisted schedule versions and preservation of manual/resolved rows. A widget test covers all-day date editing without inventing a time. These tests do not establish native delivery or complete product acceptance.

## Remaining acceptance gates

- Full recurrence frequency/termination editing, fixed-count remainder semantics and regeneration beyond the materialized horizon. Version boundaries and logical generation identity need explicit integration tests before claiming infinite/open-ended series editing complete.
- Append-only intermediate schedule edit audit: current storage retains original/current times and schedule definitions, not every intermediate single-occurrence change.
- Reopening restores an actionable scheduled/rescheduled state, not an exact prior status snapshot; no explicit reversal reference is stored. Partial results remain pending decision.
- Same-second ordering currently follows SQLite row insertion order. Production file backup retains it, but arbitrary logical row re-import/reordering is not yet proven. ABA/concurrent partial-result updates need a durable revision contract.
- Complete Today/Calendar outcome journeys, note/evidence capture, accessibility/large-text and both-theme acceptance, multiple-cycle history selection, and command refresh error boundaries.
- Reminder intent is synchronized after domain commit. Same-time interrupted reopening recovery and native cancellation/delivery retain the Priority 5 gates in TRANSACTIONAL_PLATFORM_VERIFICATION.md.
- No automatic policy/financial/entitlement consumption or reversal is added. Policy-confirmed consumption and correction remain separate commands.

Do not label priorities 6 or 7 fully implemented based on this checkpoint.

## Undo follow-up implementation and evidence — 2026-10-14

**Implemented bounded user paths:** Finance cancellation/correction, full transfer-group/fee compensation, account archive/restore with guarded Undo, commitment lifecycle Undo and a persistent history/archive entry route, active payment-match correction/removal with retained allocation history, partial-result reopening, and date/time schedule Undo. Metadata journals, heads and suspension/reopening intent are persistent. No migration, dependency, release-version change or historical backfill was introduced. PRD, AGENTS and ADR 0007 document the approved semantics.

Key changed consumers: Finance menus/forms and cash summaries; root lifecycle actions/history/refresh; relationship detail/history/correction sheet; Details occurrence actions and schedule Undo; production plan and Calendar range readers; actual/commitment/finance/reconciliation repositories; reminder admission/recovery; and the Persian catalog/generated resources. Database state stays authoritative; UI tokens only identify durable commands. Real-match removal/correction never changes money, results or consumed credit. Resolved allocations are retained rather than deleted/reinserted. Known legacy financial compensation is protected against another cancellation but is not automatically reclassified or repaired.

Schedule Undo retains intermediate audit, stable occurrence identity and every definition, and restores series via a forward version. All-day today remains a local date; timed values already elapsed today are protected alongside earlier dates. A new preparation/materialization, protected history, changed rules or another relevant write can invalidate the snapshot; that conservative refusal is intentional. Only the latest eligible operation is offered; multi-step Undo/Redo and unrestricted historical recovery are not claimed. Reopening is still an actionable scheduled/rescheduled state, not exact prior-status, money or entitlement restoration.

Reminder evidence now distinguishes interrupted same-time Actual reopening from an independently cancelled instance. Lifecycle suspension retains scheduled/snoozed intent and rule evidence; restoration preserves snooze and never revives a reminder that was independently cancelled before suspension. Fresh eligibility includes owner and cycle state. Delivery failure remains separate from a committed command and retries through durable reconciliation. This resolves the bounded software recovery gap, not native Android delivery/reboot acceptance.

**Verification:** Windows Flutter/Dart, local working tree, no signed APK/device run. The complete suite passed **865 tests, zero failures** in approximately 4m08s. After the final narrow Resume-versus-archive admission guard, 25 relevant domain/repository/real-route checks passed again; the final same-day time guard passed all 11 production repository checks. The complete suite was not repeated after those narrow guards. Final analysis reported no issues; generated Persian defaults and changed-file format, diff and local-link checks passed. Raw logs are ignored local artifacts under `build/undo-*.log`.

Acceptance comparison (self-review only): `undo_repair_test.dart` covers signed/repeated/concurrent reversal, full transfer fee cancellation with middle-failure rollback, correction rollback, stale lifecycle/account tokens, cold reopen and personal SQLite snapshot preservation, partial/ABA result admission, intermediate/forward schedule history, audit rollback and elapsed-time protection. `undo_repair_journeys_test.dart` covers root history access after snackbar expiry, cancellation/confirmation, archive Undo, Finance cancellation/correction and committed-refresh failure, real match correction/removal, Details schedule Undo and partial reopening. `reminder_interruption_recovery_test.dart` covers cold same-time recovery and preserved cancellation/snooze. Existing full-suite backup/schema fixtures and narrow/large-text Light/Dark finance/calendar checks remain passing. The older pre-migration-copy checksum remains unchanged; introduced Undo copy is explicitly marked and still receives metadata/placeholder/generation checks.

Escape-process note: previous coverage checked single correction balances and isolated action availability, missing repeated cancellation, reversal classification, the concrete correction form and Calendar/Details revision propagation. The new regression evidence adds these admission and entry-route counterexamples; test counts alone are not release evidence.

**Unexecuted / release blockers:** independent review; native notification permission/delivery/reboot and isolated device restore; realistic large-history journal/performance and full new-control accessibility acceptance; older-binary/writer policy enforcement; legacy financial recovery and unknown archive/reminder-history recovery. Existing full recurrence/frequency/count editing, note/evidence capture, multiple-cycle navigation and arbitrary logical row-reimport gates are not waived by this follow-up. Software-gap owner: feature maintainer. Native/independent acceptance owner: release maintainer/device tester. Next action: review these routes and compatibility policy against the final immutable device candidate; production release remains blocked until required gates are evidenced. Do not describe this bounded Undo implementation as universal Undo or full Priority 6/7 release acceptance.
