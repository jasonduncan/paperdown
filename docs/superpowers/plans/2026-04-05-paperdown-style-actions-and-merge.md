# paperdown Style Actions and Merge Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend `paperdown` so Finder exposes multiple style actions and two merged-output actions backed by one deterministic CLI.

**Architecture:** Keep Finder workflows thin and add explicit `convert` and `merge` subcommands to `bin/paperdown`. Introduce reusable workflow templates plus an installer that materializes all Finder actions, and keep merge behavior deterministic by assembling temporary Markdown in argument order before passing it into the existing Pandoc/XeLaTeX renderer.

**Tech Stack:** Bash, pandoc, xelatex, Automator Quick Actions, macOS shell tooling

---

## Spec Reference

- `docs/specs/2026-04-05-paperdown-style-actions-and-merge-design.md`

## Planned File Structure

- `bin/paperdown`
  - Expand into an explicit CLI with `convert` and `merge` subcommands, style and mode flags, shared output naming helpers, deterministic command resolution, and merge assembly support.
- `bin/paperdown-quick-action`
  - Update to pass through fixed subcommand arguments cleanly and preserve error summaries for the new action set.
- `scripts/install-quick-action.sh`
  - Expand from a single workflow installer into a multi-workflow installer that installs every defined Finder action and rewrites placeholders in each bundle.
- `scripts/uninstall-quick-action.sh`
  - Remove every installed `paperdown` workflow bundle rather than a single action.
- `macos/quick-actions/templates/workflow-document.wflow`
  - New reusable workflow document template with placeholder command arguments for generated Finder actions.
- `macos/quick-actions/actions/*.json`
  - New action manifests describing bundle name, Finder menu title, and fixed CLI arguments for each installed workflow.
- `macos/quick-actions/generated/<Workflow Name>.workflow/Contents/Info.plist`
  - Versioned per-action Finder service bundle metadata.
- `macos/quick-actions/generated/<Workflow Name>.workflow/Contents/document.wflow`
  - Versioned per-action workflow documents generated from the shared template shape.
- `tests/fixtures/merge-a.md`
  - First merge fixture with frontmatter title/author/date for compiled baseline behavior.
- `tests/fixtures/merge-b.md`
  - Second merge fixture with conflicting frontmatter to verify suppression and deterministic assembly.
- `tests/smoke/test_paperdown.sh`
  - Expand to cover style selection, packet merge, compiled merge, output naming, and service-like environment handling.
- `tests/smoke/test_quick_action_metadata.sh`
  - Expand to validate every workflow bundle and its fixed action arguments.
- `tests/smoke/test_install_quick_action.sh`
  - Expand to install all workflows into a temp Services dir and exercise representative actions through `automator`.
- `docs/install/macos-quick-action.md`
  - Update installation and Finder usage docs for the multi-action surface.
- `README.md`
  - Update status, run examples, and action inventory.

## Chunk 1: Merge Fixtures and CLI Test Red

### Task 1: Add merge fixtures and extend the smoke test with failing merge expectations

**Files:**
- Create: `tests/fixtures/merge-a.md`
- Create: `tests/fixtures/merge-b.md`
- Modify: `tests/smoke/test_paperdown.sh`

- [ ] **Step 1: Write the merge fixtures**

```markdown
---
title: Project Notes
author: PD Labs
date: 2026-04-05
---

# Alpha Section

This is the first merged document.
```

```markdown
---
title: Conflicting Title
author: Someone Else
date: 2020-01-01
---

# Beta Section

This is the second merged document.
```

- [ ] **Step 2: Extend the smoke test with failing merge coverage**

Add assertions for:

- `paperdown convert --style memo ...` produces a PDF
- `paperdown merge --mode packet --style report merge-a.md merge-b.md` produces `merge-a-packet.pdf`
- `paperdown merge --mode compiled --style report merge-a.md merge-b.md` produces `merge-a-compiled.pdf`
- collision-safe merged naming produces `merge-a-compiled-1.pdf` on a second compiled run

- [ ] **Step 3: Run the smoke test to verify it fails for the missing subcommands**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: FAIL because `bin/paperdown` does not yet understand `convert` and `merge`

- [ ] **Step 4: Commit**

```bash
git add tests/fixtures/merge-a.md tests/fixtures/merge-b.md tests/smoke/test_paperdown.sh
git commit -m "test: add merge smoke coverage"
```

