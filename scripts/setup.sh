#!/usr/bin/env bash
set -Eeuo pipefail

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'error: required command not found: %s\n' "$1" >&2
    exit 1
  fi
}

install_mise() {
  if command -v mise >/dev/null 2>&1; then
    log "mise is already installed"
    return
  fi

  log "Installing mise"

  if command -v curl >/dev/null 2>&1; then
    curl https://mise.run | sh
    export PATH="$HOME/.local/bin:$PATH"
  elif command -v cargo >/dev/null 2>&1; then
    cargo install cargo-binstall
    cargo binstall --no-confirm mise
  else
    cat >&2 <<'EOF'
error: mise is not installed and this script could not install it automatically.
Install mise first, then rerun ./scripts/setup.sh.

Supported automatic installers:
- curl https://mise.run | sh
- cargo install cargo-binstall && cargo binstall mise
EOF
    exit 1
  fi
}

run_mise() {
  if command -v mise >/dev/null 2>&1; then
    mise "$@"
    return
  fi

  if [ -x "$HOME/.local/bin/mise" ]; then
    "$HOME/.local/bin/mise" "$@"
    return
  fi

  printf 'error: mise was installed but is not available on PATH\n' >&2
  exit 1
}

main() {
  cd "$(dirname "${BASH_SOURCE[0]}")/.."

  require_command git
  install_mise

  log "Trusting mise configuration"
  run_mise trust --yes .mise/config.toml 2>/dev/null || run_mise trust .mise/config.toml

  log "Installing pinned tools"
  run_mise install

  log "Validating Bashly configuration"
  run_mise run validate

  log "Building CLI"
  run_mise run build

  if [ "${LCT_SETUP_SKIP_TESTS:-0}" = "1" ]; then
    warn "Skipping tests because LCT_SETUP_SKIP_TESTS=1"
  else
    log "Running tests"
    run_mise run test
  fi

  log "Setup complete"
}

main "$@"
