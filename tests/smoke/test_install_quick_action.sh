#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
services_dir="$(mktemp -d)"
work_dir="$(mktemp -d)"
trap 'rm -rf "$services_dir" "$work_dir"' EXIT

"$repo_root/scripts/install-quick-action.sh" --services-dir "$services_dir"

for workflow_name in \
  "Convert to PDF (Report)" \
  "Convert to PDF (Memo)" \
  "Convert to PDF (Handout)" \
  "Merge to PDF (Packet)" \
  "Merge to PDF (Compiled)"; do
  workflow_dir="$services_dir/$workflow_name.workflow"
  test -d "$workflow_dir"
  test -f "$workflow_dir/Contents/Info.plist"
  test -f "$workflow_dir/Contents/document.wflow"
done

cp "$repo_root/tests/fixtures/basic.md" "$work_dir/basic.md"
cp "$repo_root/tests/fixtures/merge-a.md" "$work_dir/merge-a.md"
cp "$repo_root/tests/fixtures/merge-b.md" "$work_dir/merge-b.md"

automator -i "$work_dir/basic.md" "$services_dir/Convert to PDF (Report).workflow"
test -f "$work_dir/basic.pdf"

automator -i "$work_dir/merge-a.md" "$work_dir/merge-b.md" \
  "$services_dir/Merge to PDF (Compiled).workflow"
test -f "$work_dir/merge-a-compiled.pdf"

"$repo_root/scripts/uninstall-quick-action.sh" --services-dir "$services_dir"
for workflow_name in \
  "Convert to PDF (Report)" \
  "Convert to PDF (Memo)" \
  "Convert to PDF (Handout)" \
  "Merge to PDF (Packet)" \
  "Merge to PDF (Compiled)"; do
  test ! -e "$services_dir/$workflow_name.workflow"
done
