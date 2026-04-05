#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
generated_root="$repo_root/macos/quick-actions/generated"

assert_workflow() {
  local workflow_name="$1"
  local expected_command_fragment="$2"
  local workflow_dir="$generated_root/$workflow_name.workflow"
  local info_plist="$workflow_dir/Contents/Info.plist"
  local workflow_plist="$workflow_dir/Contents/document.wflow"
  local command_string

  test -d "$workflow_dir"
  test -f "$info_plist"
  test -f "$workflow_plist"
  test "$(plutil -extract NSServices.0.NSSendFileTypes.0 raw -o - "$info_plist")" = "public.item"
  test "$(plutil -extract actions.0.action.AMAccepts.Types.0 raw -o - "$workflow_plist")" = "com.apple.cocoa.path"
  test "$(plutil -extract actions.0.action.AMProvides.Types.0 raw -o - "$workflow_plist")" = "com.apple.cocoa.path"
  test "$(plutil -extract workflowMetaData.serviceInputTypeIdentifier raw -o - "$workflow_plist")" = "com.apple.Automator.fileSystemObject"

  command_string="$(plutil -extract actions.0.action.ActionParameters.COMMAND_STRING raw -o - "$workflow_plist")"
  printf '%s\n' "$command_string" | rg -F "$expected_command_fragment"
}

assert_workflow "Convert to PDF (Report)" 'bin/paperdown-quick-action convert --style report "$@"'
assert_workflow "Convert to PDF (Memo)" 'bin/paperdown-quick-action convert --style memo "$@"'
assert_workflow "Convert to PDF (Handout)" 'bin/paperdown-quick-action convert --style handout "$@"'
assert_workflow "Merge to PDF (Packet)" 'bin/paperdown-quick-action merge --mode packet --style report "$@"'
assert_workflow "Merge to PDF (Compiled)" 'bin/paperdown-quick-action merge --mode compiled --style report "$@"'
