# paperdown Packaged Quality Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn `paperdown` into a packaged macOS product with a bundled rendering runtime, a native host app, stronger compiled-document polish, and lightweight global settings.

**Architecture:** Keep the existing shell converter as the document orchestration core, but introduce a packaged runtime layout that can be embedded inside a native SwiftUI app and installed into `~/Library/Application Support/paperdown`. Migrate rendering from the current repo-local `xelatex` path toward a bundled `pandoc + typst` stack, preserve explicit Finder actions, and let the app own install/update, diagnostics, and global defaults while the runtime owns conversion behavior.

**Tech Stack:** SwiftUI/AppKit bridge, Bash, pandoc, typst, Automator Quick Actions, macOS application packaging, shell smoke tests, XCTest

---

## Spec Reference

- `docs/specs/2026-04-05-paperdown-packaged-quality-design.md`

## Planned File Structure

- `.gitignore`
  - Ignore packaged build artifacts and the transient `.superpowers/` brainstorm directory.
- `README.md`
  - Update product description from repo-local utility to packaged app plus explicit Finder actions.
- `docs/install/macos-quick-action.md`
  - Replace repo-script-centric install guidance with packaged app setup and repair guidance.
- `docs/install/packaged-app.md`
  - New operator/user doc for drag-to-Applications install, first launch, runtime repair, and troubleshooting.
- `docs/superpowers/specs/2026-04-05-paperdown-packaged-quality-design.md`
  - Canonical approved design reference for this transition.
- `Paperdown.xcodeproj/project.pbxproj`
  - Native macOS app project definition.
- `PaperdownApp/App/PaperdownApp.swift`
  - App entry point and scene wiring.
- `PaperdownApp/App/MainView.swift`
  - Main status screen showing runtime health, Finder action health, and repair/install actions.
- `PaperdownApp/App/Settings/SettingsView.swift`
  - Global settings UI for compiled cover page, TOC, default convert style visibility, and diagnostics links.
- `PaperdownApp/App/Models/AppSettings.swift`
  - Codable settings model stored in `UserDefaults` or app support JSON.
- `PaperdownApp/App/Models/InstallStatus.swift`
  - Shared status model for runtime and Quick Action installation health.
- `PaperdownApp/App/Services/RuntimeInstaller.swift`
  - Extracts/stages the packaged runtime into `~/Library/Application Support/paperdown`.
- `PaperdownApp/App/Services/QuickActionInstaller.swift`
  - Installs and repairs Finder Quick Actions against the packaged runtime path.
- `PaperdownApp/App/Services/HealthCheckService.swift`
  - Checks app support runtime presence, bundled tools, and installed workflow integrity.
- `PaperdownApp/App/Services/DiagnosticsService.swift`
  - Opens logs/support folders and surfaces version/build/runtime metadata.
- `PaperdownApp/Resources/QuickActions/...`
  - Bundled workflow templates or prebuilt workflow bundles shipped inside the app.
- `Packaging/build-runtime-bundle.sh`
  - Stages the CLI, templates, workflows, and bundled tool binaries into a distributable runtime layout.
- `Packaging/verify-runtime-bundle.sh`
  - Verifies the staged runtime contains the expected binaries, templates, workflows, and executable permissions.
- `Packaging/bundle-pandoc.sh`
  - Vendor/stage the `pandoc` binary used by packaged builds.
- `Packaging/bundle-typst.sh`
  - Vendor/stage the `typst` binary used by packaged builds.
- `bin/paperdown`
  - Add packaged-runtime awareness, typst rendering path, global settings ingestion, and improved compiled-document rendering.
- `bin/paperdown-quick-action`
  - Resolve the packaged runtime location, load settings defaults, and preserve macOS-friendly batch summaries.
- `styles/report.yaml`
  - Trim to shared metadata/config inputs or migrate content into shared style tokens as needed during the typst transition.
- `styles/memo.yaml`
  - Same as above, but memo-specific overrides.
- `styles/handout.yaml`
  - Same as above, but accessibility-first overrides.
