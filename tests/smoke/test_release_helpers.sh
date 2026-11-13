#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

stub_bin="$tmp_dir/bin"
mkdir -p "$stub_bin"

cat >"$stub_bin/security" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
mode="${PAPERDOWN_SECURITY_MODE:-missing}"
case "$mode" in
  ready)
    cat <<'OUT'
  1) ABCDEF1234567890ABCDEF1234567890ABCDEF12 "Developer ID Application: PD Labs (ABC1234567)"
     1 valid identities found
OUT
    ;;
  *)
    echo "     0 valid identities found"
    ;;
esac
EOF
chmod +x "$stub_bin/security"

cat >"$stub_bin/xcrun" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "notarytool" && "${2:-}" == "history" ]]; then
  mode="${PAPERDOWN_XCRUN_HISTORY_MODE:-missing}"
  if [[ "$mode" == "ready" ]]; then
    echo "Successfully retrieved history."
    exit 0
  fi
  cat >&2 <<'ERR'
Error: No Keychain password item found for profile: paperdown

Run 'notarytool store-credentials' to create another credential profile.
ERR
  exit 1
fi

if [[ "${1:-}" == "notarytool" && "${2:-}" == "store-credentials" ]]; then
  printf '%s\n' "$*" >"${PAPERDOWN_STORE_ARGS_FILE:?}"
  exit 0
fi

echo "unexpected xcrun invocation: $*" >&2
exit 1
EOF
chmod +x "$stub_bin/xcrun"

SECURITY_BIN="$stub_bin/security" \
XCRUN_BIN="$stub_bin/xcrun" \
PAPERDOWN_SECURITY_MODE=missing \
PAPERDOWN_XCRUN_HISTORY_MODE=missing \
"$repo_root/scripts/check-release-readiness.sh" \
  --profile paperdown \
  --json >"$tmp_dir/degraded.json"

jq -e '.state == "degraded"' "$tmp_dir/degraded.json" >/dev/null
jq -e '.has_developer_id_identity == false' "$tmp_dir/degraded.json" >/dev/null
jq -e '.notary_profile_configured == false' "$tmp_dir/degraded.json" >/dev/null
jq -e '.messages | index("No Developer ID Application signing identity is installed.") != null' "$tmp_dir/degraded.json" >/dev/null

SECURITY_BIN="$stub_bin/security" \
XCRUN_BIN="$stub_bin/xcrun" \
PAPERDOWN_SECURITY_MODE=ready \
PAPERDOWN_XCRUN_HISTORY_MODE=ready \
"$repo_root/scripts/check-release-readiness.sh" \
  --profile pdlabs-notary \
  --json >"$tmp_dir/ready.json"

jq -e '.state == "ready"' "$tmp_dir/ready.json" >/dev/null
jq -e '.has_developer_id_identity == true' "$tmp_dir/ready.json" >/dev/null
jq -e '.notary_profile_name == "pdlabs-notary"' "$tmp_dir/ready.json" >/dev/null
jq -e '.developer_identities[0] == "Developer ID Application: PD Labs (ABC1234567)"' "$tmp_dir/ready.json" >/dev/null

store_args_file="$tmp_dir/store-args.txt"
PAPERDOWN_STORE_ARGS_FILE="$store_args_file" \
XCRUN_BIN="$stub_bin/xcrun" \
"$repo_root/scripts/store-notary-profile.sh" \
  --profile paperdown \
  --apple-id dev@example.com \
  --team-id TEAM1234567 \
  --password super-secret \
  --dry-run >"$tmp_dir/store.out"

rg --fixed-strings 'Dry run: xcrun notarytool store-credentials --apple-id dev@example.com --password ***REDACTED*** --team-id TEAM1234567 paperdown --validate' "$tmp_dir/store.out"
test ! -f "$store_args_file"
