#!/usr/bin/env bash
set -euo pipefail

APP_PATH="dist/Paperdown.app"
ZIP_PATH="dist/Paperdown-notarize.zip"
STAPLE=true
DRY_RUN=false

NOTARY_KEYCHAIN_PROFILE="${NOTARY_KEYCHAIN_PROFILE:-}"
NOTARY_KEY_PATH="${NOTARY_KEY_PATH:-}"
NOTARY_KEY_ID="${NOTARY_KEY_ID:-}"
NOTARY_ISSUER="${NOTARY_ISSUER:-}"

usage() {
  cat <<USAGE
Usage: $0 [--app <path>] [--zip <path>] [--no-staple] [--dry-run]

Auth options (choose one):
  1) NOTARY_KEYCHAIN_PROFILE
  2) NOTARY_KEY_PATH + NOTARY_KEY_ID + NOTARY_ISSUER

Examples:
  NOTARY_KEYCHAIN_PROFILE=pdlabs-notary $0
  NOTARY_KEY_PATH=./AuthKey_ABC123.p8 NOTARY_KEY_ID=ABC123 NOTARY_ISSUER=<issuer-uuid> $0
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app)
      APP_PATH="$2"
      shift 2
      ;;
    --zip)
      ZIP_PATH="$2"
      shift 2
      ;;
    --no-staple)
      STAPLE=false
      shift
      ;;
    --dry-run)
      DRY_RUN=true
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

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun not found; Xcode command line tools are required." >&2
  exit 1
fi

echo "Creating notarization archive: $ZIP_PATH"
mkdir -p "$(dirname "$ZIP_PATH")"
rm -f "$ZIP_PATH"

ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ZIP_PATH"
echo "Notarization archive ready at $ZIP_PATH"

submit_args=(notarytool submit "$ZIP_PATH" --wait)

if [[ -n "$NOTARY_KEYCHAIN_PROFILE" ]]; then
  echo "Submitting with keychain profile: $NOTARY_KEYCHAIN_PROFILE"
  submit_args+=(--keychain-profile "$NOTARY_KEYCHAIN_PROFILE")
elif [[ -n "$NOTARY_KEY_PATH" && -n "$NOTARY_KEY_ID" && -n "$NOTARY_ISSUER" ]]; then
  echo "Submitting with API key from: $NOTARY_KEY_PATH"
  submit_args+=(--key "$NOTARY_KEY_PATH" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER")
else
  echo "Missing notarization credentials." >&2
  usage >&2
  exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
  printf 'Dry run: xcrun'
  printf ' %q' "${submit_args[@]}"
  printf '\n'
  exit 0
fi

xcrun "${submit_args[@]}"

if [[ "$STAPLE" == true ]]; then
  echo "Stapling notarization ticket to app bundle..."
  xcrun stapler staple "$APP_PATH"
  xcrun stapler validate "$APP_PATH"
fi

echo "Notarization workflow complete."
