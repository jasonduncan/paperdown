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
- Versioned workflow bundle:
  - `macos/quick-actions/Convert Markdown to PDF.workflow`

## Install the Quick Action

From the repo root:

```bash
./scripts/install-quick-action.sh
```

This installs the Finder Quick Action into the per-user Services directory and
rewrites the workflow bundle so it points at the current repo path.

## Uninstall the Quick Action

From the repo root:

```bash
./scripts/uninstall-quick-action.sh
```

## Reinstall After Workflow Changes

Run the installer again after editing the workflow bundle.

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
4. Choose `Convert Markdown to PDF`.

Expected behavior:

- one PDF is written beside each selected Markdown file
- existing PDFs are preserved by creating `-1`, `-2`, and higher suffixes
- non-Markdown files are skipped
- a notification or dialog summarizes the result

## Use From the Shell

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

The wrapper is intended for the Automator workflow and adds macOS notifications
on top of the normal converter.

The Finder Quick Action itself stays fixed to the `report` style in v1. The
other bundled styles are currently intended for shell-based use.

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
automator -i "$tmpdir/basic.md" "$tmpservices/Convert Markdown to PDF.workflow"
ls "$tmpdir"
./scripts/uninstall-quick-action.sh --services-dir "$tmpservices"
rm -rf "$tmpservices"
rm -rf "$tmpdir"
```

Expected result:

- `basic.pdf` appears beside `basic.md`

You can also validate the workflow metadata directly:

```bash
bash tests/smoke/test_quick_action_metadata.sh
```
