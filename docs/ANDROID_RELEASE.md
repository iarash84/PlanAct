# Android Release

## Signing setup

Use one long-lived release keystore for every public build. Keep a secure offline backup; losing or replacing this key prevents existing installations from accepting updates. Never commit the keystore or `android/key.properties`.

GitHub Actions requires these repository or environment secrets:

- `ANDROID_KEYSTORE_BASE64`: base64-encoded keystore file.
- `ANDROID_KEYSTORE_PASSWORD`: keystore password.
- `ANDROID_KEY_ALIAS`: signing key alias.
- `ANDROID_KEY_PASSWORD`: signing key password.
- `ANDROID_SIGNING_CERT_SHA256`: expected signing certificate SHA-256 fingerprint, with or without colons. The workflow rejects a different certificate.
- `SYMBOLS_ENCRYPTION_PASSPHRASE`: strong random passphrase used to encrypt Flutter obfuscation symbols before they are stored as a CI artifact.

For local Release builds, create `android/key.properties` with these keys. `storeFile` may be an absolute path or a path relative to the `android` directory:

```properties
storeFile=C:/secure/keys/planact-release.jks
storePassword=...
keyAlias=planact-release
keyPassword=...
```

The same keystore and alias must be used locally and in CI. Release Gradle tasks fail when signing is absent or incomplete; they never fall back to the Android debug key.

Read the certificate fingerprint with `keytool -list -v -keystore path/to/planact-release.jks -alias planact-release` and store its SHA-256 value as `ANDROID_SIGNING_CERT_SHA256`.

## Creating a release

Update `pubspec.yaml` to the intended `X.Y.Z+N` version, commit that change, then push a matching `vX.Y.Z` tag. The workflow checks the tag against `pubspec.yaml`, uses the tag as `versionName`, and uses the monotonically increasing GitHub Actions run number as `versionCode`. Re-running a workflow run retains its number; a new run receives a higher number.

Flutter is pinned to 3.47.5. CI runs dependency resolution with the checked-in lockfile, analyze, tests, Universal and ABI-split builds, APK validation, and SHA-256 checksum generation. R8 and resource shrinking remain disabled; Flutter Dart obfuscation is enabled. Universal and split builds write to separate symbol directories. Their symbol files are encrypted with the CI-only passphrase and retained as a 90-day Actions artifact, not attached to the public Release.

Release assets:

- `PlanAct-vX.Y.Z-universal.apk`: recommended for most users.
- `PlanAct-vX.Y.Z-arm64-v8a.apk`: most current Android phones.
- `PlanAct-vX.Y.Z-armeabi-v7a.apk`: older 32-bit ARM devices.
- `PlanAct-vX.Y.Z-x86_64.apk`: primarily emulators and specialized x86 devices.

After downloading the APKs and checksum file into the same folder, verify them with `sha256sum -c SHA256SUMS.txt`.

## Existing installations

Previous Release builds selected Gradle's machine-specific debug signing config. Debug certificates are not a stable production identity, and changing to the permanent release key means those APKs cannot be updated in place. Before replacing an older installation, export a PlanAct backup and verify that it can be restored; then uninstall the old package and install the new signed APK. The application ID remains `com.example.planact` to preserve the identity of already-installed builds where signature compatibility permits.

## Device installation diagnostics

Install the selected APK from a connected device with:

```sh
adb install path/to/PlanAct-vX.Y.Z-universal.apk
```

Use `adb install -r` only when updating an installation signed with the same release key. `INSTALL_FAILED_NO_MATCHING_ABIS` means the chosen split does not contain the device ABI; use Universal or the matching ABI split. `INSTALL_FAILED_UPDATE_INCOMPATIBLE` means the installed package has a different signing certificate; back up app data, uninstall the old package, and install again. `INSTALL_FAILED_VERSION_DOWNGRADE` means the APK has a lower versionCode; install the newer build or remove the existing package after backup. `INSTALL_FAILED_OLDER_SDK` means the device Android version is below the APK minSdkVersion. `INSTALL_PARSE_FAILED_*` points to a malformed, truncated, or otherwise unreadable APK; re-download it and verify `SHA256SUMS.txt`. A package-name conflict indicates another package with the same application ID but a different signing identity.

For the exact Package Manager failure, run `adb install path/to/app.apk` and retain the complete output. The workflow also checks APK ZIP integrity, alignment, package/version metadata, minimum SDK metadata, ABI contents, and the non-debug signing certificate before publishing.

Obfuscation symbol artifacts are encrypted. To symbolicate a crash, download the matching tag's `PlanAct-vX.Y.Z-symbols-encrypted` Actions artifact, decrypt it with the retained `SYMBOLS_ENCRYPTION_PASSPHRASE`, and use the symbol directory matching the APK variant with Flutter's `flutter symbolize` command.