#!/usr/bin/env bash
set -euo pipefail

profile=""
apple_id=""
password=""
team_id=""
key_path=""
key_id=""
issuer=""
keychain=""
validate=true
sync=false
dry_run=false

XCRUN_BIN="${XCRUN_BIN:-/usr/bin/xcrun}"

usage() {
  cat <<'USAGE'
Usage: store-notary-profile.sh --profile <name> [auth options] [--dry-run]

Auth options (choose one):
  Apple ID flow:
    --apple-id <email> --team-id <team-id> [--password <app-specific-password>]

  App Store Connect API key flow:
    --key <path> --key-id <id> [--issuer <issuer-uuid>]

Other options:
  --keychain <path>   Store credentials in a specific keychain
  --sync              Sync the credential item with iCloud Keychain
  --no-validate       Skip notarytool credential validation before saving
  --dry-run           Print the command that would run, with secrets redacted
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      profile="$2"
      shift 2
      ;;
    --apple-id)
      apple_id="$2"
      shift 2
      ;;
    --password)
      password="$2"
      shift 2
      ;;
    --team-id)
      team_id="$2"
      shift 2
      ;;
    --key)
      key_path="$2"
      shift 2
      ;;
    --key-id)
      key_id="$2"
      shift 2
      ;;
    --issuer)
      issuer="$2"
      shift 2
      ;;
    --keychain)
      keychain="$2"
      shift 2
      ;;
    --sync)
      sync=true
      shift
      ;;
    --no-validate)
      validate=false
      shift
      ;;
    --dry-run)
      dry_run=true
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

if [[ -z "$profile" ]]; then
  echo "--profile is required." >&2
  usage >&2
  exit 1
fi

use_apple_id=false
use_api_key=false

if [[ -n "$apple_id" || -n "$team_id" || -n "$password" ]]; then
  use_apple_id=true
fi
if [[ -n "$key_path" || -n "$key_id" || -n "$issuer" ]]; then
  use_api_key=true
fi

if [[ "$use_apple_id" == true && "$use_api_key" == true ]]; then
  echo "Choose either Apple ID auth or API key auth, not both." >&2
  exit 1
fi

if [[ "$use_apple_id" == false && "$use_api_key" == false ]]; then
  echo "You must provide either Apple ID credentials or API key credentials." >&2
  exit 1
fi

args=(notarytool store-credentials)

if [[ "$use_apple_id" == true ]]; then
  if [[ -z "$apple_id" || -z "$team_id" ]]; then
    echo "Apple ID flow requires --apple-id and --team-id." >&2
    exit 1
  fi
  args+=(--apple-id "$apple_id")
  if [[ -n "$password" ]]; then
    args+=(--password "$password")
  fi
  args+=(--team-id "$team_id")
fi

if [[ "$use_api_key" == true ]]; then
  if [[ -z "$key_path" || -z "$key_id" ]]; then
    echo "API key flow requires --key and --key-id." >&2
    exit 1
  fi
  args+=(--key "$key_path" --key-id "$key_id")
  if [[ -n "$issuer" ]]; then
    args+=(--issuer "$issuer")
  fi
fi

args+=("$profile")

if [[ "$sync" == true ]]; then
  args+=(--sync)
fi
if [[ "$validate" == true ]]; then
  args+=(--validate)
else
  args+=(--no-validate)
fi
if [[ -n "$keychain" ]]; then
  args+=(--keychain "$keychain")
fi

if [[ "$dry_run" == true ]]; then
  redacted=()
  redact_next=false
  for arg in "${args[@]}"; do
    if [[ "$redact_next" == true ]]; then
      redacted+=("***REDACTED***")
      redact_next=false
      continue
    fi

    redacted+=("$arg")
    if [[ "$arg" == "--password" ]]; then
      redact_next=true
    fi
  done

  printf 'Dry run: xcrun'
  printf ' %s' "${redacted[@]}"
  printf '\n'
  exit 0
fi

"$XCRUN_BIN" "${args[@]}"
