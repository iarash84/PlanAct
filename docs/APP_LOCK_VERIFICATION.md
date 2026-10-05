# App lock — Priority 4 checkpoint

Date: 2026-10-05. Application implementation improved; native release acceptance remains **partial**.

## Behavior and implementation

- Protection is opt-in and defaults off when no setting exists. The existing SQLite metadata setting remains authoritative. A setting-read failure shows a blocking retry surface rather than exposing the home screen.
- Enabling and disabling require fresh device authentication. Authentication denial, cancellation, unavailable credentials or persistence failure do not change the enabled setting; the Settings control shows Persian feedback and permits retry. Concurrent setting/authentication attempts are rejected.
- Enabled cold starts lock before private content becomes visible. The gate wraps the root Navigator via the application builder, covering pushed pages, dialogs and sheets. Offstage preserves route/form state while preventing painting, hit testing, semantics and focus; tickers are paused while obscured.
- Inactive state obscures content immediately. Ordinary inactive/background transitions lock; inactive/resume caused by an in-flight native prompt does not launch a second prompt. Hidden/paused/detached transitions invalidate in-flight results so authentication completed after actual backgrounding cannot unlock the application.
- Authentication failure/exception retains the lock and exposes a Persian retry action. No custom PIN, reset bypass, automatic disabling, or destructive recovery was added. Device credential fallback remains enabled through the existing local_auth adapter; native prompt availability depends on device configuration.
- Android uses FlutterFragmentActivity and AppCompat launch/normal themes as required by local_auth. Existing SMS and notification-settings bridges are preserved. Sticky background authentication is disabled.

## Automated evidence

- Full Flutter suite: **271 passed**; analyzer clean; formatting and Git whitespace check passed.
- Isolated Android debug APK built successfully. No personal installation was replaced, cleared, or uninstalled.
- New coverage: generation invalidation, pushed-route protection with retained text input, prompt inactive/resume deduplication, exception/retry, Settings failure/retry, and file-backed SQLite enable/disable across close/reopen. Setting-command tests additionally prove denial never writes, failed persistence retains protection, disabling waits for persistence, background invalidates pending authentication, and concurrent changes do not duplicate writes.
- Existing cold-start, denial, controller, backup/full-state and reminder tests remain passing.

These tests use fake authenticators and are not native biometric/device-credential or cold-process evidence. The file-backed setting test proves storage reopen behavior, not Android process recreation.

## Persistence and backup

No schema migration or dependency was added. The pre-existing app-lock metadata remains included in database backup; restoration creates a fresh application generation and reloads the lock setting. Authentication session state is not persisted or exported. App lock protects UI access, not encryption of the database at rest, and does not change existing backup key recovery limitations.

## Required native acceptance

Use only the isolated verification package, never the personal production installation, to verify: biometric success, device PIN/password fallback, cancellation, temporary/permanent lockout, absent or removed device credentials, unavailable sensor, repeated taps, prompt interruption by Home/screen lock, cold process recreation, background/resume from pushed pages and modal forms, and external notification/SMS/file-picker settings return. Check notification-settings and SMS bridges after the activity-base change.

Verify native screenshots/recents behavior: a Flutter privacy cover alone is not proof that Android captures no private frame. Native window/snapshot protection has not been added in this checkpoint. Screen-reader focus, back/keyboard behavior, Light/Dark and large Persian text scaling also require device review. No release-complete claim is made until this matrix is recorded.

## Visual coverage

App Lock: migrated to shared spacing, theme typography/colors and scrollable content. Settings lock control: migrated to explicit busy/success/error states using themed Material controls. Navigator consumers: intentionally unchanged; the root gate covers them without feature-specific styling or destroying forms. No shared palette/typography or unrelated presentation redesign was introduced.
