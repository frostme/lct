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

[See docs](./docs/README.md)

## Contributing

- run `setup.sh` to get necessary libraries
- gum (for interactive CLI presentation)
- `mise run build` to generate local version in target/build/lct
- `mise run test` to run the smoke tests (uses approvals.bash)
- `mise run install` to install local version (target/build/lct) to /usr/local/bin
- update `src/bashly.yml` with a new version to trigger the GitHub Action release on merge to `main`
