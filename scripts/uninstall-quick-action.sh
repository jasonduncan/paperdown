#!/usr/bin/env bash
set -euo pipefail

default_services_dir="$HOME/Library/Services"
services_dir="$default_services_dir"
repo_root="$(cd "$(dirname "$0")/.." && pwd)"
runtime_root=""
legacy_workflow_name="Convert Markdown to PDF.workflow"
workflow_names=(
  "Convert to PDF (Report).workflow"
  "Convert to PDF (Memo).workflow"
  "Convert to PDF (Handout).workflow"
  "Merge to PDF (Packet).workflow"
  "Merge to PDF (Compiled).workflow"
)

usage() {
  cat <<'EOF'
Usage: uninstall-quick-action.sh [--services-dir DIR] [--runtime-root DIR]
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
    --runtime-root)
      shift
      if [[ $# -eq 0 ]]; then
        echo "--runtime-root requires a value" >&2
        exit 2
      fi
      runtime_root="$1"
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

generated_workflows_dir="$repo_root/macos/quick-actions/generated"
if [[ -n "$runtime_root" ]]; then
  generated_workflows_dir="$runtime_root/macos/quick-actions/generated"
fi

if [[ -d "$generated_workflows_dir" ]]; then
  shopt -s nullglob
  source_workflows=("$generated_workflows_dir"/*.workflow)
  shopt -u nullglob

  for source_workflow in "${source_workflows[@]}"; do
    workflow_name="$(basename "$source_workflow")"
    rm -rf "$services_dir/$workflow_name"
    printf 'Removed %s/%s\n' "$services_dir" "$workflow_name"
  done
else
  for workflow_name in "${workflow_names[@]}"; do
    rm -rf "$services_dir/$workflow_name"
    printf 'Removed %s/%s\n' "$services_dir" "$workflow_name"
  done
fi

rm -rf "$services_dir/$legacy_workflow_name"

if [[ "$services_dir" == "$default_services_dir" ]]; then
  /System/Library/CoreServices/pbs -flush 2>/dev/null || true
fi
