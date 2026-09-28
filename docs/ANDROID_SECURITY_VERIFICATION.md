# Android security and release verification

## Policy

- `android:allowBackup="false"` is explicit because the database contains financial and SMS-derived data. `data_extraction_rules.xml` also excludes cloud/device-transfer extraction.
- `android:usesCleartextTraffic="false"` and `network_security_config.xml` deny HTTP cleartext. PlanAct core remains local-first; any future network adapter must use TLS.
- `MainActivity` is the launcher and is intentionally `exported="true"`. `BankSmsReceiver` is the only public receiver and is restricted by `android.permission.BROADCAST_SMS`. Notification and boot receivers are explicitly `exported="false"`.
- `READ_SMS` and `RECEIVE_SMS` are requested only by the explicit SMS import flow. Denial returns no SMS data and must not block planning, finance, backup, or reminders.
- `POST_NOTIFICATIONS` is needed only for reminder delivery. Denial is non-blocking; persisted reminders remain in the domain and can be reconciled if access is later granted.
- `SCHEDULE_EXACT_ALARM` is retained because the Android adapter schedules `exactAllowWhileIdle` reminders. If the user revokes exact-alarm access, scheduling must fail gracefully while persisted reminders remain intact.
- `RECEIVE_BOOT_COMPLETED` is retained for rebuilding durable reminder notifications after reboot/update.

## Local verification

From the repository root, with Android SDK tools and a release keystore configured through environment variables or ignored `android/key.properties`:

```powershell
flutter analyze
flutter test
flutter build apk --release
cd android
.\gradlew.bat :app:processReleaseMainManifest :app:mergeReleaseResources :app:assembleRelease
cd ..
```

Inspect the merged manifest at `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml` and verify:

- application has `allowBackup="false"`, `usesCleartextTraffic="false"`, `networkSecurityConfig`, and data extraction rules;
- no component with an intent-filter is accidentally exported;
- PlanAct exports only `MainActivity` and the SMS receiver;
- the SMS receiver has `android.permission.BROADCAST_SMS`;
- dependency receivers are either non-exported or protected by a system/signature permission (AndroidX profile installer uses `android.permission.DUMP`);
- no unexpected permission was introduced by dependency merge (`VIBRATE` is expected from local notifications).

Use Android build tools against the release artifact:

```powershell
$apk = "build\app\outputs\flutter-apk\app-release.apk"
$buildTools = Get-ChildItem "$env:ANDROID_SDK_ROOT\build-tools" | Sort-Object Name -Descending | Select-Object -First 1
& "$($buildTools.FullName)\aapt.exe" dump permissions $apk
& "$($buildTools.FullName)\aapt.exe" dump xmltree $apk AndroidManifest.xml
& "$($buildTools.FullName)\apksigner.bat" verify --verbose --print-certs $apk
```

The release must not be signed with the Android debug certificate. CI additionally checks package/version/ABI, alignment, ZIP integrity, certificate fingerprint, and checksums through `validate_android_release.sh`.

## Device/emulator matrix

On Android 13+ and one pre-13 API level, install the release APK and verify:

1. Deny SMS permissions: the app remains usable; import shows an understandable Persian denial state; no SMS body is logged or imported; granting later enables import.
2. Deny notifications: planning and reminder persistence still work; no crash occurs; granting later and reconciliation restores upcoming notifications.
3. Revoke exact-alarm access (where supported): reminder creation remains persisted and the app reports delivery limitation without deleting the reminder.
4. Schedule a reminder, reboot the device, and verify the boot receiver rebuilds only active upcoming notifications; completed/cancelled reminders are not active.
5. Send a test SMS while SMS capability is granted and verify the restricted receiver stages only a relevant message; with access denied, no data crosses the bridge.
6. Attempt cleartext HTTP from a debug-only test harness and verify it is rejected; release contains no cleartext exception.

Record device API level, install/build version, granted permissions, and pass/fail results with each release candidate. Do not include raw SMS text, sender identifiers, financial values, or backup contents in the record.
