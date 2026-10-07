# Transactional/platform consistency — Priority 5 checkpoint

## Implemented boundary

SQLite and Android notification APIs cannot share an atomic transaction. Domain persistence commits first; external delivery is retried from durable rules, occurrences and reminder instances. No migration, dependency, platform ID backup requirement or additional mutable balance/entitlement counter is introduced.

- Commitment creation already wraps commitment, cycle, schedule, occurrence, policy, entitlement grant and financial expectation writes in the production plan transaction. Reminder failures after that commit now return explicit pending-delivery feedback instead of inviting duplicate creation.
- Reminder rule updates, stale-instance cancellation and replacement intent writes are committed together through the optional application-facing reminder transaction contract, implemented by Drift. Android cancellation/scheduling runs only after this transaction exits.
- Startup reconciliation repairs missing instances and stale scheduled times from enabled rules and eligible durable occurrences, transactionally, before rebuilding platform state. Repeated reconciliation keeps persisted identities stable.
- Occurrence commands distinguish a committed occurrence with pending reminder synchronization from a failed occurrence write. The currently exposed completion/restore UI updates its state and reports pending synchronization in Persian.
- Reconciliation preserves delivered history, unchanged snooze deadlines and explicit same-time instance cancellation. It does not modify finance matches, ledger entries or entitlement consumption.

## Evidence

`test/repository/reminder_interruption_recovery_test.dart` covers file-backed close/reopen with missing intent, stale intent after rescheduling, scheduling failure during committed creation, replacement intent persisted before Android cancellation failure, committed completion with failed cancellation, idempotent repeated recovery and preservation of snooze/delivery/cancellation history.

Existing creation rollback and reminder retry tests remain regression coverage. Existing finance transfer/correction, inbox atomic confirmation and match correction adapters retain their SQLite transactional boundaries; this checkpoint does not claim a new app-wide command serialization contract. The command gate protects backup retirement/admission, not mutual exclusion of every command.

## Remaining gates / limitations

- Simulated exceptions and SQLite reopen tests are not native process-kill, reboot, alarm-delivery or device permission evidence. Complete the independent reminder device verification matrix before release.
- A restored occurrence interrupted before same-time cancelled intent is reactivated is indistinguishable from explicit individual reminder cancellation under the current schema. Recovery deliberately preserves cancellation rather than silently resurrecting it. An explicit durable lifecycle/version intent is needed to eliminate this ambiguity.
- Generic platform failure can stop reconciliation before later platform cleanup; durable intent remains available for the next retry. No background worker or automatic infinite retry is added.
- Postcommit pending outcomes include failures in the reminder synchronization phase, including reminder persistence failures; they do not imply that notification scheduling succeeded. Original domain state remains committed and durable rules remain the recovery source.
- Cross-command races, comprehensive failure injection for every financial/session command, and occurrence actual/undo history are not completed by this checkpoint. Priorities 6 and 7 remain separate.

Presentation coverage is limited to existing Quick Capture/Quick Add committed-creation feedback and occurrence completion/restore feedback. Shared tokens, layout, typography and Light/Dark styling are intentionally unchanged; no app-wide visual redesign is claimed.
