#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: bundle-typst.sh TARGET_PATH
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

target_path="$1"
source_path="${PAPERDOWN_SOURCE_TYPST_BIN:-$(command -v typst || true)}"

if [[ -z "$source_path" || ! -x "$source_path" ]]; then
  echo "Unable to locate typst for bundling" >&2
  exit 1
fi

mkdir -p "$(dirname "$target_path")"
cp "$source_path" "$target_path"
chmod +x "$target_path"
printf '%s\n' "$target_path"
