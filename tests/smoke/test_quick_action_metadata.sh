#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
info_plist="$repo_root/macos/quick-actions/Convert Markdown to PDF.workflow/Contents/Info.plist"
workflow_plist="$repo_root/macos/quick-actions/Convert Markdown to PDF.workflow/Contents/document.wflow"

test "$(plutil -extract NSServices.0.NSSendFileTypes.0 raw -o - "$info_plist")" = "public.item"
test "$(plutil -extract actions.0.action.AMAccepts.Types.0 raw -o - "$workflow_plist")" = "com.apple.cocoa.path"
test "$(plutil -extract actions.0.action.AMProvides.Types.0 raw -o - "$workflow_plist")" = "com.apple.cocoa.path"
test "$(plutil -extract workflowMetaData.serviceInputTypeIdentifier raw -o - "$workflow_plist")" = "com.apple.Automator.fileSystemObject"
