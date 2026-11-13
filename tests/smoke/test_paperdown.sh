#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cp "$repo_root/tests/fixtures/basic.md" "$tmp_dir/basic.md"
cp "$repo_root/tests/fixtures/rich-content.md" "$tmp_dir/rich-content.md"
cp "$repo_root/tests/fixtures/basic.md" "$tmp_dir/service-env.md"
cp "$repo_root/tests/fixtures/compiled-cover.md" "$tmp_dir/compiled-cover.md"
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

settings_root="$tmp_dir/Application Support"
settings_file="$settings_root/paperdown/settings.json"
mkdir -p "$(dirname "$settings_file")"
cat > "$settings_file" <<'EOF'
{
  "compiledCoverPageEnabled": false,
  "compiledTableOfContentsEnabled": false
}
EOF

packaged_runtime="$("$repo_root/Packaging/build-runtime-bundle.sh" --output-dir "$settings_root")"

PAPERDOWN_SETTINGS_FILE="$settings_file" \
  "$packaged_runtime/bin/paperdown" merge --mode compiled --style report \
  "$tmp_dir/compiled-cover.md" "$tmp_dir/merge-b.md"

packaged_text="$(pdftotext "$tmp_dir/compiled-cover-compiled.pdf" -)"
if printf '%s\n' "$packaged_text" | rg -q 'A polished packet for sharing'; then
  echo "compiled subtitle should be omitted when cover-page default is disabled" >&2
  exit 1
fi
if printf '%s\n' "$packaged_text" | rg -q '^Contents$'; then
  echo "compiled table of contents should be omitted when TOC default is disabled" >&2
  exit 1
fi

PAPERDOWN_SETTINGS_FILE="$settings_file" \
  "$packaged_runtime/bin/paperdown" merge --mode compiled --style report \
  --cover-page --table-of-contents \
  "$tmp_dir/compiled-cover.md" "$tmp_dir/merge-b.md"

packaged_override_text="$(pdftotext "$tmp_dir/compiled-cover-compiled-1.pdf" -)"
printf '%s\n' "$packaged_override_text" | rg 'A polished packet for sharing'
printf '%s\n' "$packaged_override_text" | rg '^Contents$'
