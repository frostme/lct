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

if command -v shunit2 &>/dev/null; then
  echo "shunit2 is already installed"
else
  curl -sSL https://raw.githubusercontent.com/kward/shunit2/v2.1.8/shunit2 -o /usr/local/bin/shunit2
  chmod +x /usr/local/bin/shunit2
fi
