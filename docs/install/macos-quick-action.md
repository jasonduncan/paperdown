# macOS Quick Action Install Guide

## Prerequisites

`paperdown` depends on:

- `pandoc`
- `xelatex`

Both are already present in Jason's current development environment. On another
Mac, install them before using the Quick Action.

## Repo Paths

- Converter: `bin/paperdown`
- Quick Action wrapper: `bin/paperdown-quick-action`
- Installer: `scripts/install-quick-action.sh`
- Uninstaller: `scripts/uninstall-quick-action.sh`
- Action manifests: `macos/quick-actions/actions/`
- Generated workflow bundles: `macos/quick-actions/generated/`

## Install the Quick Action

From the repo root:

```bash
./scripts/install-quick-action.sh
```

This installs the full `paperdown` Finder action set into the per-user Services
directory and rewrites each workflow bundle so it points at the current repo
path.

## Uninstall the Quick Action

From the repo root:

```bash
./scripts/uninstall-quick-action.sh
```

## Reinstall After Workflow Changes

Run the installer again after editing any workflow bundle.

If Finder still shows an old version:

```bash
/System/Library/CoreServices/pbs -flush 2>/dev/null || true
killall Finder 2>/dev/null || true
```

If the menu entry is still missing after that, log out and back in to refresh
macOS Services registration.

If Finder says the Service is not configured correctly, reinstall the workflow
from the repo root:

```bash
./scripts/install-quick-action.sh
```

Then restart Finder once:

```bash
killall Finder 2>/dev/null || true
```

## Use From Finder

1. Select one or more Markdown files in Finder.
2. Right-click.
3. Open `Quick Actions` if needed.
4. Choose one of:
   - `Convert to PDF (Report)`
   - `Convert to PDF (Memo)`
   - `Convert to PDF (Handout)`
   - `Merge to PDF (Packet)`
   - `Merge to PDF (Compiled)`

Expected behavior:

- convert actions write one PDF beside each selected Markdown file
- merge actions write one merged PDF beside the first selected Markdown file
- existing PDFs are preserved by creating `-1`, `-2`, and higher suffixes
- non-Markdown files are skipped
- a notification or dialog summarizes the result

Merge mode behavior:

- `Packet` concatenates the selected Markdown files in Finder order with page
  breaks between documents
- `Compiled` creates one publication-style document in Finder order, derives its
  title from the first selected file, and includes a table of contents

## Use From the Shell

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

The wrapper is intended for the Automator workflow and adds macOS notifications
on top of the normal converter.

The wrapper is primarily for Automator workflow execution. Finder normally calls
it through one of the installed workflow bundles with fixed arguments.

## Logs

Conversion logs are written to:

```text
~/Library/Logs/paperdown/
```

Each run creates a timestamped log file. Use the newest log when a conversion
fails or the Finder action shows an error dialog.

## Headless Verification

You can verify the versioned workflow without using Finder:

```bash
tmpservices=$(mktemp -d)
./scripts/install-quick-action.sh --services-dir "$tmpservices"
tmpdir=$(mktemp -d)
cp tests/fixtures/basic.md "$tmpdir/basic.md"
cp tests/fixtures/merge-a.md "$tmpdir/merge-a.md"
cp tests/fixtures/merge-b.md "$tmpdir/merge-b.md"
automator -i "$tmpdir/basic.md" "$tmpservices/Convert to PDF (Report).workflow"
automator -i "$tmpdir/merge-a.md" "$tmpdir/merge-b.md" "$tmpservices/Merge to PDF (Compiled).workflow"
ls "$tmpdir"
./scripts/uninstall-quick-action.sh --services-dir "$tmpservices"
rm -rf "$tmpservices"
rm -rf "$tmpdir"
```

Expected result:

- `basic.pdf` appears beside `basic.md`
- `merge-a-compiled.pdf` appears beside `merge-a.md`

You can also validate the workflow metadata directly:

```bash
bash tests/smoke/test_quick_action_metadata.sh
```
