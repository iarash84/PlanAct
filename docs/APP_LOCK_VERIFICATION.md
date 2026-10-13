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

## Same-route settings refresh — 2026-10-11 acceptance contract

- Entry: More → Settings → app-lock switch, with persistent settings and available device authentication. Both enabling and disabling require fresh authentication and successful storage before the displayed value changes. The open route must show the confirmed value without closing, reopening or an artificial delay.
- Cancellation, authentication failure, storage failure and authentication invalidated by backgrounding retain the previous effective and displayed setting, show existing Persian feedback and allow retry. Busy feedback and duplicate-request prevention remain in place. Reversing the setting is another authenticated command, not an unauthenticated Undo.
- Trace: AppLockSettingsCard → PlanActApp._setAppLock → AppLockController.changeSetting/verify → AppSettings.writeAppLockEnabled → SQLite metadata → root setState → AppLockGate. More pushes a route containing a captured SettingsPage; root rebuilds do not replace that captured widget. The switch reads its old enabled property even after successful completion. The focused fix projects the successfully completed command in the mounted control and still accepts subsequent parent updates; it does not become a durable source of truth.
- Scope: same-route switch refresh and regression evidence only. Keep the root Navigator gate, forms, lifecycle generation invalidation, default-off semantics, storage and backup format unchanged. No migration, dependency, security bypass or visual-token change is planned.
- Evidence required: actual More/Settings route enable/disable, pending authentication/storage, cancellation, failed write/retry, background-interrupted authentication, cold widget reconstruction plus existing file-backed close/reopen, root pushed/modal protection and form-retention tests. Native authentication, process recreation, recents privacy and independent release review remain separate mandatory gates.
- Escaped check: prior tests covered command durability and failure feedback but did not assert the successful switch value on the captured, still-open Settings route.

### Implementation and verification result

- Bounded display fix implemented in AppLockSettingsCard: initialize from the application value, update after successful command completion only, and synchronize changed parent values. Existing busy/disabled and Persian feedback remain. No change to authentication, generation invalidation, root protection, SQLite schema, backup data, dependencies or product defaults; PRD/AGENTS safeguards remain unchanged.
- Same-route regression reproduced before the fix. Nine new route tests cover both directions in Light/Dark, pending authentication/write and duplicate taps, cancellation/write failure/background invalidation in both initial states with retry, and cold widget reconstruction from persisted settings. The host uses production HomeShell/More/Settings, controller and AppSettings, with controlled authentication/write failures; it mirrors root setting publication rather than exercising native local_auth or the complete production startup adapter.
- Additional modal-form regression proves the root gate hides an open dialog and preserves its draft after background/resume authentication. Existing pushed-route/form, cold-start gate, controller command and file-backed SQLite close/reopen tests remain passing.
- Validation on Windows Flutter test host: **26 related tests passed** across app_lock_settings_route_test, app_lock_lifecycle_test, app_lock_gate_test, app_lock_setting_change_test, app_lock_test and app_lock_settings_test. Scoped Dart formatting passed; flutter analyze reported no issues; git diff --check passed. The full suite and Android build were not rerun for this display-only fix.
- UI refresh criteria are supported by automated route evidence; native biometric/device-credential, actual process cold start, recents/snapshot privacy, device accessibility and independent acceptance review are **not executed** in this task. No new protection defect was established by this regression work; this is not a security certification and does not close the existing mandatory native gates above.
- Release decision: app-lock native readiness remains **Partial / blocked**, not ready for release. Owner: release/security maintainer; next action: execute the isolated-device matrix above, record build/device evidence and obtain independent review. Existing development exposure is unchanged; this task grants no production-release approval.
