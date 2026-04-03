# paperdown V1 Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS Finder Quick Action that converts one or more Markdown files into polished PDF documents using a fixed `report` style.

**Architecture:** Keep the Finder integration thin and put the real behavior in a local converter script. Store document templates and style presets as repo assets, cover the converter with shell smoke tests, and keep the Quick Action installable from versioned files in the repo.

**Tech Stack:** Bash, pandoc, xelatex, Automator Quick Actions, macOS shell tooling

---

## Spec Reference

- `docs/specs/2026-04-03-markdown-finder-pdf-tool-design.md`

## Planned File Structure

- `bin/paperdown`
  - Main converter entrypoint. Parses inputs, filters non-Markdown files,
    resolves style, handles collision-safe output names, runs `pandoc`, and
    emits a summary.
- `templates/document.tex`
  - Shared LaTeX template for page layout, metadata presentation, typography,
    and reusable document styling.
- `styles/report.yaml`
  - Default document preset used by the Finder Quick Action in v1.
- `styles/memo.yaml`
  - Future preset asset so style expansion does not require structural changes.
- `styles/handout.yaml`
  - Future preset asset for concise handout formatting.
- `tests/fixtures/basic.md`
  - Simple document fixture for smoke conversion.
- `tests/fixtures/rich-content.md`
  - Representative fixture for headings, tables, lists, code blocks, blockquotes,
    and images.
- `tests/smoke/test_paperdown.sh`
  - Shell smoke test runner for converter behavior.
- `macos/quick-actions/Convert Markdown to PDF.workflow/Contents/document.wflow`
  - Versioned Quick Action bundle that invokes `bin/paperdown --style report`.
- `docs/install/macos-quick-action.md`
  - Install, reinstall, and troubleshooting instructions for the Finder action.

## Chunk 1: Converter Foundation

### Task 1: Create the smoke test harness

**Files:**
- Create: `tests/fixtures/basic.md`
- Create: `tests/fixtures/rich-content.md`
- Create: `tests/smoke/test_paperdown.sh`

- [ ] **Step 1: Write the fixture Markdown files**

```markdown
---
title: Basic Fixture
author: PD Labs
date: 2026-04-03
---

# Hello

This is a smoke test fixture.
```

```markdown
---
title: Rich Fixture
subtitle: Formatting coverage
author: PD Labs
date: 2026-04-03
---

# Heading One

> A blockquote

## Table

| Name | Value |
| ---- | ----- |
| One  | 1     |

## Code

```text
example
```
```

- [ ] **Step 2: Write the failing smoke test script**

```bash
#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

cp "$repo_root/tests/fixtures/basic.md" "$tmp_dir/basic.md"
"$repo_root/bin/paperdown" "$tmp_dir/basic.md"
test -f "$tmp_dir/basic.pdf"
```

- [ ] **Step 3: Run the smoke test to verify it fails**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: FAIL because `bin/paperdown` does not exist yet

- [ ] **Step 4: Commit**

```bash
git add tests/fixtures/basic.md tests/fixtures/rich-content.md tests/smoke/test_paperdown.sh
git commit -m "test: add paperdown smoke fixtures"
```

### Task 2: Implement the converter entrypoint

**Files:**
- Create: `bin/paperdown`
- Modify: `tests/smoke/test_paperdown.sh`

- [ ] **Step 1: Write the failing collision and mixed-selection checks**

Add assertions for:

- skipped non-Markdown files do not fail the batch
- `basic.pdf` collision produces `basic-1.pdf`

- [ ] **Step 2: Run the smoke test to verify it fails for missing behavior**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: FAIL with missing command or missing PDF outputs

- [ ] **Step 3: Write the minimal converter implementation**

```bash
#!/usr/bin/env bash
set -euo pipefail

style="report"
log_dir="${HOME}/Library/Logs/paperdown"
mkdir -p "$log_dir"

next_output_path() {
  local source_path="$1"
  local base="${source_path%.md}"
  local candidate="${base}.pdf"
  local n=1
  while [[ -e "$candidate" ]]; do
    candidate="${base}-${n}.pdf"
    n=$((n + 1))
  done
  printf '%s\n' "$candidate"
}
```

Implementation requirements:

- default style is `report`
- skip non-`.md` inputs and count them
- continue after per-file failures
- print a final summary line
- write stderr from failed `pandoc` runs to the log directory

- [ ] **Step 4: Run the smoke test to verify it passes for batch basics**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: PASS with generated PDFs in the temporary directory

- [ ] **Step 5: Commit**

```bash
git add bin/paperdown tests/smoke/test_paperdown.sh
git commit -m "feat: add paperdown converter entrypoint"
```

## Chunk 2: Document Rendering Assets

### Task 3: Add the shared template and report preset

**Files:**
- Create: `templates/document.tex`
- Create: `styles/report.yaml`
- Modify: `bin/paperdown`
- Modify: `tests/smoke/test_paperdown.sh`

