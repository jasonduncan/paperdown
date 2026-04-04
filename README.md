# paperdown

Convert Markdown files into polished, document-style PDFs from the macOS
Finder.

## Status

Implemented v1:

- shell converter for one or more Markdown files
- document-style PDF rendering via `pandoc` + `xelatex`
- macOS Finder Quick Action wrapper
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

## Styles

Available converter styles:

- `report`
- `memo`
- `handout`

The Finder Quick Action stays fixed to `report` in v1.

## Build

No compiled build step is required.

Implementation details and the planned file structure live in:

- `docs/specs/2026-04-03-markdown-finder-pdf-tool-design.md`
- `docs/superpowers/plans/2026-04-03-paperdown-v1.md`

## Test

Run the shell smoke test:

```bash
bash tests/smoke/test_paperdown.sh
bash tests/smoke/test_quick_action_metadata.sh
```

Current smoke coverage:

- single-file conversion
- multi-file conversion
- filename collision handling
- mixed-selection skipping
- report-style metadata verification
- stripped-down Finder-style environment handling
- Quick Action Finder-service metadata validation
- Quick Action install and uninstall
- headless Automator execution through an installed workflow

## Run

Direct converter:

```bash
./bin/paperdown path/to/file.md
./bin/paperdown path/to/one.md path/to/two.md
./bin/paperdown --style memo path/to/file.md
```

Quick Action wrapper:

```bash
./bin/paperdown-quick-action path/to/file.md
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
can select any supported style with `--style`.

See:

- `docs/install/macos-quick-action.md`
