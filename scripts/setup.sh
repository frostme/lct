#!/bin/bash
set -Eeuo pipefail

if command -v mise &>/dev/null; then
  echo "mise is already installed"
else
  cargo install cargo-binstall
  cargo binstall mise
fi

mise trust
mise install
mise run setup
