#!/usr/bin/env bash

LCT_BIN="${LCT_BIN:-target/build/lct}"
tmpdir=""

oneTimeSetUp() {
  if [ ! -x "$LCT_BIN" ]; then
    echo "lct binary missing at $LCT_BIN"
    exit 1
  fi

  tmpdir="$(mktemp -d)"
  mkdir -p "$tmpdir/.config" "$tmpdir/.local/share" "$tmpdir/.local/state" "$tmpdir/.cache"
  export HOME="$tmpdir"
  export CONFIG_DIR="$tmpdir/.config"
  export SHARE_DIR="$tmpdir/.local/share"
  export STATE_DIR="$tmpdir/.local/state"
  export CACHE_DIR="$tmpdir/.cache"
}

oneTimeTearDown() {
  rm -rf "$tmpdir"
}

test_help_exits_zero() {
  "$LCT_BIN" --help >/dev/null 2>&1
  assertEquals "lct --help should exit 0" 0 $?
}

test_dotfiles_commands() {
  "$LCT_BIN" dotfiles add "$tmpdir/.zshrc"

  local output
  output=$("$LCT_BIN" dotfiles list)
  assertEquals "dotfiles list should include the added entry" ".zshrc" "$output"

  "$LCT_BIN" dotfiles remove "$tmpdir/.zshrc"
  output=$("$LCT_BIN" dotfiles list)
  assertEquals "dotfiles list should be empty after removal" "No dotfiles configured." "$output"
}

test_configs_commands() {
  "$LCT_BIN" configs add "$tmpdir/.config/alacritty"

  local output
  output=$("$LCT_BIN" configs list)
  assertEquals "configs list should include the added entry" "alacritty" "$output"

  "$LCT_BIN" configs remove "$tmpdir/.config/alacritty"
  output=$("$LCT_BIN" configs list)
  assertEquals "configs list should be empty after removal" "No configs configured." "$output"
}

. "$(command -v shunit2)"
