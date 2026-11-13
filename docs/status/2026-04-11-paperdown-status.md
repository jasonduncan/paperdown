# paperdown Status

Date: 2026-04-11
Branch: `codex/paperdown-v1`
Project root: `/Users/jason/Development/Projects/paperdown`

## Summary

`paperdown` has progressed from a Finder Quick Action prototype into a packaged macOS app path with a bundled runtime, native SwiftUI host app, diagnostics, release helper scripts, and explicit Finder actions for conversion and merge workflows.

The core product behavior is implemented and smoke-tested. The remaining major blocker is not code: this Mac does not currently have a valid Developer ID Application signing identity or a configured `notarytool` keychain profile for live notarization.

## Finished

- Created the `paperdown` project under `/Users/jason/Development/Projects/paperdown`.
- Implemented the shell converter:
  - `convert` mode for one PDF per Markdown file.
  - `merge` mode for one PDF from multiple Markdown files.
  - `packet` and `compiled` merge behavior.
  - filename collision suffixing.
  - mixed-selection handling.
  - Finder-style stripped `PATH` handling.
- Implemented explicit Finder Quick Actions:
  - `Convert to PDF (Report)`
  - `Convert to PDF (Memo)`
  - `Convert to PDF (Handout)`
  - `Merge to PDF (Packet)`
  - `Merge to PDF (Compiled)`
- Fixed the original Finder Service issues:
  - workflow metadata now registers as file-oriented.
  - runtime no longer depends on Finder inheriting a usable `PATH`.
- Added scripted install/uninstall support for Finder Quick Actions.
- Added packaged runtime staging:
  - bundled runtime layout under `paperdown-runtime`.
  - bundled `pandoc` and `typst` support.
  - typst templates for report, memo, handout, compiled cover, and shared partials.
- Added a native macOS SwiftUI app:
  - `Paperdown.app` scaffold via XcodeGen.
  - app-managed runtime install into `~/Library/Application Support/paperdown/paperdown-runtime`.
  - app-managed Finder action install/repair.
  - settings scene for compiled cover page and table of contents defaults.
  - diagnostics surface for settings, logs, runtime, services, and latest log.
  - support report copy action.
  - detection for missing Finder actions and stale actions pointing at the wrong runtime.
- Added app export support:
  - `Packaging/export-app.sh`
  - embedded runtime under `Paperdown.app/Contents/Resources/paperdown-runtime`
  - optional zip output.
- Added release helper scripts:
  - `scripts/sign-macos-app.sh`
  - `scripts/notarize-macos-app.sh`
  - `scripts/check-release-readiness.sh`
  - `scripts/store-notary-profile.sh`
- Added native release readiness checks:
  - Developer ID Application identity detection.
  - `notarytool` keychain-profile detection.
  - release readiness in app UI and copied support reports.
- Updated project docs:
  - README
  - macOS Quick Action install guide
  - packaged app install guide
  - distribution guide
  - design specs and implementation plans.

## Last Known Verification

The following verification commands have passed during this work:

- `bash tests/smoke/test_paperdown.sh`
- `bash tests/smoke/test_quick_action_metadata.sh`
- `bash tests/smoke/test_install_quick_action.sh`
- `bash tests/smoke/test_packaged_runtime.sh`
- `bash tests/smoke/test_packaged_quick_actions.sh`
- `bash tests/smoke/test_packaged_app_bundle.sh`
- `bash tests/smoke/test_export_app.sh`
- `bash tests/smoke/test_release_distribution.sh`
- `bash tests/smoke/test_release_helpers.sh`
- `xcodegen generate`
- `xcodebuild test -project Paperdown.xcodeproj -scheme Paperdown -destination 'platform=macOS'`

The current release-readiness check reports:

```text
Paperdown release readiness
State: degraded
Notary profile: paperdown (missing)
Developer ID identities: none
Messages:
  - No Developer ID Application signing identity is installed.
  - Notary profile 'paperdown' is not configured.
```

## Update — 2026-11-13

- Fixed Finder Quick Action failures on documents with tables
  (`LaTeX Error: No counter 'none' defined`). Cause: pandoc 3.3+ emits
  `\def\LTcaptype{none}` for uncaptioned tables and the custom
  `templates/document.tex` lacked `\newcounter{none}`. It appeared after a
  newer pandoc landed in `/opt/homebrew`, not because of the macOS update.
- `bin/paperdown` now prefers `~/homebrew/bin/pandoc` (the primary Homebrew on
  this Mac) over `/opt/homebrew`, since Finder's minimal `PATH` decides which
  install is used.
- Verified with pandoc 3.2, 3.10.1, and 3.13 across report, memo, and handout
  styles; `tests/smoke/test_paperdown.sh` passes.
- Committed all previously uncommitted work (`9747e91`).
- Moved hosting from `git.pdlabs.dev` to GitHub (see Current Git State).

## Current Git State

As of 2026-11-13 the working tree is clean and everything is committed.

- Remote: `origin` → `git@github.com:jasonduncan/paperdown.git` (private).
  The old `git.pdlabs.dev` remote was removed locally; the copy on that server
  is stale and was not modified.
- Branches: `main` (default) and `codex/paperdown-v1`, which is ahead of `main`
  and still needs a PR to merge.

## Known Blockers

- No valid Developer ID Application certificate/private key is installed on this Mac.
- No `notarytool` keychain profile named `paperdown` is configured.
- Because of those missing credentials, the live Developer ID sign, notarize, staple, and final Gatekeeper validation path has not been completed.

## Risks / Gotchas

- Running packaged app export tests in parallel can race Xcode/XcodeGen outputs. Run packaging smoke tests sequentially.
- The generated `Paperdown.xcodeproj` is produced from `project.yml`; update `project.yml` first, then regenerate with `xcodegen generate`.
- Do not assume Finder has refreshed the Services cache immediately after workflow changes. The app and installer flush the Services cache, but `killall Finder` may still be useful during manual testing.
- Do not commit Apple credentials, app-specific passwords, API keys, or private signing material.
