# paperdown

Convert Markdown files into polished, document-style PDFs from the macOS
Finder.

## Status

Bootstrap repository. The approved design spec and the first implementation
plan are checked in; the converter and Finder Quick Action are not implemented
yet.

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

The v1 Finder workflow installs a single document style:

- `report` is the default and only Finder-exposed style in v1

The repo also reserves future presets so menu expansion does not require a
structural rewrite:

- `memo`
- `handout`

## Build

No compiled build step is required.

Implementation details and the planned file structure live in:

- `docs/specs/2026-04-03-markdown-finder-pdf-tool-design.md`
- `docs/superpowers/plans/2026-04-03-paperdown-v1.md`

## Test

Run the shell smoke test:

```bash
bash tests/smoke/test_paperdown.sh
```

Current smoke coverage:

- single-file conversion
- multi-file conversion
- filename collision handling
- mixed-selection skipping
- report-style metadata verification

## Run

Direct converter:

```bash
./bin/paperdown path/to/file.md
./bin/paperdown path/to/one.md path/to/two.md
```

Quick Action wrapper:

```bash
./bin/paperdown-quick-action path/to/file.md
```

Finder Quick Action install:

```bash
mkdir -p ~/Library/Services
rm -rf "$HOME/Library/Services/Convert Markdown to PDF.workflow"
cp -R "macos/quick-actions/Convert Markdown to PDF.workflow" "$HOME/Library/Services/"
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
```

The installed Finder action invokes the default `report` style.

See:

- `docs/install/macos-quick-action.md`
