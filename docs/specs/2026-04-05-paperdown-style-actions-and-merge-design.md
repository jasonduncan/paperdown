# paperdown Style Actions and Merge Design

Date: 2026-04-05
Status: Approved baseline
Owner: Codex working session with Jason

## Purpose

Extend `paperdown` beyond the initial single-action Finder workflow so it can:

- expose multiple document styles directly in Finder
- merge multiple Markdown files into a single PDF in two distinct modes
- preserve the existing "fast, right-click, no setup" experience

The goal is to expand document usefulness without introducing prompts, LLM
dependencies, or a native macOS app rewrite.

## Product Direction

This feature set should remain deterministic and document-oriented.

It does not require an LLM. The next release should continue using structured
document assembly through `pandoc`, the existing LaTeX rendering stack, and
fixed workflow definitions.

LLM features may become useful later for generated summaries, synthesized cover
pages, or editorial cleanup, but they are explicitly out of scope for this
design.

## Approved User Experience

The next Finder surface should expose separate actions rather than a prompt.

Approved Finder entries:

- `Convert to PDF (Report)`
- `Convert to PDF (Memo)`
- `Convert to PDF (Handout)`
- `Merge to PDF (Packet)`
- `Merge to PDF (Compiled)`

This keeps the context-menu experience explicit and fast. Users choose the
operation directly from Finder instead of being asked to make a choice after the
workflow starts.

## Scope Boundaries

### Included

- multiple single-file conversion actions with fixed style presets
- merged PDF generation from multiple selected Markdown files
- two merge modes: `packet` and `compiled`
- automatic merged title derivation
- collision-safe merged output naming
- deterministic output location

### Excluded

- interactive prompts or style pickers
- LLM-powered title generation or content synthesis
- native Finder extensions or host app work
- advanced publication editing workflows

## Finder Action Model

Finder actions should remain thin wrappers over the shared converter.

Each workflow bundle should pass fixed arguments into the `paperdown` CLI and
should not own any document logic beyond service registration and invocation.

The installer should install all workflow bundles together into
`~/Library/Services` so the set of actions stays versioned and coherent.

## Converter Model

`paperdown` should evolve into a small explicit CLI with subcommands:

- `paperdown convert --style report file1.md file2.md`
- `paperdown convert --style memo file1.md file2.md`
- `paperdown convert --style handout file1.md file2.md`
- `paperdown merge --mode packet --style report file1.md file2.md`
- `paperdown merge --mode compiled --style report file1.md file2.md`

The CLI should preserve argument order exactly as received. That order becomes
the source order for merged output.

The CLI should continue writing logs to the existing `~/Library/Logs/paperdown`
location and should keep summary behavior consistent across convert and merge
paths.

## Style Exposure Rules

### Single-file conversion

All three existing styles should be exposed in Finder:

- `report`
- `memo`
- `handout`

### Merge actions

The first merge release should expose only the `report` style in Finder.

This keeps the menu from exploding while still delivering the two most useful
merge behaviors. The CLI may still retain a style parameter for merge so the
implementation remains extensible, but Finder should initially present only:

- `Merge to PDF (Packet)`
- `Merge to PDF (Compiled)`

## Merge Semantics

Merged output must preserve the selected file order as received by the Finder
workflow.

If Finder reliably passes the user’s selection order, that order should be used
as-is. If macOS behavior turns out to be ambiguous in some edge case, the
converter should still preserve the received argument order rather than
re-sorting internally.

Merged output is written beside the first selected Markdown file.

## Output Naming

Merged filenames should derive from the first selected file.

Recommended shape:

- packet: `<first-selected-basename>-packet.pdf`
- compiled: `<first-selected-basename>-compiled.pdf`

Collision handling should match current `paperdown` behavior:

- `name-compiled.pdf`
- `name-compiled-1.pdf`
- `name-compiled-2.pdf`

and similarly for `packet`.

No merged PDF should overwrite an existing file by default.

## Compiled Mode

`compiled` mode should feel like one authored publication.

Behavior:

- preserve selected-file order
- derive document title automatically
- include a table of contents by default
- treat each source file as a top-level section
- use a shared document-level style

### Title derivation

The compiled document title should come from:

1. the first selected file’s frontmatter `title`, if present
2. otherwise the first selected file’s basename

No user prompt is required.

### Metadata handling

The first selected file provides the document-level metadata baseline.

Practical implications:

- first file `title` may become the compiled document title
- first file `author` and `date` may be used when present
- later files should not be allowed to override the document-level title
- later files should be treated as content sections, not as separate standalone
  documents

### Structure

Each source file should begin as a top-level section in the merged output. A
table of contents should be enabled by default for this mode.

## Packet Mode

`packet` mode should be simple and literal.

Behavior:

- preserve selected-file order
- concatenate files with page breaks between them
- avoid a table of contents
- keep rendering minimal and predictable

This mode is for distributing a bundle of notes or documents as one PDF, not
for creating a polished unified publication.

## File Selection Rules

Primary supported inputs remain Markdown files.

For `convert`:

- non-Markdown inputs should be skipped
- the batch should continue
- skipped files should be counted in the summary

For `merge`:

- non-Markdown inputs may be ignored
- if no Markdown files remain after filtering, the merge should fail clearly

The converter should never silently produce an empty merged document.

## Architecture

The implementation should remain cleanly separated:

- workflow bundles own Finder registration only
- wrapper scripts own fixed arguments per action
- `paperdown` CLI owns convert and merge orchestration
- template/style assets own appearance
- logs own diagnostics

This separation matters because the number of Finder actions will grow, but the
document behavior should still live in one place.

## Finder Integration Design

The repo should contain multiple workflow bundles, one per Finder action.

Each workflow should call the same installed wrapper path, but pass different
fixed arguments such as:

- `paperdown convert --style report`
- `paperdown convert --style memo`
- `paperdown convert --style handout`
- `paperdown merge --mode packet --style report`
- `paperdown merge --mode compiled --style report`

The installer should install all workflows and rewrite repo-root placeholders in
each bundle the same way the current installer handles the single existing
workflow.

## Testing and Validation

Validation should cover three layers.

### 1. Converter tests

- convert with each style
- merge packet preserves input order
- merge compiled preserves input order
- compiled title derivation from first selected file metadata
- merged output naming and collision handling

### 2. Workflow metadata tests

- every workflow is registered as a file-based Finder Service
- each workflow carries the expected fixed action arguments

### 3. End-to-end smoke tests

- install all workflows into a temp Services directory
- invoke representative workflows through `automator`
- verify expected PDFs appear in expected locations

Manual verification should still include a real Finder run for at least one
convert action and one merge action.

## Why This Design Is Correct

This design extends `paperdown` in the direction users actually need without
breaking the strengths of the current approach.

It keeps Finder interaction explicit, keeps the implementation deterministic,
and introduces richer document workflows without dragging in LLM complexity or a
native app rewrite. It also treats merged output as two distinct products
instead of one overloaded feature: a literal packet and a polished compiled
document.
