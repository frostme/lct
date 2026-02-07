# lct

## Installation

- `git clone`
- `make install`

## Usage

[See docs](./docs/README.md)

## Contributing

Needed Libraries

- run `setup.sh` to get necessary libraries (bashly, shunit2, etc)
- gum (for interactive CLI presentation)
- `just build` to generate local version in target/lct
- `just test` to run the smoke tests (uses shunit2)
- `make install` to install local version
- `just release <major|minor|patch>` to generate new release
