#!/usr/bin/env bash
set -euo pipefail

default_services_dir="$HOME/Library/Services"
services_dir="$default_services_dir"
workflow_name="Convert Markdown to PDF.workflow"

usage() {
  cat <<'EOF'
Usage: uninstall-quick-action.sh [--services-dir DIR]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --services-dir)
      shift
      if [[ $# -eq 0 ]]; then
        echo "--services-dir requires a value" >&2
        exit 2
      fi
      services_dir="$1"
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

rm -rf "$services_dir/$workflow_name"

if [[ "$services_dir" == "$default_services_dir" ]]; then
  /System/Library/CoreServices/pbs -flush 2>/dev/null || true
fi

printf 'Removed %s/%s\n' "$services_dir" "$workflow_name"
