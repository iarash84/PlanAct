# ADR 0001: Feature-first layered structure

- Status: Accepted
- Date: 2026-09-20

## Context

The project needs a predictable structure before product features are implemented. The domain must remain independent from Flutter widgets, Drift tables, and platform APIs.

## Decision

Use feature-first organization with explicit `domain`, `application`, `data`, and `presentation` layers where a feature requires them. Shared primitives belong under `lib/core`, and composition belongs under `lib/app`.

Allowed dependency direction:

- `presentation -> application -> domain`
- `data/infrastructure -> domain/application contracts`

No generic `utils`, `helpers`, or `services` dumping grounds will be introduced.

## Consequences

- New code has an explicit ownership boundary.
- Domain logic can be tested without Flutter or persistence.
- Empty directories are represented by this baseline README/ADR until their first implementation arrives.