- `templates/typst/paperdown.typ`
  - Shared typst foundation for margins, typography, heading rhythm, tables, code blocks, running footer/header logic.
- `templates/typst/report.typ`
  - Report style overrides.
- `templates/typst/memo.typ`
  - Memo style overrides.
- `templates/typst/handout.typ`
  - Handout style overrides.
- `templates/typst/compiled-cover.typ`
  - Cover page and compiled frontmatter treatment.
- `templates/typst/partials/`
  - Shared partials for TOC, section openers, metadata blocks, and reusable components.
- `scripts/install-quick-action.sh`
  - Rework into a packaged-runtime-aware installer used by the app and still callable in development.
- `scripts/uninstall-quick-action.sh`
  - Rework to uninstall packaged-runtime workflows cleanly.
- `tests/fixtures/compiled-cover.md`
  - Fixture focused on compiled cover-page defaults and TOC behavior.
- `tests/fixtures/accessibility-handout.md`
  - Fixture focused on handout density/heading behavior.
- `tests/smoke/test_paperdown.sh`
  - Expand for typst path, compiled cover page, TOC defaults, and packaged-runtime invocation support.
- `tests/smoke/test_packaged_runtime.sh`
  - New verification for staged runtime contents and execution without repo-relative assumptions.
- `tests/smoke/test_packaged_quick_actions.sh`
  - New end-to-end test that installs workflows against a fake app-support runtime and exercises them with `automator`.
- `PaperdownAppTests/HealthCheckServiceTests.swift`
  - Unit tests for app-side install health and missing-runtime detection.
- `PaperdownAppTests/QuickActionInstallerTests.swift`
  - Unit tests for workflow install/update path rewriting.

## Chunk 1: Runtime Packaging Foundation

### Task 1: Define and verify a packaged runtime layout

**Files:**
- Modify: `.gitignore`
- Create: `Packaging/build-runtime-bundle.sh`
- Create: `Packaging/verify-runtime-bundle.sh`
- Create: `tests/smoke/test_packaged_runtime.sh`
- Modify: `README.md`

- [ ] **Step 1: Add the failing packaged-runtime smoke test**

Create `tests/smoke/test_packaged_runtime.sh` with assertions for:

- staged runtime directory exists under a temp output root
- bundled `pandoc` and `typst` binaries are present and executable
- `bin/paperdown` can run from the staged runtime without a repo-relative path
- workflow assets and style/template assets are copied into the runtime

- [ ] **Step 2: Run the new smoke test to verify it fails**

Run: `bash tests/smoke/test_packaged_runtime.sh`
Expected: FAIL because no runtime bundling scripts or staged layout exist yet

- [ ] **Step 3: Add packaging scripts and ignore rules**

Implement:

- `.superpowers/` ignore in `.gitignore`
- `Packaging/build-runtime-bundle.sh` that stages:
  - runtime `bin/`
  - workflow assets
  - style/template assets
  - placeholder vendored tool locations
- `Packaging/verify-runtime-bundle.sh` that validates required files and executable permissions

- [ ] **Step 4: Update README packaging/status language**

Add a short “packaged app transition” section describing the new staged runtime and how it fits the upcoming app host.

- [ ] **Step 5: Run the packaged-runtime smoke test again**

Run: `bash tests/smoke/test_packaged_runtime.sh`
Expected: PASS for staged layout checks, but rendering still uses placeholder tool hooks

- [ ] **Step 6: Commit**

```bash
git add .gitignore README.md Packaging/build-runtime-bundle.sh Packaging/verify-runtime-bundle.sh tests/smoke/test_packaged_runtime.sh
git commit -m "build: add packaged runtime bundle scaffolding"
```

## Chunk 2: Bundled Renderer Transition

### Task 2: Add bundled `pandoc + typst` support to the converter

**Files:**
- Create: `Packaging/bundle-pandoc.sh`
- Create: `Packaging/bundle-typst.sh`
- Modify: `bin/paperdown`
- Modify: `tests/smoke/test_paperdown.sh`
- Modify: `tests/smoke/test_packaged_runtime.sh`

