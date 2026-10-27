# Cloudflare CLI for Homebrew

A community Homebrew tap for [Cloudflare's `cf` CLI](https://github.com/cloudflare/cf).
This repository is independently maintained and is not an official Cloudflare or Homebrew project.

## Install

```sh
brew install drblessing/cloudflare-cli/cloudflare-cli
cf --version
```

Homebrew installs its own Node 24 runtime as a dependency. The `cf` and `cloudflare`
launchers use that runtime even when nvm selects a different Node version. Your
project's Node configuration is not changed.

The upstream CLI is currently **beta**. This tap exists because Homebrew's main
catalog requires a stable upstream release. The formula is named `cloudflare-cli`
because Homebrew's existing `cf` formula is an unrelated timestamp utility.

## Sign in

If you have already signed in with `cf`, the Homebrew installation reuses the same
user-level Cloudflare credentials. Otherwise:

```sh
cf auth login
cf auth whoami
```

Wrangler has a separate login. This package does not import Wrangler credentials.

## Switching from an npm installation

An existing npm-installed `cf` may appear earlier on your PATH. Inspect the commands:

```sh
type -a cf cloudflare
"$(brew --prefix)/bin/cf" --version
```

After verifying the Homebrew command, remove the npm copy from the Node version
where you originally installed it:

```sh
npm uninstall --global cf
```

Removing the npm package does not delete the user-level Cloudflare login. Other
nvm versions may have their own npm copy. Homebrew also refuses to link this
formula alongside the unrelated `cf` or `cloudfoundry-cli` formulae, which install
the same command name.

## Update or uninstall

```sh
brew update
brew upgrade drblessing/cloudflare-cli/cloudflare-cli
```

```sh
brew uninstall cloudflare-cli
brew untap drblessing/cloudflare-cli
```

Uninstalling the formula leaves Cloudflare credentials in their normal user-level
location. To revoke the login, use `cf auth logout` before uninstalling.

## Packaging and maintenance

- Downloads the exact official npm release and verifies its SHA-256 checksum.
- Pins production dependencies with a checksummed npm shrinkwrap file, including
  integrity hashes and optional packages for other platforms.
- Installs packages inside Homebrew's prefix, with npm lifecycle scripts disabled.
- Uses a supported Node 24 runtime; it does not rely on the active nvm version.
- Tests command aliases, API schema lookup, Node selection, and the local Workers runtime.

Updates are reviewed and published explicitly; this tap does not automatically
install new beta versions. See [CONTRIBUTING.md](CONTRIBUTING.md) for release steps.
Issues about packaging belong in this repository. CLI bugs belong in
[cloudflare/cf](https://github.com/cloudflare/cf/issues).

The formula and tap files are MIT licensed. Cloudflare's CLI retains its upstream
MIT OR Apache-2.0 license, and dependencies retain their own licenses.
