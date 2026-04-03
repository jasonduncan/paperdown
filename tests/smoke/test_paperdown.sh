#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cp "$repo_root/tests/fixtures/basic.md" "$tmp_dir/basic.md"
"$repo_root/bin/paperdown" "$tmp_dir/basic.md"
test -f "$tmp_dir/basic.pdf"
