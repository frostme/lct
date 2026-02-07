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

. "$(command -v shunit2)"
