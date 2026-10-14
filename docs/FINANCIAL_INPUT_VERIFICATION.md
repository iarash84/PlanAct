# Financial input and Inbox feedback acceptance (2026-10-13)

Entry: Inbox -> edit/confirm transaction -> saved transaction tags; all monetary forms.
Canonical amounts display in the durable app preference, with exact integer IRR storage.
Manual/legacy monetary forms pin that preference; SMS review keeps explicit source-unit
evidence and suggests the app default when evidence is ambiguous.
SMS source evidence remains separately visible; missing/conflicting evidence requires
explicit reviewed-unit saving, and no saved history is reinterpreted.
Confirmed Inbox transactions offer the existing durable tag editor and Reports direct-tag filters.
Cancellation of tagging does not undo the financial transaction; tag errors support retry.
Money inputs group integer digits from the right, preserve signs and fractional input,
and must not turn malformed text into a different valid amount. Existing shared money
formatting applies to display and initial form values. No schema/dependency change.
Evidence required: formatter exactness/cursor tests, Inbox tag route with durable storage,
existing unit/report/backup regression suites, analyzer. Independent acceptance and
native visual review are separate unexecuted release gates.

Implementation plan: reuse tag repository/editor, wire production Inbox dependency,
share input grouping across monetary forms and untyped SMS amount displays.
Escaped check: monetary forms lacked a common formatter; existing tests covered
formatted display but did not require grouping during editing.

## Verification result

Implemented: default-unit suggestion in ambiguous SMS review; optional immediate
post-confirmation tagging; shared grouping for all monetary form keyboards and
initial values; grouping for original/ambiguous SMS and report amount text.
No persisted schema, new dependency, ledger mutation or historical migration.

Automated evidence: money input/unit/display tests; Inbox account/review routes;
unit preference routes; report routes including tag filters and narrow large text;
tag lifecycle and preference repositories; full-state personal backup regression.
The new Inbox journey creates a tag, verifies assignment/filter membership after
cold SQLite reopen, and preserves the relationship action after tagging. Default
unit review tests cover cancellation, explicit save, canonical conversion and
unchanged original ambiguous evidence. All executed checks passed after fixing
SnackBar queue interference. Dart analyzer: no issues; git diff --check: clean.

Acceptance self-review challenged signed/fractional amounts, invalid pasted groups,
ambiguous SMS under toman preference, tagging without a second financial entry,
cold reopen, and existing tag report consumption. This is automated verification,
not independent release sign-off. Remaining owner: maintainer/product reviewer;
next action: independent acceptance and native narrow-screen/keyboard review of
post-save tags and monetary forms. Exposure decision: source changes are available
for review; release readiness remains conditional on those checks and existing
SMS/report native gates. No release or deployment was performed.