- [ ] **Step 1: Extend the converter smoke test with failing typst-path expectations**

Add assertions for:

- packaged runtime prefers bundled `pandoc` and `typst`
- converter still works when repo-local PATH is stripped down
- converter emits a clear failure if bundled typst is missing

- [ ] **Step 2: Run targeted smoke tests to verify failure**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: FAIL because `bin/paperdown` does not yet resolve typst or packaged tool locations

Run: `bash tests/smoke/test_packaged_runtime.sh`
Expected: FAIL because bundled tool scripts are placeholders

- [ ] **Step 3: Implement bundled tool staging scripts**

Add:

- `Packaging/bundle-pandoc.sh` to copy or vendor a portable `pandoc` binary into the staged runtime
- `Packaging/bundle-typst.sh` to copy or vendor a portable `typst` binary into the staged runtime
- verification hooks in `Packaging/build-runtime-bundle.sh`

- [ ] **Step 4: Refactor `bin/paperdown` for packaged renderer discovery**

Implement:

- ordered tool resolution: packaged runtime first, dev overrides second, PATH last
- `typst` PDF rendering path for packaged builds
- compatibility path so development can still use existing assets while the transition is in progress
- clear log messages naming the renderer path actually used

- [ ] **Step 5: Re-run smoke tests**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: PASS for convert/merge behavior through the new renderer resolution path

Run: `bash tests/smoke/test_packaged_runtime.sh`
Expected: PASS for staged tool verification and runtime execution

- [ ] **Step 6: Commit**

```bash
git add Packaging/bundle-pandoc.sh Packaging/bundle-typst.sh Packaging/build-runtime-bundle.sh bin/paperdown tests/smoke/test_paperdown.sh tests/smoke/test_packaged_runtime.sh
git commit -m "feat: add bundled typst runtime support"
```

## Chunk 3: Shared Typst Document System

### Task 3: Build the shared style foundation and stronger compiled defaults

**Files:**
- Create: `templates/typst/paperdown.typ`
- Create: `templates/typst/report.typ`
- Create: `templates/typst/memo.typ`
- Create: `templates/typst/handout.typ`
- Create: `templates/typst/compiled-cover.typ`
- Create: `templates/typst/partials/metadata.typ`
- Create: `templates/typst/partials/toc.typ`
- Create: `templates/typst/partials/section-openers.typ`
- Create: `tests/fixtures/compiled-cover.md`
- Create: `tests/fixtures/accessibility-handout.md`
- Modify: `bin/paperdown`
- Modify: `tests/smoke/test_paperdown.sh`
- Modify: `styles/report.yaml`
- Modify: `styles/memo.yaml`
- Modify: `styles/handout.yaml`

- [ ] **Step 1: Add failing tests for document-quality defaults**

Extend `tests/smoke/test_paperdown.sh` to check:

- compiled output includes cover-page metadata defaults
- compiled mode still enables TOC by default
- handout style produces a distinct PDF subject/metadata path
- report, memo, and handout resolve through one shared renderer foundation

- [ ] **Step 2: Run the smoke test to confirm the new quality assertions fail**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: FAIL because cover-page and shared typst templates do not exist yet

- [ ] **Step 3: Write the shared typst foundation**

Implement:

- base page geometry and type scale
- heading rhythm and spacing
- list, table, quote, and code block styling
- running footer/header behavior
- style hooks that let `report`, `memo`, and `handout` override only what differs

- [ ] **Step 4: Add compiled cover-page and section-opener treatment**

Implement:

- default cover page for `compiled`
- TOC block wired through typst
- section opener presentation using first-file metadata and ordered source sections

- [ ] **Step 5: Update shell style configs to feed the typst templates**

Keep the style files focused on style identity and metadata rather than long LaTeX inline blocks.

- [ ] **Step 6: Re-run the converter smoke test**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: PASS, including compiled cover-page/TOC defaults and distinct style rendering

- [ ] **Step 7: Commit**

