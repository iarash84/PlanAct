# Personal reports — acceptance contract

User-approved scope (2026-10-13): offline personal reports reached through More →
Reports, using existing durable records without new permissions or accounts.
Provide overview, performance, attention, cash flow, planned/settled payments,
packages, topic, upcoming, rescheduling and account movement views. Shared filters
include inclusive local/Jalali dates, stable-ID multi-tag any/all/exclusion/untagged,
commitment/cycle, status and relevant financial dimensions. All displayed totals
and drill-down rows must use the same filtered projection.

Trace: More tap → report reader → transactional SQLite snapshot → pure domain
projection → Persian RTL report sections and expandable details. Reading, changing
filters, cancellation and retry must never write occurrences, reminders, financial,
actual or entitlement state. Refresh replaces a complete snapshot; a failed read
shows a Persian retry state, never a fabricated empty report. Returning from a
record/action route reloads the report. Restore/restart reconstruct from existing
repositories; filters are explicitly temporary, no schema/migration/dependency.

Date semantics: performance uses current occurrence local date (changes may use
original date); cash uses transaction date; settlement uses occurrence due date,
with current confirmed allocations across payment dates; packages use ledger
balance at selected end-of-day, and ledger movement within the selected range.
These are current outcomes for selected scheduled dates, not a reconstruction of
unknown historical intermediate schedule/status states. Unknown result is distinct
from missed. Archived owners remain in history; upcoming excludes inactive owners.
Account balances use full ledger, never hashtag-filtered movements as a balance.

Financial tags are direct entry tags by default. Explicit related-allocation mode
attributes only matched amounts to selected commitments, without copying tags.
Distinct record identity prevents multi-tag duplication. Currencies remain
separate, including unknown expectation currency. Reversal movements affect the
original cash-flow direction on reversal date; transfers/opening/adjustments are
not income/expense. Independent transaction review uses the canonical projection.

Future previews reuse bounded read-only planned slots, in chunks of at most 31
local dates over a maximum 366-day selected range. They remain labelled previews,
with no occurrence IDs/effects or invented financial expectations. Recorded future
financial expectations are explicitly incomplete where preview slots exist.

Non-goals: exports, budgets, actual duration/on-time inference, forecast balances,
automatic categorization, historical tag membership reconstruction, intermediate
rescheduling-event counts and fixing unrelated release gates.

Required evidence: independent expected-value domain regressions for date boundary,
multi-tag overlap, partial allocation, review, reversal, currency and ledger folding;
SQLite cold reopen/read-only snapshot and older-cycle coverage; More-route widget
journey, filters/totals/details, error/retry/cancel, Light/Dark RTL and narrow large
text; formatter/analyzer/full existing suite. Native/device performance and visual
review plus independent acceptance remain separate release gates owned by the
release maintainer; next action is device review of this read-only route, with no
release-ready claim until accepted.

## Implementation and evidence

The ten report views, production transactional reader, pure projections, shared
filters, expandable rows and existing Details/relationship navigation are wired.
No migration, dependency, permission, stored report cache or platform adapter was
added. Finance's existing summary now uses its filtered rows; its former unfiltered
summary lacked a filter-to-summary regression, now covered by a widget check.

Package-credit limitation: existing creation can persist a configured entitlement
without a Grant ledger entry. The report exposes configured units and explicitly
withholds a reliable remaining balance when Grant is missing. No synthesized Grant,
consumption or historical repair is performed. This part is Partial for those
records. Owner: domain maintainer; next action: separately approve initial-grant
creation and historical recovery semantics. Exposure decision: disclose missing
ledger inside the report; never show configured units as usable remaining credit.

## Verification record

Environment: Windows, repository Flutter/Dart toolchain, 2026-10-13; working-tree
change on `feature/new-capabilities`, base `e28234f`. Implementation and automated
verification are separate from independent release acceptance.

| Acceptance scope | Evidence | Status / limits |
| --- | --- | --- |
| Inclusive dates, all-day values, stable multi-tag identity, any/all/exclusion/untagged, distinct cash records | `test/unit/personal_reports_test.dart` | Passed; explicit expected values independent of the projection |
| Separate currencies, reversal date and original classification, partial related allocation, due-date settlement, review invalidation | Same domain suite | Passed; refund/transfer/opening semantics use existing domain conventions |
| Ledger cutoff, missing Grant disclosure, archive history, reopening, original/current change date, full-ledger account balances | Same domain suite | Passed; missing Grant is still a data prerequisite, not repaired |
| Durable cold reopen, every-table equality before/after reads, multiple historical cycles | `test/repository/reports_reader_test.dart` | Passed with file-backed SQLite; includes archived owner and canonical typed tag memberships |
| Future previews across multiple 31-day chunks beyond materialization horizon | Same repository suite | Passed; occurrence rows unchanged and no financial/reminder intent inserted |
| More → Reports; tag summary/detail scope and refresh in Light/Dark RTL | `test/widget/reports_page_test.dart` | Passed using production SQLite reader |
| Direct Reports → Details → explicit Save → return and reread | Same widget suite + `test/commitment_details_test.dart` | Passed; existing action-sheet navigation retains the same Details composition |
| Failed load/retry, picker cancellation, all ten selectors at 360dp and 1.8 text scale | Same widget suite | Passed; large-text coverage is selector/empty-state coverage, not a populated-scale/device claim |
| Existing Finance summary follows tag filter | `test/widget/finance_report_filter_test.dart` | Passed; regression for previously missed summary/filter consistency |
| Formatting and whitespace | `dart format --output=none --set-exit-if-changed lib test`; `git diff --check` | Passed; 316 Dart files, 0 changes required |
| Static analysis | `flutter analyze` | Passed; no issues |
| Full application suite | `flutter test --reporter expanded` | Passed on final working tree: **808 passed, 0 failed**, 4m17s; includes existing migration, backup/restore, native-adapter seams and all prior widget journeys |
| Device visual/keyboard/accessibility and realistic-volume performance | Reference phone budget and data volume to be selected by release maintainer | Not run; next action: populated report journeys and measured snapshot/expansion performance before release sign-off |
| Independent acceptance | Human reviewer/maintainer, distinct from implementation self-review | Not run; no release-ready claim |

The first full execution recorded 807 passed / 1 failed in the newly added direct
Details journey before final route validation. The corrected route and existing
Details tests were then run sequentially: 8 passed. The final full run is required
for the final working tree; that earlier run is not completion evidence. Final
sequential run completed with **808 passed, 0 failed**. The change adds 21 tests
(13 domain, 2 repository, 5 report widget journeys and 1 Finance regression).

Exposure: this read-only route is implemented within the documented scope, with
incomplete ledger and preview financial coverage disclosed inline. Native/scale
review and independent acceptance are owned by the release maintainer; do not
announce release readiness based only on the automated counts. Existing backup,
app-lock, notification and SMS release blockers are unchanged.
