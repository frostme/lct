#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

LCT_BIN="${repo_root}/target/build/lct" FORCE_COLOR=true bash_unit tests/*_test.sh

echo "Smoke tests passed."
