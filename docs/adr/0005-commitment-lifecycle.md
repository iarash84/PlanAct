# ADR 0005: Commitment lifecycle

- Status: Accepted
- Date: 2026-09-20

## Decision

`Commitment` is the stable user concept and has the lifecycle `Active | Paused | Archived`. Its lifecycle is separate from occurrence status and cycle completion.

Valid transitions are:

- Active → Paused
- Paused → Active
- Active → Archived
- Paused → Archived

Archived commitments are historical and cannot be resumed or archived again. Domain transitions return a new immutable value and reject invalid transitions with a domain validation error.
