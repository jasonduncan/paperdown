#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: verify-runtime-bundle.sh RUNTIME_ROOT
EOF
}

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 2
fi

runtime_root="$1"

required_paths=(
  "$runtime_root/bin/paperdown"
  "$runtime_root/bin/paperdown-quick-action"
  "$runtime_root/styles/report.yaml"
  "$runtime_root/styles/memo.yaml"
  "$runtime_root/styles/handout.yaml"
  "$runtime_root/templates/document.tex"
  "$runtime_root/macos/quick-actions/templates/workflow-document.wflow"
  "$runtime_root/vendor/bin/pandoc"
  "$runtime_root/vendor/bin/typst"
)

for path in "${required_paths[@]}"; do
  if [[ ! -e "$path" ]]; then
    echo "Missing required runtime path: $path" >&2
    exit 1
  fi
done

executable_paths=(
  "$runtime_root/bin/paperdown"
  "$runtime_root/bin/paperdown-quick-action"
  "$runtime_root/vendor/bin/pandoc"
  "$runtime_root/vendor/bin/typst"
)

for path in "${executable_paths[@]}"; do
  if [[ ! -x "$path" ]]; then
    echo "Expected executable path: $path" >&2
    exit 1
  fi
done

for path in "$runtime_root/vendor/bin/pandoc" "$runtime_root/vendor/bin/typst"; do
  "$path" --version >/dev/null 2>&1 || {
    echo "Bundled tool is not runnable: $path" >&2
    exit 1
  }
done

printf 'verified %s\n' "$runtime_root"