- [ ] **Step 1: Write a failing rich-content assertion**

Extend the smoke test to convert `tests/fixtures/rich-content.md` and verify the
PDF is created successfully.

- [ ] **Step 2: Run the smoke test to verify it fails without the rendering assets**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: FAIL because the converter does not yet pass a template/style bundle

- [ ] **Step 3: Write the base template and report style**

Template requirements:

- page margins and geometry suitable for a printable document
- title, subtitle, author, and date handling
- readable heading spacing
- pleasant code block, table, and blockquote treatment

Preset requirements:

- bind the template
- set fonts and spacing defaults for the `report` style
- keep configuration readable and data-driven

- [ ] **Step 4: Update the converter to pass the template and report style into `pandoc`**

Run command shape:

```bash
pandoc "$input" \
  --from markdown \
  --pdf-engine=xelatex \
  --template "$repo_root/templates/document.tex" \
  --metadata-file "$repo_root/styles/report.yaml" \
  -o "$output"
```

- [ ] **Step 5: Run the smoke test to verify it passes**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: PASS for both the basic and rich fixtures

- [ ] **Step 6: Commit**

```bash
git add templates/document.tex styles/report.yaml bin/paperdown tests/smoke/test_paperdown.sh
git commit -m "feat: add report PDF rendering assets"
```

### Task 4: Add future-ready style presets without changing the v1 UX

**Files:**
- Create: `styles/memo.yaml`
- Create: `styles/handout.yaml`
- Modify: `README.md`

- [ ] **Step 1: Write the preset files**

Include minimal but valid alternate metadata presets so the repo has the
intended future expansion points checked in from day one.

- [ ] **Step 2: Document that v1 Finder integration still uses only `report`**

Update the README to clarify:

- `report` is the only installed Finder action in v1
- `memo` and `handout` are reserved for later menu expansion

- [ ] **Step 3: Verify the converter still defaults to `report`**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: PASS with no behavior change

- [ ] **Step 4: Commit**

```bash
git add styles/memo.yaml styles/handout.yaml README.md
git commit -m "docs: reserve additional style presets"
```

## Chunk 3: Finder Integration and Installation

### Task 5: Add the Quick Action bundle

**Files:**
- Create: `macos/quick-actions/Convert Markdown to PDF.workflow/Contents/document.wflow`
- Modify: `bin/paperdown`

- [ ] **Step 1: Write a shell wrapper that the Quick Action can call**

Ensure the converter can be invoked from Finder with absolute paths and without
depending on an interactive shell profile.

- [ ] **Step 2: Create the workflow bundle**

Workflow behavior:

- receives files from Finder
- invokes the repo converter with `--style report`
- shows a completion summary

- [ ] **Step 3: Manually install the workflow into `~/Library/Services/`**

Run:

```bash
mkdir -p ~/Library/Services
cp -R "macos/quick-actions/Convert Markdown to PDF.workflow" ~/Library/Services/
```

Expected: Finder shows `Convert Markdown to PDF` in the Quick Actions menu for
selected Markdown files

- [ ] **Step 4: Manually verify the Finder flow**

Verification checklist:

- select one Markdown file and generate a PDF
- select multiple Markdown files and generate multiple PDFs
- confirm collision-safe suffix generation
- confirm mixed selections skip non-Markdown files

- [ ] **Step 5: Commit**

```bash
git add macos/quick-actions/Convert\ Markdown\ to\ PDF.workflow/Contents/document.wflow bin/paperdown
git commit -m "feat: add macOS quick action"
```

### Task 6: Document installation and troubleshooting

**Files:**
- Create: `docs/install/macos-quick-action.md`
- Modify: `README.md`

- [ ] **Step 1: Write the install guide**

Cover:

- local prerequisites (`pandoc`, `xelatex`)
- where the workflow bundle lives in the repo
- how to copy it into `~/Library/Services/`
- how to refresh Finder if the action does not appear
- where the log files are written

- [ ] **Step 2: Update the README with build, test, and run instructions**

README must include:

- how to run smoke tests
- how to install the Quick Action
- how to invoke the converter directly from the shell

- [ ] **Step 3: Run the smoke tests and a final manual Finder check**

Run: `bash tests/smoke/test_paperdown.sh`
Expected: PASS

Manual expected result: the Finder action creates polished PDFs beside the
selected Markdown files and preserves existing PDFs by suffixing new filenames

- [ ] **Step 4: Commit**

```bash
git add docs/install/macos-quick-action.md README.md
git commit -m "docs: add quick action install guide"
```

## Final Verification

- [ ] Run: `bash tests/smoke/test_paperdown.sh`
Expected: PASS

- [ ] Run a manual Finder conversion with:
  - one simple Markdown file
  - one rich Markdown file
  - one existing `name.pdf` collision
Expected: PDFs are generated beside the sources with polished document styling

- [ ] Confirm the installed Quick Action appears in Finder and remains usable
  from a non-terminal workflow
