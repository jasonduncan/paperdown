#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_root="$(mktemp -d)"
tmp_dir="$tmp_root/packaged app"
mkdir -p "$tmp_dir"
trap 'rm -rf "$tmp_root"' EXIT

services_dir="$tmp_dir/Library Services"
app_support_root="$tmp_dir/Application Support"
runtime_root="$app_support_root/paperdown-runtime"
work_dir="$tmp_dir/work items"

"$repo_root/Packaging/build-runtime-bundle.sh" --output-dir "$app_support_root" >/dev/null
"$repo_root/scripts/install-quick-action.sh" \
  --services-dir "$services_dir" \
  --runtime-root "$runtime_root"

test -d "$services_dir/Convert to PDF (Report).workflow"
rg "$runtime_root/bin/paperdown-quick-action" \
  "$services_dir/Convert to PDF (Report).workflow/Contents/document.wflow"

mkdir -p "$work_dir"
cp "$repo_root/tests/fixtures/basic.md" "$work_dir/basic.md"
automator -i "$work_dir/basic.md" "$services_dir/Convert to PDF (Report).workflow"
test -f "$work_dir/basic.pdf"

rm -rf "$services_dir/Convert to PDF (Report).workflow"
"$repo_root/scripts/install-quick-action.sh" \
  --services-dir "$services_dir" \
  --runtime-root "$runtime_root"
test -d "$services_dir/Convert to PDF (Report).workflow"

"$repo_root/scripts/uninstall-quick-action.sh" \
  --services-dir "$services_dir" \
  --runtime-root "$runtime_root"
test ! -e "$services_dir/Convert to PDF (Report).workflow"
