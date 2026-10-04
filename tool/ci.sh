#!/usr/bin/env bash
set -euo pipefail

# Shared validation entry point for local development and GitHub Actions.
# CI supplies an ephemeral keystore; production release supplies the protected
# production keystore. No unsigned release artifact is accepted.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

if [[ "${PLANACT_SKIP_ANDROID_BUILD:-false}" != "true" ]]; then
  flutter build appbundle --release \
    --build-name="${PLANACT_BUILD_NAME:-ci}" \
    --build-number="${PLANACT_BUILD_NUMBER:-1}"
fi
