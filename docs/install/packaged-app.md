# Packaged App Install Guide

## Status

`Paperdown.app` can now be exported as a self-contained macOS app bundle with
its runtime embedded under `Contents/Resources/paperdown-runtime`.

Current state:

- local app export is implemented
- first-launch install and repair is implemented
- Finder actions are installed from the packaged runtime, not from repo paths
- release helper scripts for signing and notarization are implemented
- live Developer ID signing and notarization still depend on installing real credentials

Build a local bundle from the repo:

```bash
./Packaging/export-app.sh
./Packaging/export-app.sh --zip
```

Default export output:

```text
dist/Paperdown.app
```

Release helpers:

```bash
./scripts/sign-macos-app.sh --identity -
NOTARY_KEYCHAIN_PROFILE=<profile> ./scripts/notarize-macos-app.sh --dry-run
```

Full workflow notes live in:

```text
docs/distribution.md
```

## Expected Install Flow

The primary user path is:

1. Build or obtain `Paperdown.app`.
2. Drag `Paperdown.app` into `/Applications`.
3. Launch `Paperdown.app`.
4. Click `Install or Repair`.
5. Let the app stage its runtime and install Finder actions.
6. Open Finder and use one of the explicit `paperdown` Quick Actions.

For a local unsigned build, remove quarantine if macOS blocks the launch:

```bash
xattr -dr com.apple.quarantine /Applications/Paperdown.app 2>/dev/null || true
```

## What the Export Includes

The exported bundle contains:

- the native SwiftUI host app
- the bundled `paperdown-runtime`
- vendored `pandoc` and `typst`
- generated Finder workflow bundles
- shared styles and templates

You can inspect the embedded runtime at:

```text
dist/Paperdown.app/Contents/Resources/paperdown-runtime/
```

## What First Launch Does

The app-owned install path does two things:

1. stages the packaged runtime into:

```text
~/Library/Application Support/paperdown/paperdown-runtime/
```

2. installs the Finder actions into:

```text
~/Library/Services/
```

The installed action set remains:

- `Convert to PDF (Report)`
- `Convert to PDF (Memo)`
- `Convert to PDF (Handout)`
- `Merge to PDF (Packet)`
- `Merge to PDF (Compiled)`

## Settings

The app and runtime share one settings file:

```text
~/Library/Application Support/paperdown/settings.json
```

Current global defaults:

- compiled cover page on/off
- compiled table of contents on/off

The native app exposes these settings through its macOS Settings scene.

The app now also exposes diagnostics details directly in the UI:

- app version/build
- settings file path
- logs folder path
- latest conversion log path when one exists
- support folder path
- installed runtime path
- services folder path
- bundled runtime path when running from an exported app
- missing Finder actions vs actions needing repair
- one-click support report copy for troubleshooting
- release-readiness checks for:
  - installed Developer ID Application identities
  - `notarytool` keychain-profile availability

The current default profile name is:

```text
paperdown
```

You can override that check for local development by launching the app with:

```bash
PAPERDOWN_NOTARY_PROFILE=<profile> /Applications/Paperdown.app/Contents/MacOS/Paperdown
```

Repo-side helper scripts now exist for the same workflow:

```bash
./scripts/check-release-readiness.sh --profile paperdown
./scripts/store-notary-profile.sh --profile paperdown --apple-id <apple-id> --team-id <team-id>
```

## Repair and Reinstall

If Finder actions disappear or behave unexpectedly:

1. Launch `Paperdown.app`.
2. Click `Install or Repair`.
3. Review the install-status details in the main window or Settings if the app reports specific actions as missing or stale.
4. Use `Copy Support Report` if you need to capture the current runtime/action state for debugging.
5. Restart Finder if macOS is still holding onto a stale Services cache.

Finder restart command:

```bash
killall Finder 2>/dev/null || true
```

The app should be treated as the primary repair path. Repo scripts remain
useful for development and smoke tests.

## Logs and Support Files

Runtime logs:

```text
~/Library/Logs/paperdown/
```

App support root:

```text
~/Library/Application Support/paperdown/
```

Finder Services root:

```text
~/Library/Services/
```

## Development-State Equivalent

If you want to stay entirely inside the repo:

1. Export the app with `./Packaging/export-app.sh --configuration Debug`.
2. Launch `dist/Paperdown.app` or the copied `/Applications/Paperdown.app`.
3. Use the main window’s `Install or Repair` button.
4. Use the app’s Settings scene to change compiled defaults.
5. Validate the runtime with the existing smoke suite.

## Verification

Current verification commands:

```bash
xcodegen generate
xcodebuild test -project Paperdown.xcodeproj -scheme Paperdown -destination 'platform=macOS'
bash tests/smoke/test_paperdown.sh
bash tests/smoke/test_packaged_runtime.sh
bash tests/smoke/test_packaged_quick_actions.sh
bash tests/smoke/test_packaged_app_bundle.sh
bash tests/smoke/test_export_app.sh
```
