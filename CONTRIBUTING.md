# Maintaining the formula

This is a community tap for a beta release. Review each upstream update before
publishing it. A formula update and its lockfile must describe the same version.

## Prepare an update

1. Select an exact version from the official `cf` npm package. Verify the
   repository remains `cloudflare/cf` and review its release notes.
2. Download the `dist.tarball` URL from the version's npm registry metadata. Check
   its published integrity and compute its SHA-256 checksum for the formula.
3. In a temporary directory, copy the published `package.json` and remove only
   `devDependencies` and `scripts`. Production dependencies must remain unchanged.
4. Using a supported Node/npm version, run:

   ```sh
   npm install --package-lock-only --ignore-scripts --omit=dev --no-audit --no-fund
   ```

5. Verify every non-root lockfile entry has an exact version, an HTTPS npm registry
   URL, and an integrity hash. Keep optional dependencies for other platforms.
   Copy `package-lock.json` to `Resources/cf/npm-shrinkwrap.json` and commit it.
6. Update the formula's upstream URL, version, SHA-256, and shrinkwrap resource.
   Pin the resource URL to the full commit SHA from step 5, never a moving branch.
   Recompute the shrinkwrap file's SHA-256.
7. Check upstream's `engines.node` requirements against the formula's Node
   dependency. The launcher must use that runtime, independent of the user's PATH.

## Validate and publish

The lockfile commit must be available on GitHub before Homebrew can fetch its
immutable resource URL. For local development before publishing, use a separate
test tap with a `file://` URL pointing to the identical lockfile; keep the same
checksum. Never commit a local path in the published formula.

Run the following against the checked-out tap:

```sh
brew style Formula/cloudflare-cli.rb
brew install --build-from-source drblessing/cloudflare-cli/cloudflare-cli
brew test drblessing/cloudflare-cli/cloudflare-cli
brew audit --strict --online drblessing/cloudflare-cli/cloudflare-cli
```

Use `brew reinstall --build-from-source` when the formula is already installed.
Confirm both command names work with an incompatible `node` first on PATH. The
formula's test also runs an actual local Worker to check its native runtime.
Never add credentials, personal configuration files, or npm caches to the tap.

The CI workflow installs and tests the formula on macOS and Linux. Publish only
after the required platforms pass. Report support limits when a platform cannot
be tested. When upstream ships a stable release, reassess eligibility for
Homebrew's main catalog and the need for this community tap.
