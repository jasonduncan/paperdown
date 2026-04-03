# Markdown Finder PDF Tool Design

Date: 2026-04-03
Status: Approved baseline
Owner: Codex working session with Jason

## Purpose

Create a macOS-native right-click workflow that converts one or more Markdown
files into polished, document-style PDFs for non-technical readers.

The tool should make Markdown-authored content easier to share as a real
document artifact rather than as raw source text or developer-facing rendered
Markdown.

## Approved User Experience

The approved v1 experience is:

- select one or more `.md` files in Finder
- right-click and choose a fixed action such as `Convert Markdown to PDF`
- receive one PDF per source file in the same folder as the source file
- if a target filename already exists, create `name-1.pdf`, `name-2.pdf`, and
  so on rather than overwriting an existing PDF

The action should be batch-safe and should continue processing the remaining
files even if one file fails conversion.

## Core Product Requirement

The PDF must look like a real document, not like raw Markdown.

This means the output must include intentional page layout, typography, spacing,
heading hierarchy, code block treatment, blockquote treatment, table styling,
and sensible handling of title metadata.

The tool is explicitly aimed at accessibility in the broad practical sense:
producing a familiar, readable, printable artifact for readers who are not
expected to consume Markdown directly.

## Approved Architecture

Use a thin Finder-facing macOS Quick Action backed by a reusable local
conversion tool.

### 1. Finder Quick Action

The Quick Action is the right-click entry point.

Responsibilities:

- receive one or more selected files from Finder
- pass them to the local converter with a fixed style preset
- surface a simple success/failure summary to the user

The Quick Action should remain intentionally thin so Finder integration can be
changed later without rewriting the conversion logic.

### 2. Local Converter Tool

The converter is the real implementation surface.

Responsibilities:

- accept one or more Markdown file paths
- apply a fixed style preset for the invoked action
- generate collision-safe output filenames
- convert each file independently
- continue after per-file failures
- emit a final summary and write logs for diagnostics

This separation keeps the workflow maintainable and allows the same converter to
be reused later from Finder, Shortcuts, shell, or a native app.

### 3. Template and Style Assets

The renderer should use a shared document template plus named style presets.

Responsibilities:

- define page geometry and margins
- define typography and heading hierarchy
- style tables, lists, code blocks, blockquotes, and images
- provide named presets such as `report`, `memo`, and `handout`

For v1, the right-click action should invoke the fixed `report` preset, but the
style system should be organized so additional actions or a later picker can
expose other presets without redesigning the tool.

### 4. Logging and Diagnostics

The tool should write failures to a predictable local log location.

Responsibilities:

- record source file, output target, command failure, and stderr summary
- keep logs outside the Finder workflow itself
- support diagnosing template or content issues without opening Automator

## Rendering Strategy

Use `pandoc` with `xelatex`.

This is the approved v1 rendering stack because it is already available on the
machine and is well-suited to document-grade PDF generation.

The rendering layer should support:

- plain Markdown files without metadata
- frontmatter-enhanced Markdown files when metadata is present
- document title/subtitle/author/date handling
- tables, fenced code blocks, images, lists, blockquotes, and long documents

The output should be biased toward a clean printable document rather than a
browser-style or GitHub-style Markdown rendering.

## Metadata Model

Frontmatter metadata should be supported when present, but should not be
required.

Expected useful fields include:

- `title`
- `subtitle`
- `author`
- `date`
- optional style or document-class hints for future extension

If metadata is absent, the tool should still produce a clean PDF using the file
contents alone.

## File Handling Rules

### Accepted Inputs

Primary supported inputs are `.md` files passed from Finder.

If Finder passes mixed selections, the tool should ignore non-Markdown files,
continue processing the Markdown files, and include the skipped file count in
the final summary.

### Output Location

Each PDF is written beside the original Markdown file.

### Collision Policy

If `name.pdf` already exists, generate:

- `name-1.pdf`
- `name-2.pdf`
- and so on

No existing PDFs should be overwritten by default.

## Failure Handling

The tool must fail per file, not per batch.

Approved behavior:

- attempt all selected files
- record which files succeeded and which failed
- show a final summary such as converted `N`, failed `M`
- preserve error details in a log for later inspection

This behavior is important because a Finder batch action should remain useful
when one document has malformed content or a rendering problem.

## Style System

The style system is an approved part of the design even though the first Finder
action uses only one fixed preset.

### V1

- one fixed Quick Action
- one configured default document style: `report`

### Planned Expansion

Later style exposure may take one of three forms:

- multiple separate Quick Actions in the Finder menu
- a submenu-style Finder integration if that becomes practical
- a prompt or picker surfaced by a later native wrapper

The converter should therefore treat style as a first-class parameter even if
the Finder action hardcodes it in v1.

## Recommended Initial Project Shape

Suggested local structure:

- converter script/tool in a reusable local workspace path
- `templates/` for base document templates
- `styles/` for preset definitions
- `logs/` for conversion diagnostics
- a small README covering installation, style presets, and Finder setup

The exact folder can be chosen during implementation, but it should live in a
stable reusable location rather than being embedded only inside an Automator
workflow bundle.

## Boundaries and Responsibilities

The units should remain cleanly separated:

- Finder action owns invocation and user entry point
- converter owns orchestration, file policy, and summaries
- renderer assets own appearance
- logs own diagnostics

Each unit should be understandable without reading the internals of the others.
That separation is important if the workflow later graduates to a native Swift
wrapper or adds richer style selection.

## Testing and Validation Plan

The implementation plan should cover both automated and manual validation.

Automated validation should include:

- single-file conversion smoke test
- multi-file batch conversion smoke test
- filename collision tests
- representative content fixtures for headings, lists, tables, blockquotes,
  code blocks, images, and frontmatter

Manual validation should include:

- Finder right-click workflow test
- visual review of the generated PDF for document quality
- summary notification/dialog behavior on mixed success and failure

## Explicit Non-Goals for V1

The following are intentionally not required for the first version:

- a native Swift app or Finder extension
- an interactive style picker
- cloud sync or sharing workflows
- OCR, accessibility tagging audits, or advanced PDF post-processing
- a generalized document publishing system

These may be added later, but they are not required to deliver the approved
right-click conversion workflow.

## Why This Design Is Correct

This design delivers the requested user value quickly while preserving a clean
path for later growth.

It avoids over-engineering by using native macOS Quick Actions for the UX layer
and a normal local converter for the durable logic layer. It also keeps the most
important quality bar explicit: the output is a polished, readable document for
people who should not have to interact with Markdown directly.
