#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

runtime_root="$tmp_dir/runtime"
log_dir="$tmp_dir/logs"

"$repo_root/Packaging/build-runtime-bundle.sh" --output-dir "$runtime_root"

staged_runtime="$runtime_root/paperdown-runtime"
test -d "$staged_runtime"
test -x "$staged_runtime/bin/paperdown"
test -x "$staged_runtime/vendor/bin/pandoc"
test -x "$staged_runtime/vendor/bin/typst"
test -f "$staged_runtime/styles/report.yaml"
test -f "$staged_runtime/templates/document.tex"
test -f "$staged_runtime/macos/quick-actions/templates/workflow-document.wflow"

"$repo_root/Packaging/verify-runtime-bundle.sh" "$staged_runtime"
"$staged_runtime/bin/paperdown" --help | rg '^Usage:$'
cp "$repo_root/tests/fixtures/basic.md" "$tmp_dir/basic.md"
cp "$repo_root/tests/fixtures/compiled-cover.md" "$tmp_dir/compiled-cover.md"
cp "$repo_root/tests/fixtures/merge-b.md" "$tmp_dir/merge-b.md"

packaged_output="$(env -i HOME="$HOME" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  PAPERDOWN_LOG_DIR="$log_dir" \
  "$staged_runtime/bin/paperdown" convert --style report "$tmp_dir/basic.md")"
printf '%s\n' "$packaged_output" | rg '^converted 1, failed 0, skipped 0$'
test -f "$tmp_dir/basic.pdf"
latest_log="$(ls -1t "$log_dir"/paperdown-*.log | head -1)"
rg "^pandoc_bin=${staged_runtime}/vendor/bin/pandoc$" "$latest_log"
rg "^pdf_engine_bin=${staged_runtime}/vendor/bin/typst$" "$latest_log"

compiled_output="$(env -i HOME="$HOME" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  PAPERDOWN_LOG_DIR="$log_dir" \
  "$staged_runtime/bin/paperdown" merge --mode compiled --style report \
  "$tmp_dir/compiled-cover.md" "$tmp_dir/merge-b.md")"
printf '%s\n' "$compiled_output" | rg '^converted 1, failed 0, skipped 0$'
test -f "$tmp_dir/compiled-cover-compiled.pdf"
/Users/jason/homebrew/bin/pdftotext "$tmp_dir/compiled-cover-compiled.pdf" - | \
  rg 'A polished packet for sharing'

rm "$staged_runtime/vendor/bin/typst"
if env -i HOME="$HOME" PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  PAPERDOWN_LOG_DIR="$log_dir" \
  "$staged_runtime/bin/paperdown" convert --style report "$tmp_dir/basic.md" \
  >"$tmp_dir/missing-typst.out" 2>"$tmp_dir/missing-typst.err"; then
  echo "expected packaged runtime convert to fail without typst" >&2
  exit 1
fi

rg '^Missing typst executable in packaged runtime$' "$tmp_dir/missing-typst.err"
