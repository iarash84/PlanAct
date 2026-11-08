# Behavior-preserving projection performance review

## Acceptance contract — 2026-11-08

Scope: reduce repeated full-collection scans in Today attention and personal-report projections. No presentation, product semantics, persisted state, schema, dependencies, platform delivery or command admission changes.

Entry paths: Today refresh → AttentionEngine.build/buildActionCenter; Reports route/filter refresh → buildPersonalReport. Existing readers supply durable snapshots; these pure projections perform no durable writes. Existing commands, confirmations, Undo, failure/retry and refresh paths remain unchanged.

Success: retain item ordering, unresolved/archived classification, exact signed account balances, separate currencies, partial settlement, reversal exclusion, and relationship-review history fingerprints (including inactive/corrected matches). Build temporary per-call indexes only; never reuse them across snapshots. Preserve the existing Money validation through rebuildBalance.

Plan: group matches by transaction once in each projection; group ledger entries by account once in Today. Pass only each owner's complete history to existing domain functions. Test mixed histories and bounded source-collection traversal as well as existing domain and route regressions. No database migration or backup format change is needed because indexes are transient and reconstructed on every call.

## Review findings

- Today projects each transaction review by filtering the entire match collection: O(entries × matches) unrelated-match scanning.
- Related-allocation reports also filter all matches for each entry, then repeat that scan for review projection.
- Today rebuilds each active account balance by scanning the full entry collection: O(accounts × entries).

The selected changes remove unrelated-item scans without replacing the financial/review rules. Per-owner fingerprint sorting and encoding remain necessary and unchanged. This is a bounded review, not a claim that all app performance issues have been audited.

## Evidence and limitations

Implemented: per-call transaction-history indexes in Today and Reports, and a per-call account-entry index in Today. Existing domain functions still calculate balances and relationship-review tokens. No visual, schema, dependency, persisted enum or backup changes.

Verification completed:

- Formatting of all three changed Dart files completed.
- Full-project static analysis: no issues found.
- Entire unit suite: 395 passed (includes the two new projection regressions).
- Four affected widget suites: 23 passed, covering Reports SQLite/filter/detail/refresh and narrow large text, Today settings/finance refresh, relationship queue routes and contextual reconciliation in Light/Dark.
- Whitespace/diff validation passed; production diff remains limited to the two selected projections.
- New fixtures cover 200 transactions with interleaved active/corrected histories and 40 accounts with mixed currencies, archived accounts, signed adjustments, transfers, reversals and a changed next snapshot. They bound source visits rather than elapsed time: Today match source at most twice, report match source at most three times, Today entry source at most three times, independent of transaction/account count.

Process gap addressed: existing semantic tests did not bound repeated full-source traversal, so correct small fixtures could conceal multiplicative scanning. The counting regressions now protect that specific cost without fragile wall-clock assertions.

Limitations/release decision: this is verified behavior-neutral projection optimization, not independent release sign-off or a full-app performance audit. Temporary indexes add O(entries + matches) references for each projection call; device memory/frame-time/startup profiling has not been executed. No numerical device-speed improvement is claimed. Owner: maintainer/release reviewer; next action: profile realistic long-lived data on the chosen reference Android device and independently review acceptance before claiming device-level performance. Existing feature-specific native/release gates remain in force; this patch does not waive them. No persistence/restart/backup format path was changed, so no new migration or native acceptance claim is made.
