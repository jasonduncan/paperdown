# paperdown Packaged Quality Design

Date: 2026-04-05
Status: Approved baseline
Owner: Codex working session with Jason

## Purpose

Advance `paperdown` from a repo-local utility into a packaged macOS product
that improves three areas together:

- document quality
- packaging and installability
- lightweight user controls

The next release should preserve the explicit Finder action workflow while
eliminating the assumption that the user has a repo checkout, `pandoc`, or a
TeX engine installed locally.

## Product Direction

The next phase of `paperdown` should become a real packaged macOS product,
without yet committing to a heavy Finder-extension architecture.

The core product should be:

- a native macOS host app
- an embedded conversion runtime
- explicit Finder Quick Actions that continue to appear as distinct menu items

This keeps the user-facing interaction simple and familiar while making
installation, updates, and diagnostics much more durable.

## Approved Experience

### Finder surface

Finder should continue exposing explicit actions rather than collapsing to a
single configurable entry.

Approved Finder entries remain:

- `Convert to PDF (Report)`
- `Convert to PDF (Memo)`
- `Convert to PDF (Handout)`
- `Merge to PDF (Packet)`
- `Merge to PDF (Compiled)`

### Settings surface

The packaged product should add a small native settings surface, but only for
global defaults and install health.

It should not introduce per-run prompts or deep per-style customization in the
first packaged release.

## Packaging Model

### Recommended packaging shape

The preferred delivery model is a normal drag-to-Applications macOS app.

`Paperdown.app` should:

- be installable like a normal Mac app
- install or update Finder Quick Actions on first launch
- keep the conversion runtime and templates bundled with the product
- expose a small settings window and status/diagnostic surface

This approach is preferred over a `.pkg` installer because it provides a
cleaner update model, a better home for settings, and a simpler mental model
for users.

### Runtime location

The app may keep the converter runtime:

- inside the application bundle when practical, and/or
- in `~/Library/Application Support/paperdown/` when an extracted working
  runtime is needed

The product should no longer rely on a checked-out development repo at runtime.

## Rendering Stack

The packaged version should bundle its own rendering stack.

The recommended rendering direction is:

- bundled `pandoc`
- bundled `typst`-based PDF rendering rather than a bundled LaTeX stack

Reasoning:

- Typst is substantially easier to ship self-contained than a full TeX
  distribution.
- It gives `paperdown` better odds of becoming a reliable packaged product on a
  clean Mac.
- It is a better foundation for document-quality work such as cover pages,
  publication-like compiled documents, and shared style systems.

The current repo-local `pandoc + xelatex` path can remain useful during
transition, but the packaged product should target a bundled rendering runtime
that does not require user-installed TeX tooling.

## Quality Model

The quality pass should not be treated as three unrelated style tweaks.

Instead, `paperdown` should evolve toward a shared document system:

- one rendering engine
- one shared document foundation
- style-specific overrides layered on top

### Shared document foundation

The shared foundation should define:

- document grid and margins
- typography scale
- heading hierarchy and spacing rhythm
- code block treatment
- tables
- lists
- quotes and callouts
- running headers and footers
- page numbering and metadata placement

This allows quality improvements to propagate across all outputs rather than
being reimplemented in each style separately.

### Style identities

The three supported styles should remain explicit and visually distinct:

- `report`
  - restrained, professional, trustworthy
  - stronger title pages, table handling, code block presentation, and section
    hierarchy
- `memo`
  - tighter and simpler
  - optimized for short internal documents and business communication
- `handout`
  - larger type, more whitespace, higher contrast, easier scanning
  - optimized for accessibility and print readability

## Merge Modes

The two merge modes should remain, but `compiled` should receive the first
major quality investment.

### Packet

`packet` remains literal and predictable:

- preserve selected file order
- insert page breaks between source files
- minimal editorial treatment

### Compiled

`compiled` becomes a more publication-like document:

- cover page enabled by default
- table of contents enabled by default
- section-opening rhythm for each source file
- stronger running headers and footers
- shared metadata and title derived from the first selected file, as already
  approved in the prior design

## Controls Model

The first packaged release should expose global defaults only.

Approved settings scope:

- Finder Quick Action install/update status
- health/status of the bundled runtime
- `compiled` defaults such as cover page on/off and TOC on/off
- default convert behavior where a global default is meaningful
- output naming and diagnostic/log visibility where appropriate

Not in scope for the first packaged release:

- per-style override panels
- arbitrary template editing
- interactive Finder prompts

This keeps the control surface small and avoids configuration sprawl while the
product is still stabilizing.

## Finder Integration Model

Finder integration should remain thin and explicit.

The installed Quick Actions should:

- continue to exist as separate workflow bundles or equivalent Services
- call into the packaged runtime with fixed arguments
- avoid owning any document logic

The app should own installation and update of those actions so users do not
need to run repo scripts manually.

## Architecture

The packaged system should separate into clear layers:

- native macOS app
  - first-run setup
  - settings
  - diagnostics
  - install/update of Finder actions
- conversion runtime
  - argument parsing
  - convert and merge orchestration
  - logging
  - rendering integration
- style and template assets
  - shared foundation
  - style profiles
  - merge-mode assets such as cover and TOC behavior
- Finder action definitions
  - explicit action names
  - fixed invocation arguments only

This keeps UI, packaging, and rendering concerns separated so the product can
evolve without coupling everything to the Finder surface.

## Diagnostics and Failure Handling

The packaged version should make failures more understandable than the current
script-first workflow.

The app should provide:

- clear install state for Finder actions
- runtime version visibility
- access to the log directory
- a simple repair/reinstall actions operation

Conversion failures should still produce batch-friendly results:

- continue processing when appropriate
- summarize converted, skipped, and failed counts
- retain actionable logs for diagnosis

## Scope Boundaries

### Included

- packaged macOS app host
- bundled rendering stack
- bundled conversion runtime
- explicit Finder actions retained
- shared quality foundation for styles
- improved `compiled` presentation
- lightweight global settings

### Excluded

- full Finder extension rewrite
- LLM-based editorial generation or synthesis
- per-style advanced customization
- user-authored templates in the first packaged release

## Testing and Validation

Validation should expand beyond the current script-only smoke tests.

### Runtime validation

- convert and merge behavior still pass deterministically
- bundled renderer works on a clean machine profile
- quality defaults render expected cover page, TOC, and style distinctions

### Packaging validation

- first launch installs Finder actions successfully
- reinstall/update path repairs drifted or missing actions
- app works without a checked-out repo
- app works without separately installed `pandoc` or TeX

### UX validation

- explicit Finder actions remain visible and correctly named
- settings changes affect global defaults only where intended
- failure states surface actionable repair guidance

## Recommended Next Step

The implementation plan for this phase should treat the work as a product
transition rather than a style-only tweak.

Recommended execution order:

1. define packaged architecture and runtime layout
2. establish bundled rendering strategy
3. build the native host app and action installer
4. migrate styles into a shared quality system
5. expose lightweight global settings and diagnostics
