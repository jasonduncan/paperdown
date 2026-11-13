#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

require_path() {
  local path="$1"
  local check="${2:-exists}"

  case "$check" in
    dir)
      if [[ ! -d "$path" ]]; then
        echo "missing directory: $path" >&2
        find "$tmp_dir/DerivedData/Build/Products" -maxdepth 4 2>/dev/null | sort >&2 || true
        exit 1
      fi
      ;;
    executable)
      if [[ ! -x "$path" ]]; then
        echo "missing executable: $path" >&2
        find "$tmp_dir/DerivedData/Build/Products" -maxdepth 5 2>/dev/null | sort >&2 || true
        exit 1
      fi
      ;;
    *)
      if [[ ! -e "$path" ]]; then
        echo "missing path: $path" >&2
        find "$tmp_dir/DerivedData/Build/Products" -maxdepth 5 2>/dev/null | sort >&2 || true
        exit 1
      fi
      ;;
  esac
}

cd "$repo_root"
xcodegen generate >/dev/null
xcodebuild build \
  -project "$repo_root/Paperdown.xcodeproj" \
  -scheme Paperdown \
  -destination 'platform=macOS' \
  -derivedDataPath "$tmp_dir/DerivedData" >/dev/null

app_bundle="$tmp_dir/DerivedData/Build/Products/Debug/Paperdown.app"
runtime_root="$app_bundle/Contents/Resources/paperdown-runtime"

require_path "$runtime_root" dir
require_path "$runtime_root/bin/paperdown" executable
require_path "$runtime_root/bin/paperdown-quick-action" executable
require_path "$runtime_root/vendor/bin/pandoc" executable
require_path "$runtime_root/vendor/bin/typst" executable
require_path "$runtime_root/macos/quick-actions/generated" dir
