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

No buildable artifact exists yet.

Implementation details and the planned file structure live in:

- `docs/specs/2026-04-03-markdown-finder-pdf-tool-design.md`
- `docs/superpowers/plans/2026-04-03-paperdown-v1.md`

## Test

No automated test suite exists yet.

The first implementation slice will add smoke tests for:

- single-file conversion
- multi-file conversion
- filename collision handling
- representative Markdown fixtures

## Run

No runnable command or installed Quick Action exists yet.

The intended runtime entry points are:

- a local converter command in this repo
- an installable Finder Quick Action that invokes the converter with the
  default `report` style
