# Internal simplification — bounded checkpoint

## Acceptance contract (2026-10-12, before implementation)

Behavior-neutral scope: remove the deprecated constructor match-list override in
FinancialExpectationUseCases and the unreferenced single-reason holiday lookup;
aggregate active financial allocations once per settlement query instead of
rescanning every match for every expectation. No user capability is removed.

Existing entry path: HomeShell / Commitment Details → FinancialExpectationUseCases
→ repository expectations and matches → settlement projection → Today / details /
financial consumers. This is a read projection; creation, correction, allocation
admission and durable writes remain unchanged. Holiday consumers already use the
multi-reason lookup; all overlapping reasons and provenance must remain available.

Observable acceptance:
- Partial/full settlement, unmatched expectations, currency separation, currencyless
  expectations, archived expectations and inactive matches retain existing semantics.
- Every query reads current repository matches, including subsequent replacement or
  reversal; no projection cache or parallel match source is introduced.
- Existing ordering is retained; missing currency still yields no allocated Money.
- Existing failures propagate through the unchanged command gate/repository path.
- No schema, enum, migration, backup format, durable state, UI styling, notification
  behavior, permissions or dependency changes. Restart/backup contracts are unchanged.

Evidence required: reference search, baseline financial/holiday unit tests,
additional allocation-projection regression tests, formatting, full analyzer and
full Flutter test suite. No device journey is required for this internal refactor;
existing native/release gates are not waived. Independent acceptance review remains
separate from implementation and must be performed by the maintainer/reviewer.

## Verification

- Baseline: financial expectation and Iranian holiday unit tests passed (12 tests).
- Implemented: removed two unused/deprecated internal API paths. Settlement reads
  matches only from its repository and aggregates once by occurrence/currency,
  preserving active-match filtering, unknown currency, archive and result order.
  The aggregation map exists only for a query, not as durable or cached state.
- Added coverage: multiple payments, partial settlement, separate currencies and
  occurrences, reversed/corrected matches, unknown currency, archive preservation,
  and replacement of repository matches between queries.
- Full analyzer: no issues. Diff whitespace check: passed.
- Full Flutter suite: passed, 763 tests (final output: All tests passed!). Includes
  repository migration/backup/cold-reopen tests and widget consumer journeys.
- Changed Dart files formatted successfully. Production code net reduction: 10
  physical lines; benefit is two fewer API paths and one allocation pass, not a
  claim of large-scale code removal or reference-device performance improvement.
- Suite warning observed: finance_transaction_form_test.dart:68 reports a missed
  tap target. Not suppressed or changed by this refactor; maintainer should inspect
  that separate test's interaction evidence. No claim about its pre-change origin.
- No persisted/domain semantic decisions, migrations or dependencies added.
- Owner: maintainer/reviewer. Next action: independently review the diff and evidence.
- Exposure: existing features unchanged; this checkpoint is not new release readiness.
