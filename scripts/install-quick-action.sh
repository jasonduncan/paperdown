#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
default_services_dir="$HOME/Library/Services"
services_dir="$default_services_dir"
generated_workflows_dir="$repo_root/macos/quick-actions/generated"
legacy_workflow_name="Convert Markdown to PDF.workflow"

usage() {
  cat <<'EOF'
Usage: install-quick-action.sh [--services-dir DIR]
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

if [[ ! -d "$generated_workflows_dir" ]]; then
  echo "Missing generated workflows directory: $generated_workflows_dir" >&2
  exit 1
fi

mkdir -p "$services_dir"
escaped_repo_root="$(printf '%s' "$repo_root" | sed 's/[\/&]/\\&/g')"

shopt -s nullglob
source_workflows=("$generated_workflows_dir"/*.workflow)
shopt -u nullglob

if [[ "${#source_workflows[@]}" -eq 0 ]]; then
  echo "No generated workflow bundles found in: $generated_workflows_dir" >&2
  exit 1
fi

rm -rf "$services_dir/$legacy_workflow_name"

for source_workflow in "${source_workflows[@]}"; do
  workflow_name="$(basename "$source_workflow")"
  target_workflow="$services_dir/$workflow_name"

  rm -rf "$target_workflow"
  cp -R "$source_workflow" "$target_workflow"
  sed -i '' "s/__PAPERDOWN_REPO_ROOT__/$escaped_repo_root/g" \
    "$target_workflow/Contents/document.wflow"

  printf 'Installed %s\n' "$target_workflow"
done

if [[ "$services_dir" == "$default_services_dir" ]]; then
  /System/Library/CoreServices/pbs -flush 2>/dev/null || true
fi
