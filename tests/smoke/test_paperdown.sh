#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cp "$repo_root/tests/fixtures/basic.md" "$tmp_dir/basic.md"
cp "$repo_root/tests/fixtures/rich-content.md" "$tmp_dir/rich-content.md"
printf 'skip me\n' > "$tmp_dir/notes.txt"
printf 'existing file\n' > "$tmp_dir/basic.pdf"

"$repo_root/bin/paperdown" "$tmp_dir/basic.md" "$tmp_dir/notes.txt" "$tmp_dir/rich-content.md"
test -f "$tmp_dir/basic.pdf"
test -f "$tmp_dir/basic-1.pdf"
test -f "$tmp_dir/rich-content.pdf"
