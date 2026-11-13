#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
output_dir=""
runtime_name="paperdown-runtime"

usage() {
  cat <<'EOF'
Usage: build-runtime-bundle.sh --output-dir DIR
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      shift
      if [[ $# -eq 0 ]]; then
        echo "--output-dir requires a value" >&2
        exit 2
      fi
      output_dir="$1"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if [[ -z "$output_dir" ]]; then
  usage >&2
  exit 2
fi

runtime_root="$output_dir/$runtime_name"
rm -rf "$runtime_root"

mkdir -p \
  "$runtime_root/bin" \
  "$runtime_root/styles" \
  "$runtime_root/templates" \
  "$runtime_root/macos/quick-actions" \
  "$runtime_root/vendor/bin"

cp "$repo_root/bin/paperdown" "$runtime_root/bin/paperdown"
cp "$repo_root/bin/paperdown-quick-action" "$runtime_root/bin/paperdown-quick-action"
cp -R "$repo_root/styles/." "$runtime_root/styles/"
cp -R "$repo_root/templates/." "$runtime_root/templates/"
cp -R "$repo_root/macos/quick-actions/." "$runtime_root/macos/quick-actions/"

"$repo_root/Packaging/bundle-pandoc.sh" "$runtime_root/vendor/bin/pandoc" >/dev/null
"$repo_root/Packaging/bundle-typst.sh" "$runtime_root/vendor/bin/typst" >/dev/null

chmod +x \
  "$runtime_root/bin/paperdown" \
  "$runtime_root/bin/paperdown-quick-action"

printf '%s\n' "$runtime_root"
