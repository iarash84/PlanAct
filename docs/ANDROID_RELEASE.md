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

Update `pubspec.yaml` to the intended `X.Y.Z+N` version, commit that change, and push it to `master`. In GitHub, open **Actions → Release Android → Run workflow**, select `master`, and enter `X.Y.Z` without the `v` prefix or `+N` suffix. Do not create or push the tag beforehand: the workflow rejects existing tags/releases and creates `vX.Y.Z` only after validation and signed APK verification succeed. Pushing a tag alone does not trigger this workflow.

The current release target is `0.1.14+7`: a patch release for behavior-preserving cleanup and regression coverage. Enter `0.1.14` in the workflow; the resulting tag is `v0.1.14`.

The workflow checks the requested version against `pubspec.yaml` and uses it as Android `versionName`. Local builds default to the pubspec build suffix (`7` for this release), while published APKs override it with the release workflow's GitHub Actions run number as `versionCode`. Re-running a workflow run retains its number; a new run of the same workflow receives a higher number. Keep this numbering scheme and workflow identity stable, and verify that a release run number exceeds the versionCode of any previously distributed APK; the local suffix is not proof of that ordering. All universal and ABI-split release APKs use the same versionCode.

Flutter is pinned to 3.47.5 (Dart 3.13.4) in both CI and release workflows, matching the application's Dart SDK constraint. Shared validation resolves dependencies with the checked-in lockfile, checks formatting, runs analyze and tests, and builds a release App Bundle. CI uses an ephemeral signing key; the release workflow uses the production key and additionally builds Universal and ABI-split APKs, validates them, and generates SHA-256 checksums. Android R8 minification and resource shrinking are enabled for release builds; Flutter Dart obfuscation is also enabled for the release APKs. Universal and split builds write to separate symbol directories. Their symbol files are encrypted with the CI-only passphrase and retained as a 90-day Actions artifact, not attached to the public Release.

Release assets:

- `PlanAct-vX.Y.Z-universal.apk`: recommended for most users.
- `PlanAct-vX.Y.Z-arm64-v8a.apk`: most current Android phones.
- `PlanAct-vX.Y.Z-armeabi-v7a.apk`: older 32-bit ARM devices.
- `PlanAct-vX.Y.Z-x86_64.apk`: primarily emulators and specialized x86 devices.

After downloading the APKs and checksum file into the same folder, verify them with `sha256sum -c SHA256SUMS.txt`.

## Existing installations

Previous Release builds selected Gradle's machine-specific debug signing config. Debug certificates are not a stable production identity, and changing to the permanent release key means those APKs cannot be updated in place. The application ID is now `com.iarash.planact`, which is a new Android application identity and cannot upgrade an installation using the previous `com.example.planact` ID. Before switching, export a PlanAct backup and verify that it can be restored; then uninstall the old package and install the new signed APK.

## Device installation diagnostics

Install the selected APK from a connected device with:

```sh
adb install path/to/PlanAct-vX.Y.Z-universal.apk
```

Use `adb install -r` only when updating an installation signed with the same release key. `INSTALL_FAILED_NO_MATCHING_ABIS` means the chosen split does not contain the device ABI; use Universal or the matching ABI split. `INSTALL_FAILED_UPDATE_INCOMPATIBLE` means the installed package has a different signing certificate; back up app data, uninstall the old package, and install again. `INSTALL_FAILED_VERSION_DOWNGRADE` means the APK has a lower versionCode; install the newer build or remove the existing package after backup. `INSTALL_FAILED_OLDER_SDK` means the device Android version is below the APK minSdkVersion. `INSTALL_PARSE_FAILED_*` points to a malformed, truncated, or otherwise unreadable APK; re-download it and verify `SHA256SUMS.txt`. A package-name conflict indicates another package with the same application ID but a different signing identity.

For the exact Package Manager failure, run `adb install path/to/app.apk` and retain the complete output. The workflow also checks APK ZIP integrity, alignment, package/version metadata, minimum SDK metadata, ABI contents, and the non-debug signing certificate before publishing.

Obfuscation symbol artifacts are encrypted. To symbolicate a crash, download the matching tag's `PlanAct-vX.Y.Z-symbols-encrypted` Actions artifact, decrypt it with the retained `SYMBOLS_ENCRYPTION_PASSPHRASE`, and use the symbol directory matching the APK variant with Flutter's `flutter symbolize` command.