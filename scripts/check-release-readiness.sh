#!/usr/bin/env bash
set -euo pipefail

profile="${PAPERDOWN_NOTARY_PROFILE:-${NOTARY_KEYCHAIN_PROFILE:-paperdown}}"
json_output=false

SECURITY_BIN="${SECURITY_BIN:-/usr/bin/security}"
XCRUN_BIN="${XCRUN_BIN:-/usr/bin/xcrun}"

usage() {
  cat <<'USAGE'
Usage: check-release-readiness.sh [--profile <name>] [--json]

Checks whether this Mac is ready for Paperdown release signing/notarization by:
- listing Developer ID Application identities
- checking notarytool keychain-profile availability
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      profile="$2"
      shift 2
      ;;
    --json)
      json_output=true
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

security_output="$("$SECURITY_BIN" find-identity -v -p codesigning 2>&1 || true)"
set +e
xcrun_output="$("$XCRUN_BIN" notarytool history --keychain-profile "$profile" 2>&1)"
xcrun_status=$?
set -e

developer_identities="$(printf '%s\n' "$security_output" | sed -n 's/.*"\(Developer ID Application:.*\)".*/\1/p')"

developer_id_array=()
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  developer_id_array+=("$line")
done <<EOF
$developer_identities
EOF

has_identity=false
if [[ ${#developer_id_array[@]} -gt 0 ]]; then
  has_identity=true
fi

notary_profile_configured=false
if [[ $xcrun_status -eq 0 ]]; then
  notary_profile_configured=true
fi

messages=()
if [[ "$has_identity" != true ]]; then
  messages+=("No Developer ID Application signing identity is installed.")
fi

if [[ "$notary_profile_configured" != true ]]; then
  if printf '%s' "$xcrun_output" | grep -q "No Keychain password item found for profile"; then
    messages+=("Notary profile '$profile' is not configured.")
  else
    trimmed_output="$(printf '%s' "$xcrun_output" | tr '\n' ' ' | sed 's/[[:space:]]\+/ /g; s/^ //; s/ $//')"
    if [[ -n "$trimmed_output" ]]; then
      messages+=("Notary profile '$profile' could not be validated: $trimmed_output")
    else
      messages+=("Notary profile '$profile' could not be validated.")
    fi
  fi
fi

state="ready"
if [[ ${#messages[@]} -gt 0 ]]; then
  state="degraded"
fi

if [[ "$json_output" == true ]]; then
  developer_json="$(printf '%s\n' "${developer_id_array[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')"
  messages_json="$(printf '%s\n' "${messages[@]:-}" | jq -R . | jq -s 'map(select(length > 0))')"
  jq -n \
    --arg state "$state" \
    --arg profile "$profile" \
    --argjson hasIdentity "$has_identity" \
    --argjson notaryConfigured "$notary_profile_configured" \
    --argjson developerIdentities "$developer_json" \
    --argjson messages "$messages_json" \
    '{
      state: $state,
      developer_identities: $developerIdentities,
      has_developer_id_identity: $hasIdentity,
      notary_profile_name: $profile,
      notary_profile_configured: $notaryConfigured,
      messages: $messages
    }'
  exit 0
fi

echo "Paperdown release readiness"
echo "State: $state"
echo "Notary profile: $profile ($([[ "$notary_profile_configured" == true ]] && echo configured || echo missing))"
if [[ "$has_identity" == true ]]; then
  echo "Developer ID identities:"
  printf '  - %s\n' "${developer_id_array[@]}"
else
  echo "Developer ID identities: none"
fi
if [[ ${#messages[@]} -gt 0 ]]; then
  echo "Messages:"
  printf '  - %s\n' "${messages[@]}"
fi
