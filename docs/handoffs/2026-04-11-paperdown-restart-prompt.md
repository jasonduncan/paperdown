# paperdown Restart Prompt

Use this prompt to restart the work in a fresh Codex session:

```text
Continue the paperdown project at /Users/jason/Development/Projects/paperdown.

First read:
- /Users/jason/Development/Projects/paperdown/docs/status/2026-04-11-paperdown-status.md
- /Users/jason/Development/Projects/paperdown/docs/superpowers/plans/2026-04-11-paperdown-next-steps.md
- /Users/jason/Development/Projects/paperdown/docs/distribution.md
- /Users/jason/Development/Projects/paperdown/README.md

Important context:
- The current branch is codex/paperdown-v1.
- Jason previously said to ignore git for the moment, so do not commit, merge, push, or discard changes without asking.
- The working tree has a large uncommitted feature set: packaged runtime, typst templates, SwiftUI app, diagnostics, release readiness, and release helper scripts.
- project.yml is the source for the generated Xcode project; run xcodegen generate after project structure changes.
- Packaging smoke tests should be run sequentially because parallel export/build tests can race Xcode/XcodeGen output.
- Current real blocker: no Developer ID Application identity and no notarytool keychain profile named paperdown are installed on this Mac.

Your first commands should be:
- pwd
- git -C /Users/jason/Development/Projects/paperdown status --short --branch
- git -C /Users/jason/Development/Projects/paperdown diff --stat
- /Users/jason/Development/Projects/paperdown/scripts/check-release-readiness.sh --profile paperdown

Then proceed with the next-step plan:
1. Re-run the verification suite sequentially.
2. If verification is green, ask Jason how he wants to handle the dirty git state.
3. If Jason provides Apple credentials/certs, store the notary profile, verify release readiness, run live Developer ID signing, notarization, stapling, and Gatekeeper validation.
4. Do not add new product features until the release path is settled.

Verification commands to use:
- bash tests/smoke/test_paperdown.sh
- bash tests/smoke/test_quick_action_metadata.sh
- bash tests/smoke/test_install_quick_action.sh
- bash tests/smoke/test_packaged_runtime.sh
- bash tests/smoke/test_packaged_quick_actions.sh
- bash tests/smoke/test_packaged_app_bundle.sh
- bash tests/smoke/test_export_app.sh
- bash tests/smoke/test_release_distribution.sh
- bash tests/smoke/test_release_helpers.sh
- xcodegen generate
- xcodebuild test -project Paperdown.xcodeproj -scheme Paperdown -destination 'platform=macOS'
```
