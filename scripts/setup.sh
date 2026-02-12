#!/bin/bash
set -Eeuo pipefail

SEMVER_VERSION="3.4.0"
SEMVER_SHA256="1ff4a97e4d1e389f6f034f7464ac4365f1be2d900e2dc2121e24a6dc239e8991"
SEMVER_URL="https://raw.githubusercontent.com/fsaintjacques/semver-tool/${SEMVER_VERSION}/src/semver"
SEMVER_INSTALL_PATH="/usr/local/bin/semver"

hash_file() {
  local file="$1"

  if command -v sha256sum &>/dev/null; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum &>/dev/null; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    echo "Missing sha256sum or shasum for checksum verification" >&2
    exit 1
  fi
}

run_with_sudo() {
  if [[ -n "${SUDO_CMD:-}" ]]; then
    "${SUDO_CMD}" "$@"
  else
    "$@"
  fi
}

ensure_writable_install_path() {
  local install_dir
  install_dir="$(dirname "$SEMVER_INSTALL_PATH")"

  if [[ ! -w "$install_dir" ]]; then
    if command -v sudo &>/dev/null; then
      SUDO_CMD="sudo"
    else
      echo "Write access to ${install_dir} is required. Re-run with sudo or adjust SEMVER_INSTALL_PATH." >&2
      exit 1
    fi
  fi
}

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
  TMP_SEMVER="$(mktemp)"

  curl -fsSL "$SEMVER_URL" -o "$TMP_SEMVER"
  ACTUAL_SHA256="$(hash_file "$TMP_SEMVER")"

  if [[ "$ACTUAL_SHA256" != "$SEMVER_SHA256" ]]; then
    echo "Checksum verification failed for semver ${SEMVER_VERSION}" >&2
    exit 1
  fi

  ensure_writable_install_path

  if command -v install &>/dev/null; then
    run_with_sudo install -m 0755 "$TMP_SEMVER" "$SEMVER_INSTALL_PATH"
  else
    run_with_sudo cp "$TMP_SEMVER" "$SEMVER_INSTALL_PATH"
    run_with_sudo chmod 0755 "$SEMVER_INSTALL_PATH"
  fi

  rm -f "$TMP_SEMVER"
fi
