#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
services_dir="$(mktemp -d)"
work_dir="$(mktemp -d)"
trap 'rm -rf "$services_dir" "$work_dir"' EXIT

"$repo_root/scripts/install-quick-action.sh" --services-dir "$services_dir"

workflow_dir="$services_dir/Convert Markdown to PDF.workflow"
test -d "$workflow_dir"
test -f "$workflow_dir/Contents/Info.plist"
test -f "$workflow_dir/Contents/document.wflow"

cp "$repo_root/tests/fixtures/basic.md" "$work_dir/basic.md"
automator -i "$work_dir/basic.md" "$workflow_dir"
test -f "$work_dir/basic.pdf"

"$repo_root/scripts/uninstall-quick-action.sh" --services-dir "$services_dir"
test ! -e "$workflow_dir"
