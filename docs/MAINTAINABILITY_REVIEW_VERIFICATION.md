# Behavior-neutral maintainability review — 2026-11-08

## Scope and acceptance contract

Selected seam: InboxUseCases.confirm currently mixes orchestration, draft validation, financial entry construction and non-atomic repository fallback. Extract private, purpose-specific methods without changing the public API, parser, domain rules or persistence adapters. Preserve earlier projection optimizations as-is.

Trace: Inbox Confirm → gated application confirmation → selected-unit and evidence validation → account validation → deterministic entry construction → atomic production adapter (or existing fallback) → existing route feedback/refresh. No widget or route changes are planned.

Acceptance: preserve validation order/messages, exact currency conversion, UTC timestamps, deterministic entry identity, expected revision/tag forwarding, production atomic admission, fallback write order, stale/rejected handling and retry idempotency. No public API/schema/dependency/default/visual changes. The fallback remains non-atomic; extraction must not claim it has production transactional guarantees. No migration or backup impact because durable representations and adapters are unchanged.

Minimum plan: isolate validated draft selection, entry construction and fallback persistence; retain orchestration inside the existing command gate. Add characterization tests for fallback selected-unit confirmation and original-snapshot retry. Run unit, production repository and affected widget regressions plus static analysis and formatting.

## Evidence

- Implemented: private draft validation/selection, deterministic entry construction and explicitly non-atomic fallback extraction in [inbox_use_cases.dart](../lib/features/inbox/application/inbox_use_cases.dart:667). Public orchestration retains its validation order, gate and production atomic forwarding. No domain decisions, schema migrations or dependencies were added.
- Added two characterization cases in [inbox_test.dart](../test/unit/inbox_test.dart:162): rial/toman selection preserves exact amounts, original evidence, confirmed revision and staged status; retrying the original pending snapshot returns the same financial entry without another write.
- Focused Inbox unit run: **13 passed**.
- Combined regression run: **440 passed**, covering the full unit suite, six production repository suites (Inbox confirmation, default unit, review repair, tag confirmation, currency evidence and extracted evidence), and two widget suites (draft tags and account selection). These include cold-reopen, logical-backup, stale admission, cancellation and retry checks in the existing suites. Logs are local ignored artifacts under the test-reports directory.
- Final static analysis: no issues. Formatting check: two files checked, zero changes. Final diff whitespace validation passed.
- Initial ordinary test launches were blocked before execution by a concurrent process locking the Windows SQLite native library. Successful runs used a temporary process-scoped Flutter configuration pointing to a separate build directory. The other process was not stopped and global Flutter settings were not modified.

## Scope and acceptance limits

Implementation and automated regression verification are complete for this bounded refactor; this is not a whole-repository cleanup or independent release review. No manual device/visual acceptance or independent review was performed. Existing native, backup and older-writer release gates remain unchanged; these tests do not grant broader release readiness. The existing compatibility fallback is still non-atomic, and production must continue to use the atomic adapter. Further cleanup is deliberately deferred rather than broadening this behavior-neutral change.