```bash
git add templates/typst tests/fixtures/compiled-cover.md tests/fixtures/accessibility-handout.md bin/paperdown styles/report.yaml styles/memo.yaml styles/handout.yaml tests/smoke/test_paperdown.sh
git commit -m "feat: add shared typst document system"
```

## Chunk 4: Native App Scaffold and Health Surface

### Task 4: Create the macOS host app with runtime and workflow health checks

**Files:**
- Create: `Paperdown.xcodeproj/project.pbxproj`
- Create: `PaperdownApp/App/PaperdownApp.swift`
- Create: `PaperdownApp/App/MainView.swift`
- Create: `PaperdownApp/App/Models/InstallStatus.swift`
- Create: `PaperdownApp/App/Services/HealthCheckService.swift`
- Create: `PaperdownAppTests/HealthCheckServiceTests.swift`

- [ ] **Step 1: Add failing XCTest coverage for install health**

Write tests that verify:

- missing app-support runtime reports degraded status
- missing Finder workflows report degraded status
- healthy runtime plus workflow set reports ready state

- [ ] **Step 2: Run the new tests to verify they fail**

Run: `xcodebuild test -project Paperdown.xcodeproj -scheme Paperdown -destination 'platform=macOS'`
Expected: FAIL because the app project and health service do not exist yet

- [ ] **Step 3: Create the minimal native app**

Implement:

- SwiftUI app entry point
- main status window
- install health model
- health-check service that inspects app support runtime and installed workflows

- [ ] **Step 4: Re-run the app tests**

Run: `xcodebuild test -project Paperdown.xcodeproj -scheme Paperdown -destination 'platform=macOS'`
Expected: PASS for health status tests

- [ ] **Step 5: Commit**

```bash
git add Paperdown.xcodeproj PaperdownApp PaperdownAppTests
git commit -m "feat: add paperdown mac app scaffold"
```

## Chunk 5: App-Owned Runtime and Quick Action Installation

### Task 5: Let the app install and repair the packaged runtime plus Finder actions

**Files:**
- Create: `PaperdownApp/App/Services/RuntimeInstaller.swift`
- Create: `PaperdownApp/App/Services/QuickActionInstaller.swift`
- Create: `PaperdownApp/App/Services/DiagnosticsService.swift`
- Create: `PaperdownAppTests/QuickActionInstallerTests.swift`
- Modify: `PaperdownApp/App/MainView.swift`
- Modify: `scripts/install-quick-action.sh`
- Modify: `scripts/uninstall-quick-action.sh`
- Modify: `tests/smoke/test_packaged_quick_actions.sh`

- [ ] **Step 1: Add failing tests for runtime extraction and workflow rewriting**

Write:

- XCTest cases for runtime path selection and workflow placeholder rewriting
- shell smoke coverage in `tests/smoke/test_packaged_quick_actions.sh` that simulates a staged app-support runtime and installs workflows against it

- [ ] **Step 2: Run the tests to confirm failure**

Run: `xcodebuild test -project Paperdown.xcodeproj -scheme Paperdown -destination 'platform=macOS'`
Expected: FAIL because installer services are missing

Run: `bash tests/smoke/test_packaged_quick_actions.sh`
Expected: FAIL because scripts still assume repo-local runtime paths

- [ ] **Step 3: Implement app-owned installers**

Add:

- runtime extraction into `~/Library/Application Support/paperdown`
- workflow installation/repair using packaged runtime paths
- main-window controls for install/update/repair
- diagnostics hooks for log and support folder access

- [ ] **Step 4: Rework shell installer scripts for packaged-runtime awareness**

Make the scripts callable both:

- from development repo context
- from app-owned runtime context

- [ ] **Step 5: Re-run tests**

Run: `xcodebuild test -project Paperdown.xcodeproj -scheme Paperdown -destination 'platform=macOS'`
Expected: PASS

