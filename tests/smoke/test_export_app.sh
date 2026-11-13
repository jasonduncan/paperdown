#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

output_dir="$tmp_dir/export"
export_output="$("$repo_root/Packaging/export-app.sh" \
  --configuration Debug \
  --output-dir "$output_dir" \
  --zip)"

app_bundle="$output_dir/Paperdown.app"
zip_bundle="$output_dir/Paperdown-Debug.zip"
runtime_root="$app_bundle/Contents/Resources/paperdown-runtime"

test -d "$app_bundle"
test -f "$zip_bundle"
test -x "$runtime_root/bin/paperdown"
test -x "$runtime_root/bin/paperdown-quick-action"
test -x "$runtime_root/vendor/bin/pandoc"
test -x "$runtime_root/vendor/bin/typst"

printf '%s\n' "$export_output" | rg "^app_bundle=${output_dir}/Paperdown.app$"
printf '%s\n' "$export_output" | rg "^zip_bundle=${output_dir}/Paperdown-Debug.zip$"
