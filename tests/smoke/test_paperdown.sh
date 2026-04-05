#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cp "$repo_root/tests/fixtures/basic.md" "$tmp_dir/basic.md"
cp "$repo_root/tests/fixtures/rich-content.md" "$tmp_dir/rich-content.md"
cp "$repo_root/tests/fixtures/basic.md" "$tmp_dir/service-env.md"
cp "$repo_root/tests/fixtures/merge-a.md" "$tmp_dir/merge-a.md"
cp "$repo_root/tests/fixtures/merge-b.md" "$tmp_dir/merge-b.md"
printf 'skip me\n' > "$tmp_dir/notes.txt"
printf 'existing file\n' > "$tmp_dir/basic.pdf"

convert_output="$("$repo_root/bin/paperdown" convert --style memo \
  "$tmp_dir/basic.md" "$tmp_dir/notes.txt" "$tmp_dir/rich-content.md")"
printf '%s\n' "$convert_output" | rg '^converted 2, failed 0, skipped 1$'
test -f "$tmp_dir/basic.pdf"
test -f "$tmp_dir/basic-1.pdf"
test -f "$tmp_dir/rich-content.pdf"
pdfinfo "$tmp_dir/rich-content.pdf" | rg '^Subject: +paperdown-memo$'

service_output="$(env -i HOME="$HOME" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  "$repo_root/bin/paperdown" convert --style report "$tmp_dir/service-env.md")"
printf '%s\n' "$service_output" | rg '^converted 1, failed 0, skipped 0$'
test -f "$tmp_dir/service-env.pdf"

"$repo_root/bin/paperdown" merge --mode packet --style report \
  "$tmp_dir/merge-a.md" "$tmp_dir/merge-b.md"
test -f "$tmp_dir/merge-a-packet.pdf"

"$repo_root/bin/paperdown" merge --mode compiled --style report \
  "$tmp_dir/merge-a.md" "$tmp_dir/merge-b.md"
test -f "$tmp_dir/merge-a-compiled.pdf"
pdfinfo "$tmp_dir/merge-a-compiled.pdf" | rg '^Title: +Project Notes$'

"$repo_root/bin/paperdown" merge --mode compiled --style report \
  "$tmp_dir/merge-a.md" "$tmp_dir/merge-b.md"
test -f "$tmp_dir/merge-a-compiled-1.pdf"
