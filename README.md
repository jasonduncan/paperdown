# paperdown

Convert Markdown files into polished, document-style PDFs from the macOS
Finder.

## Status

Implemented:

- shell converter with explicit `convert` and `merge` modes
- document-style PDF rendering via `pandoc` + `xelatex`
- Finder Quick Actions for three styles and two merge modes
- scripted Quick Action install and uninstall helpers
- packaged runtime staging with bundled `pandoc` and `typst`
- native macOS app scaffold with install health checks
- app-side runtime extraction and Finder action repair services
- native app settings scene backed by a shared `settings.json`
- runtime defaults for compiled cover-page and table-of-contents behavior
- self-contained `Paperdown.app` export with embedded runtime assets
- release scripts for ad-hoc signing and notarization submission/dry-run
- native diagnostics surface showing installed-runtime/settings/log paths, broken Finder action detection, and copyable support reports
- native release-readiness checks for Developer ID identities and `notarytool` keychain-profile availability

In progress:

- signed/notarized packaged app distribution
- broader app polish beyond the current install, settings, and diagnostics baseline

## Goal

`paperdown` will let a user select one or more `.md` files in Finder, run a
right-click action, and receive readable PDF documents beside the source files.
The output is intended for non-technical readers rather than for people who are
comfortable reading Markdown directly.

## Stack

- macOS Quick Action (Automator)
- Shell-based local converter
- `pandoc`
- `xelatex`
- `typst`
- SwiftUI macOS app host

## Styles and Merge Modes

Available styles:

- `report`
- `memo`
- `handout`

Available merge modes:

- `packet`
- `compiled`

Finder exposes:

- `Convert to PDF (Report)`
- `Convert to PDF (Memo)`
- `Convert to PDF (Handout)`
- `Merge to PDF (Packet)`
- `Merge to PDF (Compiled)`

## Build

Build a self-contained app bundle:

```bash
./Packaging/export-app.sh
./Packaging/export-app.sh --configuration Debug --zip
```

The default export target is:

```text
dist/Paperdown.app
```

The exported bundle embeds `paperdown-runtime` under `Contents/Resources/`, so
the app no longer depends on a repo checkout to install or repair its Finder
actions.

Release workflow helpers:

```bash
./scripts/check-release-readiness.sh --profile paperdown
./scripts/sign-macos-app.sh --identity -
./scripts/store-notary-profile.sh --profile paperdown --apple-id <apple-id> --team-id <team-id>
NOTARY_KEYCHAIN_PROFILE=<profile> ./scripts/notarize-macos-app.sh --dry-run
```

Implementation details and the planned file structure live in:

- `docs/specs/2026-04-03-markdown-finder-pdf-tool-design.md`
- `docs/specs/2026-04-05-paperdown-style-actions-and-merge-design.md`
- `docs/superpowers/plans/2026-04-03-paperdown-v1.md`
- `docs/superpowers/plans/2026-04-05-paperdown-style-actions-and-merge.md`

## Test

Run the shell smoke test:

```bash
bash tests/smoke/test_paperdown.sh
bash tests/smoke/test_quick_action_metadata.sh
bash tests/smoke/test_install_quick_action.sh
bash tests/smoke/test_packaged_runtime.sh
bash tests/smoke/test_packaged_quick_actions.sh
bash tests/smoke/test_packaged_app_bundle.sh
bash tests/smoke/test_export_app.sh
bash tests/smoke/test_release_distribution.sh
bash tests/smoke/test_release_helpers.sh
xcodebuild test -project Paperdown.xcodeproj -scheme Paperdown -destination 'platform=macOS'
```

Current smoke coverage:

- single-file conversion
- multi-file conversion
- filename collision handling
- mixed-selection skipping
- style selection
- packet merge output
- compiled merge output
- compiled title derivation
- merged output collision handling
- stripped-down Finder-style environment handling
- packaged runtime execution with vendored tool resolution
- packaged-runtime settings consumption with CLI override flags
- Quick Action Finder-service metadata validation
- Quick Action install and uninstall across the full action set
- packaged-runtime Quick Action install, repair, and uninstall
- embedded packaged runtime inside the built app bundle
- export script generation of a distributable `Paperdown.app` plus optional zip
- release-script coverage for ad-hoc signing and notarization dry-run archive generation
- headless Automator execution through installed convert and merge workflows

## Run

Direct converter:

```bash
./bin/paperdown convert --style report path/to/file.md
./bin/paperdown convert --style memo path/to/one.md path/to/two.md
./bin/paperdown merge --mode packet --style report path/to/one.md path/to/two.md
./bin/paperdown merge --mode compiled --style report path/to/one.md path/to/two.md
```

Quick Action wrapper:

```bash
./bin/paperdown-quick-action convert --style report path/to/file.md
./bin/paperdown-quick-action merge --mode compiled --style report path/to/one.md path/to/two.md
```

Global settings file:

```text
~/Library/Application Support/paperdown/settings.json
```

Optional override for scripted runs:

```bash
PAPERDOWN_SETTINGS_FILE=/path/to/settings.json ./bin/paperdown merge --mode compiled --style report path/to/one.md path/to/two.md
```

Finder Quick Action install:

```bash
./scripts/install-quick-action.sh
./scripts/install-quick-action.sh --runtime-root "$HOME/Library/Application Support/paperdown/paperdown-runtime"
```

Finder Quick Action uninstall:

```bash
./scripts/uninstall-quick-action.sh
./scripts/uninstall-quick-action.sh --runtime-root "$HOME/Library/Application Support/paperdown/paperdown-runtime"
```

The installed Finder action invokes the default `report` style, while shell use
can select any supported style and merge mode directly.

See:

- `docs/install/macos-quick-action.md`
- `docs/install/packaged-app.md`
- `docs/distribution.md`
