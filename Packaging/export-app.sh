#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
configuration="Release"
output_dir="$repo_root/dist"
create_zip=0

usage() {
  cat <<'EOF'
Usage: export-app.sh [--configuration Debug|Release] [--output-dir DIR] [--zip]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --configuration)
      shift
      if [[ $# -eq 0 ]]; then
        echo "--configuration requires a value" >&2
        exit 2
      fi
      configuration="$1"
      ;;
    --output-dir)
      shift
      if [[ $# -eq 0 ]]; then
        echo "--output-dir requires a value" >&2
        exit 2
      fi
      output_dir="$1"
      ;;
    --zip)
      create_zip=1
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

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cd "$repo_root"
xcodegen generate >/dev/null
xcodebuild build \
  -project "$repo_root/Paperdown.xcodeproj" \
  -scheme Paperdown \
  -configuration "$configuration" \
  -destination 'platform=macOS' \
  -derivedDataPath "$tmp_dir/DerivedData" >/dev/null

built_app="$tmp_dir/DerivedData/Build/Products/$configuration/Paperdown.app"
if [[ ! -d "$built_app" ]]; then
  echo "Built app bundle missing at $built_app" >&2
  exit 1
fi

mkdir -p "$output_dir"
app_bundle="$output_dir/Paperdown.app"
rm -rf "$app_bundle"
/usr/bin/ditto "$built_app" "$app_bundle"

printf 'app_bundle=%s\n' "$app_bundle"

if [[ $create_zip -eq 1 ]]; then
  zip_bundle="$output_dir/Paperdown-$configuration.zip"
  rm -f "$zip_bundle"
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "$app_bundle" "$zip_bundle"
  printf 'zip_bundle=%s\n' "$zip_bundle"
fi
