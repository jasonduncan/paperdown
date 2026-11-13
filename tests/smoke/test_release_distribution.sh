#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

output_dir="$tmp_dir/export"
app_bundle="$output_dir/Paperdown.app"
zip_bundle="$output_dir/Paperdown-notarize.zip"

"$repo_root/Packaging/export-app.sh" \
  --configuration Debug \
  --output-dir "$output_dir" >/dev/null

"$repo_root/scripts/sign-macos-app.sh" \
  --app "$app_bundle" \
  --identity - >"$tmp_dir/sign.out"

codesign --verify --deep --strict --verbose=2 "$app_bundle"
codesign -dv "$app_bundle" 2>"$tmp_dir/codesign.out"
rg '^Signature=adhoc$' "$tmp_dir/codesign.out"

NOTARY_KEYCHAIN_PROFILE=dummy-profile \
  "$repo_root/scripts/notarize-macos-app.sh" \
  --app "$app_bundle" \
  --zip "$zip_bundle" \
  --dry-run >"$tmp_dir/notarize.out"

test -f "$zip_bundle"
rg '^Dry run: xcrun notarytool submit ' "$tmp_dir/notarize.out"
rg '^Notarization archive ready at ' "$tmp_dir/notarize.out"
