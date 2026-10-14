# About page acceptance contract

Entry: Settings → «درباره پلن‌اکت»; no account, network or permission required.
The page explains the commitment lifecycle and available local surfaces in Persian,
without presenting planned features or pending release acceptance as complete.
It displays the installed version/build from PackageInfo, never a hard-coded release.
Loading, failure and explicit retry affect only version information.
The repository LICENSE supplies the app license and copyright; the licenses action
opens its full bundled text alongside dependency notices, with normal back navigation.
Privacy copy explains on-device core data, explicit SMS review and user-controlled
encrypted backup/recovery-key responsibility. No new storage or permissions.

Path: Settings callback → About route → platform package metadata → local UI refresh;
licenses read bundled assets/Flutter registry. No domain commands or database writes,
migrations, backup-format changes, new dependencies or downstream data effects.
Reuse shared Light/Dark theme, RTL, wrapping text and bounded scrollable content.

Required evidence: Settings navigation/back; actual metadata rather than package name;
metadata failure/retry; full app license visibility; 320dp at 2× text in Light/Dark.
Native visual/accessibility checks and independent acceptance are separate from tests.

Scope: About copy, license access, metadata states and Settings entry description.
Non-goals: new features, support contacts/URLs without a repository source,
changes to product license or any existing native release gate.

## Implementation and evidence (2026-10-13)

Implemented: Persian introduction, available sections, privacy/permissions,
backup/key responsibility and development status; installed metadata with explicit
failure/retry; shared tokens and width cap; bundled unchanged repository license
and Flutter license registry access. Settings entry copy is updated.
No domain decisions, migrations, dependencies or persisted changes.

Automated evidence: `flutter test test/widget/about_page_test.dart` passes 5 tests:
Settings → About → back, metadata pending/failure/retry, 320dp/2× RTL scrolling in
Light and Dark, full license navigation in Light and byte-for-byte license parity.
`flutter analyze --no-pub` and diff whitespace checks pass.
Combined About and existing presentation-polish regression run passes all 9 tests.
Regression cause: About retained a release-placeholder license despite an existing
repository LICENSE; asset parity and full-license navigation now guard this drift.

Unexecuted: native visual/TalkBack checks and independent acceptance. Owner:
maintainer; next action: review Settings → About → licenses on a reference device
in Light/Dark with large text. Exposure: local About update only, no claim that
the product's existing reminder/backup/security release blockers are resolved.
