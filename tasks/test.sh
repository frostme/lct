#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v bashly >/dev/null 2>&1; then
  echo "bashly is required to run tests. Run ./setup.sh to install it." >&2
  exit 1
fi

if ! command -v shunit2 >/dev/null 2>&1; then
  echo "shunit2 is required to run tests. Run ./setup.sh to install it." >&2
  exit 1
fi

cd "$repo_root"

mkdir -p target/build
bashly validate
bashly generate --upgrade

if [ ! -x target/build/lct ]; then
  echo "Generated CLI missing at target/build/lct" >&2
  exit 1
fi

LCT_BIN=target/build/lct SHUNIT_COLOR=none tests/smoke_test.sh >/dev/null

echo "Smoke tests passed."
