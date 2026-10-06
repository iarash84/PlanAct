# ADR 0014 — Independently updateable offline holiday packages

Date: 2026-10-06
Status: Accepted implementation decision for the approved independent file-import feature

## Decision

Retain the bundled 1400–1405 baseline. Settings explicitly imports signed complete annual reference-data packages, without network access, runtime APIs or app releases. Each installed year replaces all official reasons for that year, preserving Friday weekends and scoped special-closure overlays. No command to scheduling, reminders, entitlement, actuals or finance is called.

Use existing crypto/cryptography dependencies: Ed25519 signs the exact UTF-8 payload bytes. A self-contained public key is NOT inherently trusted. First installation requires explicit user approval after comparing the SHA-256 public-key fingerprint through an independent trusted publisher channel. Later imports are pinned to that publisher and require a strictly increasing revision for an already installed year. Signature validity proves integrity and signer continuity, not official-calendar authority or factual completeness. No production publisher private key or pretrusted publisher is shipped.

An annual payload declares all twelve ordered Jalali months, correct day counts, unique official-day markers, and explicit officialFixed/officialVariable reasons. Validation checks marker/reason agreement, dates, bounded sizes, duplicate reasons and metadata. It cannot detect a publisher deliberately omitting the same date from both lists. The publisher must review every month against the published source and retain traceable review evidence. Never use approximate lunar conversion to manufacture future-year data.

## Persistence and failure

Store public packages separately in `holiday-packages.sqlite`, explicit schema/user_version 1. Creation is the forward migration from an empty version-0 store; unknown versions fail closed. Transactions atomically replace a year. Verify the existing envelopes before taking the synchronous SQLite write lock, then compare the snapshot inside the transaction; changed snapshots reject rather than overwriting concurrent work. Indexed year/revision columns must agree with signed content. No personal database schema change is required.

Startup revalidates every envelope and signer consistency. Corrupt reference storage is retained, the bundled baseline remains usable and Settings exposes an error. Imports are blocked while trust cannot be established. There is deliberately no silent trust reset, corrupt-row deletion, key rotation or recovery bypass; a future explicit recovery/rotation flow requires its own decision.

The public package database is NOT in personal backups. Restore does not replace it or change trust; users are told to retain the original package. A new installation requires importing that package and approving the publisher again. This is reference data, not user history. No new dependencies, internet permission, telemetry or sensitive logging are added.

## Publisher workflow

Use `dart run tool/holiday_package.dart keygen SEED_FILE` once with a protected offline path outside the repository. Restrict file permissions and back up the private seed securely. The seed must never be published or embedded in the application. Use `sign SEED_FILE REVIEWED_JSON OUTPUT` to sign a reviewed annual payload; the tool self-verifies and refuses to overwrite existing keys/packages. Use `verify PACKAGE` for signature/structure checks. Publish the printed fingerprint through a separate authenticated channel.

Payload fields: year (1400–1600), revision (positive integer), source (absolute HTTP(S) source URL), months (twelve objects: month, dayCount, officialDays), holidays (objects: month, day, Persian title, kind officialFixed or officialVariable). Empty months must be included explicitly; overlapping reasons use multiple rows on the same date. Envelope format is `planact-holidays-v1`, with base64 payload/publicKey/signature. Format changes may require a future app update; adding supported annual data does not.

## Scope and remaining gates

No real future-year calendar or official signing authority is fabricated. Downloading, special closures, key rotation, recovery UI and automatic scheduling changes are out of scope. Flutter tests establish application and real-file repository behavior; native file-picker/content-provider behavior still requires isolated device verification before release. Source accuracy is a separate annual review responsibility.
