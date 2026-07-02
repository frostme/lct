# lct

[![Tests](https://github.com/frostme/lct/actions/workflows/test.yml/badge.svg)](https://github.com/frostme/lct/actions/workflows/test.yml)

## Installation

```bash
curl -fsSL https://frostme.github.io/lct/install.sh | bash
```

### mise

You can also install using [mise](https://mise.jdx.dev/):

```bash
mise use -g github:frostme/lct
```

## Usage

[See docs](https://frostme.github.io/lct)

### Bootstrap idempotency

`lct bootstrap` is safe to rerun against state it previously created:

- Existing config directories and project Git repositories are reported and skipped.
- Package bundles, plugins, and modules use their existing restore/cache checks, and existing secrets are preserved.
- A config destination that is not a directory, a project destination that is not a Git repository, or a missing gathered config source stops with recovery guidance instead of being treated as valid state.
- `lct bootstrap --force` intentionally replaces configured local config destinations; it does not overwrite project directories.

Third-party plugin scripts are outside this core guarantee and must define their own idempotent behavior.

## Contributing

- run `setup.sh` to get necessary libraries
- gum (for interactive CLI presentation)
- `mise run build` to generate local version in target/build/lct
- `mise run test` to run the smoke tests (uses approvals.bash)
- `mise run install` to install local version (target/build/lct) to /usr/local/bin
- update `src/bashly.yml` with a new version to trigger the GitHub Action release on merge to `main`
