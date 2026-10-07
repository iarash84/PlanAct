# Today, Settings and Finance fixes — 2026-10-06

## Scope and files

- `lib/features/today/presentation/today_page.dart`: pull-to-refresh, with always-scrollable empty/error/content states.
- `lib/app/planact_app.dart`: refresh Today on tab return, Inbox return and Finance data changes; backup and holiday tools move to More.
- `lib/features/settings/presentation/settings_page.dart`: local presentation selection updates immediately on an already pushed route. Existing theme persistence remains unchanged.
- `lib/features/finance/presentation/finance_page.dart`: notify the shell after account/transaction mutations; use ledger-aware transaction labels and icons.
- `lib/features/finance/presentation/transaction_direction.dart`: shared financial direction presentation, using signedAmount, distinct incoming/outgoing icons, Persian semantic labels and existing Light/Dark success/attention foreground-container pairs. Ordinary withdrawals are not failures or destructive actions.
- `test/widget/today_settings_finance_refresh_test.dart`: regression checks.
- `docs/product/PRD.md`: current refresh and navigation behavior.

## Domain and safety

Refresh rereads local repositories and existing Attention projections; it does not create entries, change matching or alter history. Today continues to show transactions needing attention under existing rules, not every ledger record as an outstanding action. Transfers remain transfers; signed adjustments/reversals follow their actual account effect. No schema, migration, dependency, backup format or sensitive logging changes.

## Proportional presentation coverage

| Surface | Status | Evidence |
| --- | --- | --- |
| Today | Migrated | Empty short-list pull refresh rereads a persisted transaction from SQLite |
| Settings | Migrated | All three display choices update selection on the pushed production route |
| More | Migrated | Existing consent-bearing backup and holiday cards relocated without changing operations |
| Finance | Migrated | Incoming/outgoing icon and semantic color checks for every entry type and both signs in Light/Dark; existing transaction, tag and loading tests pass |
| Backup/holiday dialogs | Intentionally Unchanged | Existing cards and confirmation flows reused; full suite includes their tests |
| Other application surfaces | Intentionally Unchanged | No foundational theme or domain change |

## Validation

- Focused formatting: six changed/new Dart files formatted.
- Static analysis: no issues found.
- Targeted widget checks: 21 passed.
- Complete Flutter test suite: 347 passed.

## Limitations

No native-device gesture, screen-reader or visual certification is claimed. This task does not add background SMS ingestion, continuous database watching, or a daily ledger feed to Today. Existing backup portability and native release gates remain unchanged.
