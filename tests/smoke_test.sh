#!/usr/bin/env bash

LCT_BIN="${LCT_BIN:-target/build/lct}"
tmpdir=""

setup_suite() {
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

teardown_suite() {
  rm -rf "$tmpdir"
}

test_help_exits_zero() {
  "$LCT_BIN" --help
  "$LCT_BIN" --help >/dev/null 2>&1
  command_exit_code=$?
  assert_equals 0 $command_exit_code "lct --help should exit 0"
}

test_dotfiles_commands() {
  "$LCT_BIN" dotfiles add "$tmpdir/.zshrc"

  local output
  output=$("$LCT_BIN" dotfiles list)
  assert_equals ".zshrc" "$output" "dotfiles list should include the added entry"

  "$LCT_BIN" dotfiles remove "$tmpdir/.zshrc"
  output=$("$LCT_BIN" dotfiles list)
  assert_equals "No dotfiles configured." "$output" "dotfiles list should be empty after removal"
}

test_configs_commands() {
  "$LCT_BIN" configs add "$tmpdir/.config/alacritty"

  local output
  output=$("$LCT_BIN" configs list)
  assert_equals "alacritty" "$output" "configs list should include the added entry"

  "$LCT_BIN" configs remove "$tmpdir/.config/alacritty"
  output=$("$LCT_BIN" configs list)
  assert_equals "No configs configured." "$output" "configs list should be empty after removal"
}

test_prune_cache_dry_run_lists_cache_dirs() {
  mkdir -p "$tmpdir/.cache/lct/plugins/acme/tool"

  local output
  output=$("$LCT_BIN" prune --cache --dry)
  assert_matches "$tmpdir/.cache/lct/plugins/acme/tool" "$output" "prune --cache should list cached plugin dirs"
}
