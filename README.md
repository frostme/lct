# lct

## Installation

- `curl -fsSL https://frostme.github.io/lct/install.sh | bash`

## Usage

[See docs](./docs/README.md)

## Contributing

- run `setup.sh` to get necessary libraries
- gum (for interactive CLI presentation)
- `just build` to generate local version in target/build/lct
- `just test` to run the smoke tests (uses approvals.bash)
- `just install` to install local version (target/build/lct) to /usr/local/bin
- update `src/bashly.yml` with a new version to trigger the GitHub Action release on merge to `main`