## Chunk 2: Converter CLI Split

### Task 2: Add explicit `convert` subcommand support and preserve current behavior

**Files:**
- Modify: `bin/paperdown`
- Modify: `tests/smoke/test_paperdown.sh`

- [ ] **Step 1: Run the failing convert-style test in isolation**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: FAIL because `paperdown convert --style memo ...` is not implemented

- [ ] **Step 2: Refactor the CLI into explicit subcommands**

Implement:

- `paperdown convert [--style STYLE] file1.md file2.md`
- keep `convert` behavior aligned with the current default conversion path
- preserve service-environment binary resolution for `pandoc` and `xelatex`
- preserve skip/fail summary behavior

- [ ] **Step 3: Keep backward compatibility temporarily**

If invoked without a subcommand, route the old argument shape through `convert`
so the existing Quick Action remains functional during the transition.

- [ ] **Step 4: Run the smoke test to verify convert paths pass and merge still fails**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: convert assertions PASS, merge assertions still FAIL

- [ ] **Step 5: Commit**

```bash
git add bin/paperdown tests/smoke/test_paperdown.sh
git commit -m "feat: add paperdown convert subcommand"
```

## Chunk 3: Merge Engine

### Task 3: Implement packet and compiled merge modes

**Files:**
- Modify: `bin/paperdown`
- Modify: `tests/smoke/test_paperdown.sh`

- [ ] **Step 1: Add failing assertions for compiled title derivation**

Extend the smoke test to verify:

- `pdfinfo merge-a-compiled.pdf` reports a title derived from `merge-a.md`
- packet and compiled outputs are both created beside the first selected file

- [ ] **Step 2: Run the smoke test to verify merge still fails correctly**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: FAIL because `merge` behavior is still missing

- [ ] **Step 3: Implement merge assembly helpers**

Add helpers for:

- filtering Markdown inputs while preserving argument order
- deriving merged basenames from the first selected file
- collision-safe merged output paths for `packet` and `compiled`
- creating a temporary merged Markdown source

Packet assembly requirements:

- concatenate documents in order
- insert page breaks between files
- keep rendering literal and predictable

Compiled assembly requirements:

- derive title from the first selected file’s frontmatter `title`, else basename
- carry first-file metadata baseline
- suppress later-file document-level metadata
- insert top-level section boundaries in argument order
- enable TOC by default

- [ ] **Step 4: Run the smoke test to verify merge passes**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: PASS for convert, packet merge, compiled merge, and collision handling

- [ ] **Step 5: Commit**

```bash
git add bin/paperdown tests/smoke/test_paperdown.sh
git commit -m "feat: add paperdown merge modes"
```

## Chunk 4: Multi-Workflow Finder Surface

### Task 4: Introduce reusable workflow definitions for all Finder actions

**Files:**
- Create: `macos/quick-actions/templates/workflow-document.wflow`
- Create: `macos/quick-actions/actions/convert-report.json`
- Create: `macos/quick-actions/actions/convert-memo.json`
- Create: `macos/quick-actions/actions/convert-handout.json`
- Create: `macos/quick-actions/actions/merge-packet.json`
- Create: `macos/quick-actions/actions/merge-compiled.json`
- Create: `macos/quick-actions/generated/Convert to PDF (Report).workflow/Contents/Info.plist`
- Create: `macos/quick-actions/generated/Convert to PDF (Report).workflow/Contents/document.wflow`
- Create: `macos/quick-actions/generated/Convert to PDF (Memo).workflow/Contents/Info.plist`
- Create: `macos/quick-actions/generated/Convert to PDF (Memo).workflow/Contents/document.wflow`
- Create: `macos/quick-actions/generated/Convert to PDF (Handout).workflow/Contents/Info.plist`
- Create: `macos/quick-actions/generated/Convert to PDF (Handout).workflow/Contents/document.wflow`
- Create: `macos/quick-actions/generated/Merge to PDF (Packet).workflow/Contents/Info.plist`
- Create: `macos/quick-actions/generated/Merge to PDF (Packet).workflow/Contents/document.wflow`
- Create: `macos/quick-actions/generated/Merge to PDF (Compiled).workflow/Contents/Info.plist`
- Create: `macos/quick-actions/generated/Merge to PDF (Compiled).workflow/Contents/document.wflow`
- Modify: `tests/smoke/test_quick_action_metadata.sh`

