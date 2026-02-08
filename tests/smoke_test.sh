#!/usr/bin/env bash

LCT_BIN="${LCT_BIN:-target/build/lct}"

oneTimeSetUp() {
  if [ ! -x "$LCT_BIN" ]; then
    echo "lct binary missing at $LCT_BIN"
    exit 1
  fi
}

test_help_exits_zero() {
  "$LCT_BIN" --help >/dev/null 2>&1
  assertEquals "lct --help should exit 0" 0 $?
}

test_dotfiles_commands() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  local env_vars=(
    HOME="$tmpdir"
    CONFIG_DIR="$tmpdir/.config"
    SHARE_DIR="$tmpdir/.local/share"
    STATE_DIR="$tmpdir/.local/state"
    CACHE_DIR="$tmpdir/.cache"
  )

  mkdir -p "$tmpdir/.config" "$tmpdir/.local/share" "$tmpdir/.local/state" "$tmpdir/.cache"

  "${env_vars[@]}" "$LCT_BIN" dotfiles add "$tmpdir/.zshrc"

  local output
  output=$("${env_vars[@]}" "$LCT_BIN" dotfiles list)
  assertEquals "dotfiles list should include the added entry" ".zshrc" "$output"

  "${env_vars[@]}" "$LCT_BIN" dotfiles remove "$tmpdir/.zshrc"
  output=$("${env_vars[@]}" "$LCT_BIN" dotfiles list)
  assertEquals "dotfiles list should be empty after removal" "No dotfiles configured." "$output"
}

test_configs_commands() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  local env_vars=(
    HOME="$tmpdir"
    CONFIG_DIR="$tmpdir/.config"
    SHARE_DIR="$tmpdir/.local/share"
    STATE_DIR="$tmpdir/.local/state"
    CACHE_DIR="$tmpdir/.cache"
  )

  mkdir -p "$tmpdir/.config/alacritty" "$tmpdir/.local/share" "$tmpdir/.local/state" "$tmpdir/.cache"

  "${env_vars[@]}" "$LCT_BIN" configs add "$tmpdir/.config/alacritty"

  local output
  output=$("${env_vars[@]}" "$LCT_BIN" configs list)
  assertEquals "configs list should include the added entry" "alacritty" "$output"

  "${env_vars[@]}" "$LCT_BIN" configs remove "$tmpdir/.config/alacritty"
  output=$("${env_vars[@]}" "$LCT_BIN" configs list)
  assertEquals "configs list should be empty after removal" "No configs configured." "$output"
}

test_prune_cache_dry_run_lists_cache_dirs() {
  local tmpdir
  tmpdir="$(mktemp -d)"
  local env_vars=(
    HOME="$tmpdir"
    CONFIG_DIR="$tmpdir/.config"
    SHARE_DIR="$tmpdir/.local/share"
    STATE_DIR="$tmpdir/.local/state"
    CACHE_DIR="$tmpdir/.cache"
  )

  mkdir -p "$tmpdir/.config" "$tmpdir/.local/share" "$tmpdir/.local/state"
  mkdir -p "$tmpdir/.cache/lct/plugins/acme/tool"

  local output
  output=$("${env_vars[@]}" "$LCT_BIN" prune --cache --dry)
  assertContains "prune --cache should list cached plugin dirs" "$output" "$tmpdir/.cache/lct/plugins/acme/tool"
}

. "$(command -v shunit2)"