Run: `bash tests/smoke/test_packaged_quick_actions.sh`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add PaperdownApp/App/Services PaperdownAppTests/QuickActionInstallerTests.swift scripts/install-quick-action.sh scripts/uninstall-quick-action.sh tests/smoke/test_packaged_quick_actions.sh PaperdownApp/App/MainView.swift
git commit -m "feat: add app-managed runtime and actions"
```

## Chunk 6: Global Settings Surface

### Task 6: Add app settings for compiled defaults and diagnostics

**Files:**
- Create: `PaperdownApp/App/Models/AppSettings.swift`
- Create: `PaperdownApp/App/Settings/SettingsView.swift`
- Modify: `PaperdownApp/App/PaperdownApp.swift`
- Modify: `PaperdownApp/App/MainView.swift`
- Modify: `bin/paperdown`
- Modify: `bin/paperdown-quick-action`
- Modify: `PaperdownAppTests/HealthCheckServiceTests.swift`

- [ ] **Step 1: Add failing tests for settings persistence and runtime consumption**

Cover:

- app settings persist and reload
- compiled cover-page default can be toggled
- compiled TOC default can be toggled
- runtime picks up stored global defaults when invoked through the packaged path

- [ ] **Step 2: Run tests to verify failure**

Run: `xcodebuild test -project Paperdown.xcodeproj -scheme Paperdown -destination 'platform=macOS'`
Expected: FAIL because settings model and UI do not exist

Run: `bash tests/smoke/test_paperdown.sh`
Expected: FAIL once settings-aware assertions are added

- [ ] **Step 3: Implement settings storage and UI**

Add:

- `AppSettings` model
- SwiftUI Settings scene
- toggles for compiled cover page and TOC defaults
- diagnostics links for logs and support folders

- [ ] **Step 4: Wire settings into the runtime**

Make `bin/paperdown` and `bin/paperdown-quick-action` load global defaults from the packaged config location when invoked without overriding flags.

- [ ] **Step 5: Re-run tests**

Run: `xcodebuild test -project Paperdown.xcodeproj -scheme Paperdown -destination 'platform=macOS'`
Expected: PASS

Run: `bash tests/smoke/test_paperdown.sh`
Expected: PASS, including settings-driven compiled defaults

- [ ] **Step 6: Commit**

```bash
git add PaperdownApp/App/Models/AppSettings.swift PaperdownApp/App/Settings/SettingsView.swift PaperdownApp/App/PaperdownApp.swift PaperdownApp/App/MainView.swift bin/paperdown bin/paperdown-quick-action PaperdownAppTests/HealthCheckServiceTests.swift tests/smoke/test_paperdown.sh
git commit -m "feat: add paperdown global settings"
```

## Chunk 7: Packaging Docs and Release Verification

### Task 7: Document and verify the packaged product flow

**Files:**
- Create: `docs/install/packaged-app.md`
- Modify: `docs/install/macos-quick-action.md`
- Modify: `README.md`
- Modify: `tests/smoke/test_packaged_runtime.sh`
- Modify: `tests/smoke/test_packaged_quick_actions.sh`

- [ ] **Step 1: Add failing release-verification expectations where needed**

Ensure smoke coverage explicitly checks:

- runtime works without repo-relative paths
- workflows install from packaged layout
- repair path succeeds after deleting an installed workflow

- [ ] **Step 2: Write packaged-product documentation**

Document:

- drag-to-Applications install
- first-launch setup
- runtime repair
- Finder action repair/update
- where logs and app-support files live

- [ ] **Step 3: Update legacy Quick Action docs**

Make `docs/install/macos-quick-action.md` point users to the packaged app as the primary path while retaining development instructions for repo-based testing.

- [ ] **Step 4: Run the full verification set**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: PASS

Run: `bash tests/smoke/test_packaged_runtime.sh`
Expected: PASS

Run: `bash tests/smoke/test_packaged_quick_actions.sh`
Expected: PASS

Run: `xcodebuild test -project Paperdown.xcodeproj -scheme Paperdown -destination 'platform=macOS'`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add README.md docs/install/packaged-app.md docs/install/macos-quick-action.md tests/smoke/test_packaged_runtime.sh tests/smoke/test_packaged_quick_actions.sh
git commit -m "docs: add packaged app guidance"
```
