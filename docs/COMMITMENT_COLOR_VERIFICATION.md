# Durable commitment identity color

## Scope and decisions

Commitment identity color is optional user-owned metadata, not an occurrence status, urgency, financial meaning, or outcome. The domain uses eight Flutter-independent stable keys: teal, blue, indigo, violet, rose, amber, olive, and cyan. Persist their names, never enum indices or color integers; published keys must not be renamed. No dependencies were added.

Null means Automatic. It remains null in storage: presentation resolves a deterministic identity color from the stable commitment ID. The shared palette hashes the ID's code units with a 32-bit FNV-1a-style fold and chooses one of the eight keys. This is not a hidden scheduling or status default. Different commitments can share a color; color is not a unique identifier. Keep text/other identity cues when consuming this palette.

Explicit colors survive metadata, tags, and every lifecycle copy operation. Metadata commands preserve the current color unless the caller explicitly requests a color update. Clearing an explicit color is an intentional update to null. No occurrence, entitlement, reminder, financial, archive, or scheduling semantics changed.

## Integration APIs

- Domain enum: [CommitmentColor](../lib/features/commitments/domain/commitment_color.dart:3).
- [Commitment](../lib/features/commitments/domain/commitment.dart) accepts nullable color in construction/creation and exposes an immutable `withColor` operation.
- [CreateCommitment](../lib/features/commitments/application/commitment_use_cases.dart) and [CreateCommitmentPlan](../lib/features/commitments/application/commitment_plan_use_case.dart) accept optional color.
- [UpdateCommitmentMetadata](../lib/features/commitments/application/commitment_use_cases.dart) accepts optional color and `updateColor` (false by default). Use true with null to return to Automatic; omission preserves fresh persisted metadata.
- [CommitmentDraft](../lib/features/commitments/application/commitment_draft.dart) carries color across wizard steps/retries. Its `copyWith` preserves omitted color; `clearColor: true` clears it.
- [CommitmentIdentityPalette](../lib/app/theme/commitment_identity_palette.dart) exposes `fallback`, `resolve`, `background`, `foreground`, and Persian `label`. Consumers should resolve the commitment's nullable key with its stable ID, then use the current brightness for both members of the foreground/background pair. Do not substitute a status color.
- [CommitmentColorPicker](../lib/features/commitments/presentation/commitment_color_picker.dart) accepts selected nullable color, an onChanged callback, and enabled state. It uses themed choice chips, Persian labels, and an explicit Automatic choice.

The existing commitment wizard and details editor reuse this picker and existing application commands. Saving disables selection. Details dirty-state detection includes color changes. Root app edits are limited to forwarding draft color and details editing; Calendar/week integration and PRD/design governance updates are owned by the parent task.

## Persistence, migration and backup

Schema 18 adds nullable commitments.color_key with a CHECK constraint restricting values to the eight published keys. Migration from earlier schemas adds the column without recoloring old records; old records remain null. Generated Drift bindings and repository read/write mappings include the field.

Strict backup validation remains intact. Fresh schema 18 is compared exactly. Trusted migrated schemas are admitted only by exact whole-schema SHA256 fingerprints derived from checked-in real migration output, then data is checked in the isolated trusted schema. Unknown schema alterations, mixed constraints, and malformed rows are not newly accepted. Version and integrity checks remain unchanged. This work does not add import/upgrading of old-version backup packages.

Historical schema inputs and older golden outputs are retained. New *-v18 fixtures were produced through actual AppDatabase migrations. The input named fresh-v17.json is reconstructed from the already committed fb69495-v17.json schema declarations; despite its conventional fixture name, it represents a migrated schema-17 database, not independently generated fresh-v17 DDL. Its corresponding v18 fixture protects that upgrade route.

Encrypted full logical-state backup tests now include both an explicitly colored and an Automatic commitment. They retain cold-reopen restore equality and rollback coverage. Existing installation-bound key portability and native restore release gates are unchanged; these tests do not prove device-loss recovery or native platform behavior.

## Verification

- Real historical migration golden regeneration and comparison cover schema 18, nullable historical color, and preserved pre-existing records/memberships.
- Color tests cover lifecycle/metadata/tag copies, deliberate reset, deterministic fallback, all eight Light/Dark contrast pairs (at least 4.5:1), file-backed create/edit/reset across cold restarts, and rejection of unknown stored keys.
- Shared picker tests cover selection, Automatic reset and disabled state in RTL Light/Dark.
- Wizard tests cover selected color through a failed save/retry in both themes. The existing persisted details/tag journey verifies an explicit color edit without resurrecting removed tags.
- Full encrypted backup logical-state restore, failed-rebuild rollback, schema compatibility and existing schema-tampering rejection tests pass.
- Full suite: flutter test --concurrency=2 — 410 tests passed. An earlier high-concurrency attempt encountered a Flutter VM crash; the reduced-concurrency full rerun completed successfully.
- flutter analyze — no issues found. Changed Dart sources and tests were formatted with dart format. Drift generation completed successfully.

## Remaining parent/release work

Calendar/week visual consumption and shared design/PRD documentation are intentionally not implemented here. Native platform backup/recovery gates remain as documented in the existing backup verification and ADR; no release gate is waived. Widget/contrast tests are not a substitute for a visual device review of parent-integrated calendar chips, mixed text, or text scaling.
