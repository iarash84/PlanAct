# ADR 0007: Commitment use cases and repositories

- Status: Accepted
- Date: 2026-09-20

## Decision

Repository interfaces live in application-facing code. UI and future adapters invoke use cases rather than mutating persistence tables. Commitment lifecycle commands are separate use cases: create, pause, resume, and archive.

The repository contract is asynchronous and persistence-agnostic. The initial in-memory implementation exists for domain/application tests only; Drift persistence is added in P07. Each use case reads the current aggregate, applies a domain transition, and saves the new value, preserving the no-silent-mutation rule.
