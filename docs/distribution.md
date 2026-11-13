# Distribution Workflow (macOS)

## Current state

`paperdown` now supports the full local release pipeline shape:

1. export a self-contained `Paperdown.app`
2. sign it
3. prepare or submit it for notarization

What is still missing on this machine is the actual Apple credential material:

- no valid Developer ID code-signing identity is currently installed
- no notarization credentials are configured for live submission

The packaged app now surfaces those prerequisites directly through its release
readiness panel and support report:

- Developer ID Application identities detected via `security find-identity -v -p codesigning`
- `notarytool` keychain-profile readiness, defaulting to profile name `paperdown`

That means the repo can prove:

- unsigned export
- ad-hoc signing
- notarization archive creation
- notarization command rendering via dry run
- CLI release-readiness reporting
- CLI notary-profile setup command rendering via dry run

It cannot yet prove:

- real Developer ID signing
- live notarization submission
- stapled notarization on a shipped bundle

## 1) Export the app

```bash
./Packaging/export-app.sh
```

Default output:

```text
dist/Paperdown.app
```

Optional zip export:

```bash
./Packaging/export-app.sh --zip
```

## 2) Sign the app

For local validation with ad-hoc signing:

```bash
./scripts/sign-macos-app.sh --identity -
```

For Developer ID signing:

```bash
./scripts/sign-macos-app.sh \
  --identity "Developer ID Application: <Team Name> (<TEAMID>)"
```

You can also override the app path:

```bash
./scripts/sign-macos-app.sh --app /path/to/Paperdown.app --identity -
```

## 2.5) Check readiness and store a notary profile

Check the current machine state:

```bash
./scripts/check-release-readiness.sh --profile paperdown
./scripts/check-release-readiness.sh --profile paperdown --json
```

Store a notary profile with Apple ID credentials:

```bash
./scripts/store-notary-profile.sh \
  --profile paperdown \
  --apple-id <apple-id> \
  --team-id <team-id> \
  --password <app-specific-password>
```

Store a notary profile with an App Store Connect API key:

```bash
./scripts/store-notary-profile.sh \
  --profile paperdown \
  --key /path/AuthKey_XXX.p8 \
  --key-id XXX \
  --issuer <issuer-uuid>
```

Render the command safely without storing anything:

```bash
./scripts/store-notary-profile.sh \
  --profile paperdown \
  --apple-id <apple-id> \
  --team-id <team-id> \
  --password <app-specific-password> \
  --dry-run
```

## 3) Notarize the app

Using a keychain profile:

```bash
NOTARY_KEYCHAIN_PROFILE=<profile> ./scripts/notarize-macos-app.sh
```

Using an App Store Connect API key:

```bash
NOTARY_KEY_PATH=/path/AuthKey_XXX.p8 \
NOTARY_KEY_ID=XXX \
NOTARY_ISSUER=<issuer-uuid> \
./scripts/notarize-macos-app.sh
```

Dry run without live submission:

```bash
NOTARY_KEYCHAIN_PROFILE=<profile> ./scripts/notarize-macos-app.sh --dry-run
```

The notarization script creates:

```text
dist/Paperdown-notarize.zip
```

If submission succeeds and stapling is enabled, it staples the ticket back onto
the app bundle and validates the stapled result.

## Verification

Current release-pipeline verification:

```bash
bash tests/smoke/test_export_app.sh
bash tests/smoke/test_release_distribution.sh
bash tests/smoke/test_release_helpers.sh
```

## Notes

- `sign-macos-app.sh` defaults to ad-hoc signing so local validation is
  available even without a Developer ID certificate.
- `notarize-macos-app.sh` requires explicit credentials unless `--dry-run` is
  used for command verification only.
- If you want the app to inspect a different keychain profile than `paperdown`,
  launch it with `PAPERDOWN_NOTARY_PROFILE=<profile>`.
- For external distribution, the intended path is:
  - Developer ID sign
  - notarize
  - staple
  - ship the stapled `.app` or a zip built from that stapled bundle
