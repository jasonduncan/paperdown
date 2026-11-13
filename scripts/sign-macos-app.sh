#!/usr/bin/env bash
set -euo pipefail

APP_PATH="dist/Paperdown.app"
IDENTITY="${CODESIGN_IDENTITY:--}"
ENTITLEMENTS=""
DEEP=true

usage() {
  cat <<USAGE
Usage: $0 [--app <path>] [--identity <codesign-identity>] [--entitlements <plist>] [--no-deep]

Environment:
  CODESIGN_IDENTITY   Signing identity override.
                      Use '-' for ad-hoc signing (default).
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      APP_PATH="$2"
      shift 2
      ;;
    --identity)
      IDENTITY="$2"
      shift 2
      ;;
    --entitlements)
      ENTITLEMENTS="$2"
      shift 2
      ;;
    --no-deep)
      DEEP=false
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 1
fi

echo "Signing app bundle: $APP_PATH"
echo "Identity: $IDENTITY"

args=(--force --sign "$IDENTITY")

if [[ "$DEEP" == true ]]; then
  args+=(--deep)
fi

if [[ "$IDENTITY" != "-" ]]; then
  args+=(--options runtime --timestamp)
fi

if [[ -n "$ENTITLEMENTS" ]]; then
  args+=(--entitlements "$ENTITLEMENTS")
fi

codesign "${args[@]}" "$APP_PATH"

echo "Verifying codesign..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "Running Gatekeeper assess (informational)..."
spctl --assess --type execute --verbose=2 "$APP_PATH" || true

echo "Signing complete."
