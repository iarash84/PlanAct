# ADR 0002: UUIDv7 stable identifiers

- Status: Accepted
- Date: 2026-09-20

## Context

Persisted domain entities require stable identifiers independent of local SQLite row identifiers. The repository contract permits UUIDv7 or ULID and requires the final choice to be recorded.

## Decision

Use UUIDv7 strings for stable domain identifiers. Generation uses the current UTC Unix timestamp in milliseconds, UUID version/variant bits, a per-millisecond sequence, and cryptographically secure random payload bytes.

No third-party ID dependency is introduced at this stage. Parsing accepts canonical lowercase or uppercase UUIDv7 text and normalizes it to lowercase.

## Consequences

- IDs are globally practical and roughly time ordered.
- SQLite row IDs are never exposed as domain identity.
- Timestamp ordering is not a substitute for an explicit domain timestamp.
- If generation later moves to a maintained package, compatibility with persisted UUIDv7 strings must be preserved.
