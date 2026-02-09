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

if command -v semver &>/dev/null; then
  echo "semver is already installed"
else
  TOOL_URL="https://raw.githubusercontent.com/fsaintjacques/semver-tool/master/src/semver"
  INSTALL_PATH="/usr/local/bin/semver"

  curl -sSL "$TOOL_URL" -o "$INSTALL_PATH"
  chmod +x "$INSTALL_PATH"
fi