- [ ] **Step 1: Add failing workflow metadata coverage**

Expand `tests/smoke/test_quick_action_metadata.sh` to verify:

- all five workflow bundles exist
- each workflow is registered as a file-based Finder Service
- each workflow passes the expected fixed CLI arguments in `document.wflow`

- [ ] **Step 2: Run the metadata test to verify it fails**

Run: `bash tests/smoke/test_quick_action_metadata.sh`
Expected: FAIL because the multi-action workflows do not exist yet

- [ ] **Step 3: Create reusable workflow definitions**

Implementation requirements:

- one shared workflow document template with placeholders for repo root and fixed arguments
- per-action manifests describing bundle name and arguments
- generated versioned bundles for the five approved Finder actions
- all workflow bundles use file-based Service metadata

- [ ] **Step 4: Run the metadata test to verify it passes**

Run: `bash tests/smoke/test_quick_action_metadata.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add macos/quick-actions tests/smoke/test_quick_action_metadata.sh
git commit -m "feat: add multi-action quick workflows"
```

## Chunk 5: Installer and End-to-End Workflow Execution

### Task 5: Install and exercise the full workflow set

**Files:**
- Modify: `scripts/install-quick-action.sh`
- Modify: `scripts/uninstall-quick-action.sh`
- Modify: `tests/smoke/test_install_quick_action.sh`

- [ ] **Step 1: Write the failing installer smoke test for all workflows**

Expand the test to:

- install all workflows into a temp Services directory
- assert all five workflow bundles exist
- invoke one style conversion workflow through `automator`
- invoke one merge workflow through `automator`
- verify expected PDFs are created

- [ ] **Step 2: Run the installer smoke test to verify it fails**

Run: `bash tests/smoke/test_install_quick_action.sh`
Expected: FAIL because the installer only handles one workflow

- [ ] **Step 3: Update installer and uninstaller scripts**

Implementation requirements:

- install every workflow bundle from `macos/quick-actions/generated/`
- rewrite repo-root placeholders in every installed `document.wflow`
- remove every installed `paperdown` workflow during uninstall
- preserve optional `--services-dir` for temp test installs

- [ ] **Step 4: Run the installer smoke test to verify it passes**

Run: `bash tests/smoke/test_install_quick_action.sh`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add scripts/install-quick-action.sh scripts/uninstall-quick-action.sh tests/smoke/test_install_quick_action.sh
git commit -m "feat: install paperdown action set"
```

## Chunk 6: Docs and Final Verification

### Task 6: Update user-facing docs and verify the live installed action set

**Files:**
- Modify: `README.md`
- Modify: `docs/install/macos-quick-action.md`

- [ ] **Step 1: Update the README**

Document:

- the five Finder actions
- new CLI examples for `convert` and `merge`
- merged output naming and placement
- test commands for converter, metadata, and installer coverage

- [ ] **Step 2: Update the install guide**

Document:

- that installer now installs all workflows
- how `packet` and `compiled` differ
- where merged output is written
- how to refresh Finder if Services cache lags

- [ ] **Step 3: Run the full verification set**

Run:

```bash
bash tests/smoke/test_paperdown.sh
bash tests/smoke/test_quick_action_metadata.sh
bash tests/smoke/test_install_quick_action.sh
tmpdir=$(mktemp -d)
cp tests/fixtures/basic.md "$tmpdir/basic.md"
cp tests/fixtures/merge-a.md "$tmpdir/merge-a.md"
cp tests/fixtures/merge-b.md "$tmpdir/merge-b.md"
automator -i "$tmpdir/basic.md" "$HOME/Library/Services/Convert to PDF (Report).workflow"
automator -i "$tmpdir/merge-a.md" "$tmpdir/merge-b.md" "$HOME/Library/Services/Merge to PDF (Compiled).workflow"
ls "$tmpdir"
rm -rf "$tmpdir"
```

Expected:

- all smoke tests PASS
- convert workflow creates one PDF
- compiled merge workflow creates one merged PDF beside `merge-a.md`

- [ ] **Step 4: Commit**

```bash
git add README.md docs/install/macos-quick-action.md
git commit -m "docs: add style and merge workflow docs"
```
