# paperdown Next Steps Plan

Date: 2026-04-11
Status: Draft handoff plan

## Objective

Move `paperdown` from a completed local packaged-app implementation to a clean, resumable, release-ready state.

The highest-value next work is not adding more conversion features. The next work is stabilizing the branch, validating the full test suite, installing real Apple distribution credentials, and completing the live release path.

## Phase 1: Stabilize the Working Tree

- [ ] Re-read the current status document:
  - `/Users/jason/Development/Projects/paperdown/docs/status/2026-04-11-paperdown-status.md`
- [ ] Review the dirty tree before editing:
  - `git -C /Users/jason/Development/Projects/paperdown status --short --branch`
  - `git -C /Users/jason/Development/Projects/paperdown diff --stat`
- [ ] Review the generated project policy:
  - `project.yml` is the source for `Paperdown.xcodeproj`.
  - Regenerate with `xcodegen generate` after project structure changes.
- [ ] Run the core verification suite sequentially:
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
- [ ] If tests fail, fix only the failing behavior; do not start new product work.

## Phase 2: Decide Git Integration

- [ ] Confirm with Jason whether to commit locally, push, or keep the branch dirty.
- [ ] If committing, split changes into sensible commits:
  - converter and Finder action improvements
  - packaged runtime and typst templates
  - SwiftUI app scaffold and installers
  - diagnostics/settings/release readiness
  - release helper scripts and docs
- [ ] Do not rewrite or discard unrelated user changes.

## Phase 3: Install Apple Release Credentials

- [ ] Install or import a valid Developer ID Application certificate and private key.
- [ ] Verify signing identity:

```bash
security find-identity -v -p codesigning
```

- [ ] Store the notary profile. Apple ID flow:

```bash
./scripts/store-notary-profile.sh \
  --profile paperdown \
  --apple-id <apple-id> \
  --team-id <team-id> \
  --password <app-specific-password>
```

- [ ] Or store the notary profile with an App Store Connect API key:

```bash
./scripts/store-notary-profile.sh \
  --profile paperdown \
  --key /path/AuthKey_XXX.p8 \
  --key-id XXX \
  --issuer <issuer-uuid>
```

- [ ] Re-check release readiness:

```bash
./scripts/check-release-readiness.sh --profile paperdown
./scripts/check-release-readiness.sh --profile paperdown --json
```

Expected state after credentials are installed:

```text
State: ready
```

## Phase 4: Run Live Release Path

- [ ] Export the app:

```bash
./Packaging/export-app.sh --configuration Release --zip
```

- [ ] Developer ID sign:

```bash
./scripts/sign-macos-app.sh \
  --app dist/Paperdown.app \
  --identity "Developer ID Application: <Team Name> (<TEAMID>)"
```

- [ ] Submit notarization:

```bash
NOTARY_KEYCHAIN_PROFILE=paperdown \
./scripts/notarize-macos-app.sh \
  --app dist/Paperdown.app \
  --zip dist/Paperdown-notarize.zip
```

- [ ] Validate stapled bundle:

```bash
xcrun stapler validate dist/Paperdown.app
spctl --assess --type execute --verbose=2 dist/Paperdown.app
codesign --verify --deep --strict --verbose=2 dist/Paperdown.app
```

- [ ] If validation succeeds, create the final distributable zip from the stapled app.

## Phase 5: Manual Product Verification

- [ ] Launch the exported app.
- [ ] Click `Install or Repair`.
- [ ] Confirm app status says runtime and Finder actions are installed.
- [ ] Confirm release readiness reflects the installed credentials.
- [ ] In Finder, run:
  - `Convert to PDF (Report)`
  - `Convert to PDF (Memo)`
  - `Convert to PDF (Handout)`
  - `Merge to PDF (Packet)`
  - `Merge to PDF (Compiled)`
- [ ] Verify PDFs are written next to the source Markdown files.
- [ ] Verify collisions still use suffixes.

## Phase 6: Optional Polish After Release Path

Only do these after the release path is working:

- [ ] Add a first-launch welcome/onboarding panel.
- [ ] Improve app visual polish.
- [ ] Add a one-click “Open Exported App Folder” action.
- [ ] Add a small sample Markdown document for users to test.
- [ ] Add CI or a local `make verify` wrapper for the smoke suite.

## Definition of Done

- All smoke tests and XCTest suite pass.
- Branch state is intentionally handled: committed, PR’d, or explicitly left dirty by Jason’s choice.
- `./scripts/check-release-readiness.sh --profile paperdown` reports ready on the release machine.
- `dist/Paperdown.app` is Developer ID signed, notarized, stapled, and Gatekeeper-valid.
- Finder actions work from the packaged app install path.
