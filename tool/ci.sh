#!/usr/bin/env bash
set -euo pipefail

# Shared validation entry point for local development and GitHub Actions.
# CI supplies an ephemeral keystore; production release supplies the protected
# production keystore. No unsigned release artifact is accepted.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

flutter pub get --enforce-lockfile
dart run tool/generate_persian_copy.dart --check
dart run tool/generate_iranian_holidays.dart --check
dart format --output=none --set-exit-if-changed lib test
flutter analyze
# Keep assertion details and stack traces visible in GitHub Actions logs.
flutter test --reporter expanded

if [[ "${PLANACT_SKIP_ANDROID_BUILD:-false}" != "true" ]]; then
  flutter build appbundle --release \
    --build-name="${PLANACT_BUILD_NAME:-ci}" \
    --build-number="${PLANACT_BUILD_NUMBER:-1}"
fi
