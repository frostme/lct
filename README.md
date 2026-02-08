# lct

## Installation

- `curl -fsSL https://frostme.github.io/lct/install.sh | bash`

## Usage

[See docs](./docs/README.md)

## Contributing

- run `setup.sh` to get necessary libraries
- gum (for interactive CLI presentation)
- `just build` to generate local version in target/build/lct
- `just test` to run the smoke tests (uses bash_unit)
- `just install` to install local version (target/build/lct) to /usr/local/bin
- `just release <major|minor|patch>` to generate new release
