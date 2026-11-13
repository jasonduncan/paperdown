#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
resources_root="$repo_root/PaperdownApp/Resources"
staged_runtime_root="$resources_root/paperdown-runtime"

mkdir -p "$resources_root"
"$repo_root/Packaging/build-runtime-bundle.sh" --output-dir "$resources_root" >/dev/null

if [[ -n "${TARGET_BUILD_DIR:-}" && -n "${UNLOCALIZED_RESOURCES_FOLDER_PATH:-}" ]]; then
  app_resources_root="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"
  app_runtime_root="$app_resources_root/paperdown-runtime"

  mkdir -p "$app_resources_root"
  rm -rf "$app_runtime_root"
  /usr/bin/ditto "$staged_runtime_root" "$app_runtime_root"

  if [[ -n "${SCRIPT_OUTPUT_FILE_0:-}" ]]; then
    mkdir -p "$(dirname "$SCRIPT_OUTPUT_FILE_0")"
    printf '%s\n' "$app_runtime_root" >"$SCRIPT_OUTPUT_FILE_0"
  fi
fi

printf '%s\n' "$staged_runtime_root"
