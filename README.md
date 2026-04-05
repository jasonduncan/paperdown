# paperdown

Convert Markdown files into polished, document-style PDFs from the macOS
Finder.

## Status

Implemented:

- shell converter with explicit `convert` and `merge` modes
- document-style PDF rendering via `pandoc` + `xelatex`
- Finder Quick Actions for three styles and two merge modes
- scripted Quick Action install and uninstall helpers

## Goal

`paperdown` will let a user select one or more `.md` files in Finder, run a
right-click action, and receive readable PDF documents beside the source files.
The output is intended for non-technical readers rather than for people who are
comfortable reading Markdown directly.

## Planned Stack

- macOS Quick Action (Automator)
- Shell-based local converter
- `pandoc`
- `xelatex`

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

No compiled build step is required.

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
- Quick Action Finder-service metadata validation
- Quick Action install and uninstall across the full action set
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

Finder Quick Action install:

```bash
./scripts/install-quick-action.sh
```

Finder Quick Action uninstall:

```bash
./scripts/uninstall-quick-action.sh
```

The installed Finder action invokes the default `report` style, while shell use
can select any supported style and merge mode directly.

See:

- `docs/install/macos-quick-action.md`
