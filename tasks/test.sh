#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

LCT_BIN=target/build/lct SHUNIT_COLOR=auto tests/smoke_test.sh >/dev/null

echo "Smoke tests passed."
