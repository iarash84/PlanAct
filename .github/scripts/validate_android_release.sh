#!/usr/bin/env bash
set -euo pipefail

apk="$1"
expected_abi="$2"
expected_package="$3"
expected_version_name="$4"
expected_version_code="$5"
expected_certificate_digest="$(tr -d ':' <<< "${6,,}")"

if [[ ! "$expected_certificate_digest" =~ ^[[:xdigit:]]{64}$ ]]; then
  echo "Expected signing certificate fingerprint must be a 64-character SHA-256 digest." >&2
  exit 1
fi

if [[ ! -s "$apk" ]]; then
  echo "Missing or empty APK: $apk" >&2
  exit 1
fi

sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$sdk_root" || ! -d "$sdk_root/build-tools" ]]; then
  echo "Android SDK build-tools were not found (ANDROID_SDK_ROOT/ANDROID_HOME)." >&2
  exit 1
fi

build_tools="$(find "$sdk_root/build-tools" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V | tail -n 1)"
aapt="$sdk_root/build-tools/$build_tools/aapt"
apksigner="$sdk_root/build-tools/$build_tools/apksigner"
zipalign="$sdk_root/build-tools/$build_tools/zipalign"
for tool in "$aapt" "$apksigner" "$zipalign"; do
  if [[ ! -x "$tool" ]]; then
    echo "Required Android validation tool not found: $tool" >&2
    exit 1
  fi
done

unzip -t "$apk" >/dev/null
"$zipalign" -c -p 4 "$apk" >/dev/null

badging="$("$aapt" dump badging "$apk")"
package_line="$(printf '%s\n' "$badging" | sed -n '1p')"
package_name="$(sed -nE "s/^package: name='([^']+)'.*/\1/p" <<< "$package_line")"
version_code="$(sed -nE "s/.*versionCode='([^']+)'.*/\1/p" <<< "$package_line")"
version_name="$(sed -nE "s/.*versionName='([^']+)'.*/\1/p" <<< "$package_line")"
min_sdk="$(sed -nE "s/^sdkVersion:'([^']+)'.*/\1/p" <<< "$badging" | head -n 1)"

if [[ "$package_name" != "$expected_package" ]]; then
  echo "Unexpected package name in $apk: $package_name" >&2
  exit 1
fi
if [[ "$version_code" != "$expected_version_code" || "$version_name" != "$expected_version_name" ]]; then
  echo "Unexpected version in $apk: code=$version_code name=$version_name" >&2
  exit 1
fi
if [[ ! "$min_sdk" =~ ^[1-9][0-9]*$ ]]; then
  echo "Could not read a valid minSdkVersion from $apk." >&2
  exit 1
fi

actual_abis="$(unzip -Z1 "$apk" | awk -F/ '$1 == "lib" && NF >= 3 { print $2 }' | sort -u | paste -sd, -)"
if [[ "$expected_abi" == "all" ]]; then
  expected_abis="$(printf '%s\n' arm64-v8a armeabi-v7a x86_64 | sort -u | paste -sd, -)"
  if [[ "$actual_abis" != "$expected_abis" ]]; then
    echo "Universal APK ABI mismatch: expected $expected_abis, got $actual_abis" >&2
    exit 1
  fi
elif [[ "$actual_abis" != "$expected_abi" ]]; then
  echo "ABI mismatch in $apk: expected only $expected_abi, got $actual_abis" >&2
  exit 1
fi

signature_output="$("$apksigner" verify --verbose --print-certs "$apk" 2>&1)"
if grep -qi 'Android Debug' <<< "$signature_output"; then
  echo "Debug signing certificate detected in release APK: $apk" >&2
  exit 1
fi
certificate_digest="$(awk '
  /certificate SHA-256 digest:/ {
    sub(/^.*certificate SHA-256 digest:[[:space:]]*/, "")
    if ($0 == "") {
      getline
    }
    print
    exit
  }
' <<< "$signature_output" | tr -d ':')"
if [[ ! "$certificate_digest" =~ ^[[:xdigit:]]{64}$ ]]; then
  echo "Could not verify the APK signing certificate: $apk" >&2
  exit 1
fi
if [[ "${certificate_digest,,}" != "$expected_certificate_digest" ]]; then
  echo "Unexpected signing certificate in $apk; refusing a release signed with a different key." >&2
  exit 1
fi

echo "$apk: package=$package_name version=$version_name ($version_code), minSdk=$min_sdk, ABIs=$actual_abis" >&2
printf '%s\n' "$certificate_digest"