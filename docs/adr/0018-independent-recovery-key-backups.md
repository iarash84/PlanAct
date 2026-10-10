# ADR 0018 — Independent recovery-key backups

Status: Accepted for implementation from the explicit user mission (2026-10-10).
Supersedes ADR 0013 only for new export key ownership; its storage, validation,
rollback, command drainage and native verification safeguards remain binding.

## Acceptance contract (recorded before code)

Entry: More → backup/restore, with local database available; no account/network.
Each production export generates a fresh cryptography AES-256 key. Before any
file save, Persian UI displays the key, separate-storage and unrecoverable-loss
warnings, and requires explicit acknowledgement in that export. Cancellation
saves nothing. No key is logged, stored in secure storage or written to a sidecar.
A new offline installation restores format 2 from file plus user key alone.
Format 1 remains installation-key-only, with explicit warning/confirmation and
no rewriting or provisioning on import.

Trace: More card → recovery-aware file actions → ephemeral key/confirmation →
exclusive command drainage → isolated snapshot/encryption/validation → picker;
import picker → version validation → key input or legacy acknowledgement →
exclusive drainage → authenticated decryption → strict isolated SQLite validation
→ validated safety/marker/atomic replacement → repository rebind/reminder rebuild.
UI key dialogs occur before exclusive mode, because the host disposes feature
navigation while draining. Cancel, wrong key, tampering, incompatible schema and
write failures preserve current state. Post-replacement failures retain existing
rollback/recovery rules. Retry starts a new export with a new key.

## Format and scope

Format 2 retains AES-256-GCM, ciphertext SHA-256, schema compatibility checking
and version/schema authenticated data. Metadata identifies an independent raw
256-bit recovery key (not a password/KDF). Key text is canonical base64url;
invalid lengths/encoding are rejected. Format 1 metadata is unchanged.
No database migration or new dependency. No key escrow, password recovery,
automatic upload, automatic clipboard write or plaintext companion file.
The explicit 2026-10-10 follow-up permits user-initiated «کپی کلید» only, with
clipboard sensitivity warning and Persian success/failure feedback. Copy does
not satisfy the separate per-export safe-storage acknowledgement. Key-loss
warning uses shared bold title typography. No key persistence or format change.

## Required evidence and exposure

Automated independent-key/install, wrong-key/tamper, legacy, migrated-schema,
full logical state, write/rebuild failure, command drainage and Persian UI tests
are required. Native picker/storage, isolated fresh-install offline restore,
process interruption, notification and power-loss checks remain release blockers.
Owner: release maintainer; next action: run isolated-device checklist in
BACKUP_VERIFICATION.md. Do not claim device-loss readiness without those checks
and independent acceptance review. Never use the personal installation.
